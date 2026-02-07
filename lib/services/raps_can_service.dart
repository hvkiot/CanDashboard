import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:steering/models/sensor_data.dart';
import 'socketcan_interop.dart';

/// Commands sent from Main Isolate to Background Isolate
class _CanCommand {
  final String type;
  final int? id;
  final List<int>? payload;
  _CanCommand(this.type, {this.id, this.payload});
}

class RapsCanService {
  Isolate? _isolate;
  SendPort? _sendPort;
  final _controller = StreamController<SensorData>.broadcast();

  Stream<SensorData> get stream => _controller.stream;

  void initialize() async {
    final receivePort = ReceivePort();

    // Spawn the background isolate
    _isolate = await Isolate.spawn(_backgroundWorker, receivePort.sendPort);

    receivePort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
      } else if (message is SensorData) {
        _controller.add(message);
      } else if (message is String) {
        print("CAN Isolate Log: $message");
      }
    });
  }

  void calibrateAxle5() {
    _sendPort?.send(
      _CanCommand(
        'write',
        id: 0x1BDA08F1,
        payload: [0x04, 0x2E, 0x22, 0x11, 0x00, 0x00, 0x00, 0x00],
      ),
    );
  }

  void requestVoltage() {
    _sendPort?.send(
      _CanCommand(
        'write',
        id: 0x1BDA08F1,
        payload: [0x03, 0x22, 0x22, 0x0F, 0x00, 0x00, 0x00, 0x00],
      ),
    );
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _controller.close();
  }

  /// THE BACKGROUND WORKER (Runs in its own Isolate)
  static void _backgroundWorker(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    int socketFd = -1;
    bool running = false;

    // Cached values for emitting SensorData
    double a1 = 0, a5 = 0, a6 = 0, voltage = 0;

    void emitData() {
      mainSendPort.send(
        SensorData(
          axle1: a1,
          axle5: a5,
          axle6: a6,
          systemMessage: voltage.toString(),
          a5Amp: 0,
          a6Amp: 0,
          a5Error: 0,
          a6Error: 0,
          a5lk1: false,
          a5lk2: false,
          a6lk1: false,
          a6lk2: false,
          ls: false,
          time: DateTime.now(),
        ),
      );
    }

    // 1. Setup Socket
    try {
      socketFd = socket(pfCan, sockRaw, canRaw);
      if (socketFd < 0) throw Exception("Failed to open socket");

      final ifr = calloc<IfReq>();
      final ifName = "can0".codeUnits;
      for (int i = 0; i < ifName.length; i++) ifr.ref.ifrName[i] = ifName[i];

      if (ioctl(socketFd, siocGifIndex, ifr) < 0)
        throw Exception("can0 not found");
      final ifIndex = ifr.ref.ifrIfIndex;
      calloc.free(ifr);

      final addr = calloc<SockAddrCan>();
      addr.ref.canFamily = pfCan;
      addr.ref.canIfIndex = ifIndex;

      if (bind(socketFd, addr, sizeOf<SockAddrCan>()) < 0)
        throw Exception("Bind failed");
      calloc.free(addr);

      mainSendPort.send(
        "✅ RAPS CAN Service connected to can0 (Background Isolate)",
      );
      running = true;
    } catch (e) {
      mainSendPort.send("❌ CAN Init Error: $e");
      return;
    }

    // 2. Listen for outgoing commands (Write)
    receivePort.listen((message) {
      if (message is _CanCommand && message.type == 'write') {
        final frame = calloc<CanFrame>();
        frame.ref.canId = (message.id ?? 0) | 0x80000000;
        frame.ref.canDlc = 8;
        for (int i = 0; i < 8; i++) {
          frame.ref.data[i] = message.payload?[i] ?? 0;
        }
        write(socketFd, frame, sizeOf<CanFrame>());
        calloc.free(frame);
      }
    });

    // 3. The Read Loop (Blocking)
    final framePtr = calloc<CanFrame>();
    while (running) {
      // This call blocks the ISOLATE, but NOT the main Flutter thread
      if (read(socketFd, framePtr, sizeOf<CanFrame>()) > 0) {
        final id = framePtr.ref.canId & 0x1FFFFFFF;
        final data = framePtr.ref.data;

        if (id == 0x18FF0108) {
          double calc(int lo, int hi) => ((hi << 8) | lo) / 256.0 - 125.0;
          a1 = calc(data[0], data[1]);
          a5 = calc(data[2], data[3]);
          a6 = calc(data[4], data[5]);
          emitData();
        } else if (id == 0x18FF0308) {
          if ((data[0] & 0x03) == 2)
            mainSendPort.send("⚠️ Load Solenoid Error!");
        } else if (id == 0x1BDAF108) {
          // UDS Response
          if (data[3] == 0x62 && data[4] == 0x22 && data[5] == 0x0F) {
            voltage = ((data[6] << 8) | data[7]) / 10.0;
            emitData();
          }
        }
      }
    }
  }
}
