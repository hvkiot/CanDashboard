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

    // --- State Variables ---
    double a1 = 0, a5 = 0, a6 = 0, voltage = 0;
    double a5Error = 0, a6Error = 0;
    double a5Amp = 0, a6Amp = 0;

    // Solenoid Statuses
    bool ls = false, a5lk1 = false, a5lk2 = false, a6lk1 = false, a6lk2 = false;

    void emitData() {
      mainSendPort.send(
        SensorData(
          axle1: a1,
          axle5: a5,
          axle6: a6,
          systemMessage: voltage.toStringAsFixed(1),
          a5Amp: a5Amp,
          a6Amp: a6Amp,
          a5Error: a5Error,
          a6Error: a6Error,
          ls: ls,
          a5lk1: a5lk1,
          a5lk2: a5lk2,
          a6lk1: a6lk1,
          a6lk2: a6lk2,
          time: DateTime.now(),
        ),
      );
    }

    // --- 1. Setup Socket ---
    try {
      socketFd = socket(pfCan, sockRaw, canRaw);
      if (socketFd < 0) throw Exception("Failed to open socket");

      final ifr = calloc<IfReq>();
      final ifName = "can0".codeUnits;
      for (int i = 0; i < ifName.length; i++) {
        ifr.ref.ifrName[i] = ifName[i];
      }

      if (ioctl(socketFd, siocGifIndex, ifr) < 0) {
        throw Exception("can0 not found");
      }

      final ifIndex = ifr.ref.ifrIfIndex;
      calloc.free(ifr);

      final addr = calloc<SockAddrCan>();
      addr.ref.canFamily = pfCan;
      addr.ref.canIfIndex = ifIndex;

      if (bind(socketFd, addr, sizeOf<SockAddrCan>()) < 0) {
        throw Exception("Bind failed");
      }
      calloc.free(addr);

      mainSendPort.send("✅ RAPS CAN Service connected");
      running = true;
    } catch (e) {
      mainSendPort.send("❌ CAN Init Error: $e");
      return;
    }

    // --- 2. Listen for Write Commands ---
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

    // --- 3. The Read Loop ---
    final framePtr = calloc<CanFrame>();

    while (running) {
      // Read 1 frame
      if (read(socketFd, framePtr, sizeOf<CanFrame>()) > 0) {
        final id = framePtr.ref.canId & 0x1FFFFFFF;
        final data = framePtr.ref.data; // 'data' is the Array container

        // --- DECODER 1: AXLE ANGLES (ID 0x18FF0108) ---
        // Source [1]: A1(Byte0-1), A5(Byte2-3), A6(Byte4-5)
        if (id == 0x18FF0108) {
          double calc(int lo, int hi) => ((hi << 8) | lo) / 256.0 - 125.0;

          // ✅ FIX APPLIED: accessing indices ...[3]
          a1 = calc(data[0], data[1]);
          a5 = calc(data[2], data[3]);
          a6 = calc(data[4], data[5]);

          emitData();
        }
        // --- DECODER 2: ERRORS & CURRENTS (ID 0x18FF0208) ---
        // Source [1]: A5Err(0-1), A6Err(2-3), A5Cur(4-5), A6Cur(6-7)
        else if (id == 0x18FF0208) {
          double calcAngle(int lo, int hi) => ((hi << 8) | lo) / 256.0 - 125.0;
          double calcAmp(int lo, int hi) => (((hi << 8) | lo) - 32000.0);

          // ✅ FIX APPLIED: accessing indices ...[7]
          a5Error = calcAngle(data[0], data[1]);
          a6Error = calcAngle(data[2], data[3]);
          a5Amp = calcAmp(data[4], data[5]);
          a6Amp = calcAmp(data[6], data[7]);

          emitData();
        }
        // --- DECODER 3: SOLENOID STATUS (ID 0x18FF0308) ---
        // Source [1]: Page 52 Layout
        else if (id == 0x18FF0308) {
          // ✅ FIX APPLIED: Grab specific bytes first using []
          int byte0 = data[0]; // Byte 0 (Bits 0-7)
          int byte1 = data[1]; // Byte 1 (Bits 8-15)

          // Decode using your corrected logic
          int loadSol = byte0 & 0x03; // Bits 0-1
          int a5Lock1 = (byte0 >> 2) & 0x03; // Bits 2-3
          int a5Lock2 = (byte0 >> 4) & 0x03; // Bits 4-5
          int a6Lock1 = (byte0 >> 6) & 0x03; // Bits 6-7
          int a6Lock2 = byte1 & 0x03; // Byte 1 Bits 0-1 (Start Bit 8)

          // 2 = Error (Binary 10)
          ls = (loadSol == 2);
          a5lk1 = (a5Lock1 == 2);
          a5lk2 = (a5Lock2 == 2);
          a6lk1 = (a6Lock1 == 2);
          a6lk2 = (a6Lock2 == 2);

          if (ls || a5lk1 || a5lk2 || a6lk1 || a6lk2) {
            mainSendPort.send("⚠️ Solenoid Error!");
          }
          emitData();
        }
        // --- DECODER 4: UDS RESPONSE (ID 0x1BDAF108) ---
        // Source [9]: UDS Server Details
        else if (id == 0x1BDAF108) {
          // ✅ FIX APPLIED: Check specific bytes for response signature
          // Byte 1=Service(0x62), Byte 2=DID_H(0x22), Byte 3=DID_L(0x0F)
          if (data[2] == 0x62 && data[4] == 0x22 && data[5] == 0x0F) {
            // Value is in Bytes 4 and 5
            int raw = (data[6] << 8) | data[3];
            voltage = raw / 10.0;
            emitData();
          }
        }
      }
    }
  }
}
