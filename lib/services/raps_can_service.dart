import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:steering/models/sensor_data.dart';
import 'socketcan_interop.dart';

class RapsCanService {
  late int _socketFd;
  bool _running = false;

  // 1. Define the StreamController (Private)
  final _controller = StreamController<SensorData>.broadcast();

  // 2. Define the Public Getter (THIS WAS MISSING)
  // This allows 'canService.stream' to be accessed in DashboardHome
  Stream<SensorData> get stream => _controller.stream;

  // Cached values
  double _a1 = 0, _a5 = 0, _a6 = 0;
  double _voltage = 0;

  void initialize() {
    try {
      _socketFd = socket(pfCan, sockRaw, canRaw);
      if (_socketFd < 0) throw Exception("Failed to open CAN socket");

      final ifr = calloc<IfReq>();
      final ifName = "can0".codeUnits;
      for (int i = 0; i < ifName.length; i++) {
        ifr.ref.ifrName[i] = ifName[i];
      }

      if (ioctl(_socketFd, siocGifIndex, ifr) < 0) {
        throw Exception("can0 interface not found. Is the HAT configured?");
      }

      final ifIndex = ifr.ref.ifrIfIndex;
      calloc.free(ifr);

      final addr = calloc<SockAddrCan>();
      addr.ref.canFamily = pfCan;
      addr.ref.canIfIndex = ifIndex;

      if (bind(_socketFd, addr, sizeOf<SockAddrCan>()) < 0) {
        throw Exception("Failed to bind to can0");
      }
      calloc.free(addr);

      print("✅ RAPS CAN Service connected to can0");
      _running = true;
      _startReadLoop();
    } catch (e) {
      print("❌ CAN Error: $e");
    }
  }

  void _startReadLoop() async {
    final framePtr = calloc<CanFrame>();

    while (_running) {
      // Reads 1 frame at a time from Linux Kernel
      if (read(_socketFd, framePtr, sizeOf<CanFrame>()) > 0) {
        final id = framePtr.ref.canId & 0x1FFFFFFF;
        final data = framePtr.ref.data;

        // IDs defined in Source [1] and [2]
        if (id == 0x18FF0108) {
          _decodeAngles(data);
        } else if (id == 0x18FF0308) {
          _decodeSolenoids(data);
        } else if (id == 0x1BDAF108) {
          _decodeUdsResponse(data);
        }
      }
      await Future.delayed(Duration(milliseconds: 1));
    }
    calloc.free(framePtr);
  }

  void _decodeAngles(Array<Uint8> data) {
    // Formula: ((HighByte << 8) | LowByte) / 256.0 - 125.0 [Source 84]
    double calc(int lo, int hi) => ((hi << 8) | lo) / 256.0 - 125.0;

    _a1 = calc(data[0], data[1]);
    _a5 = calc(data[2], data[3]);
    _a6 = calc(data[4], data[5]);

    _emitData();
  }

  void _decodeSolenoids(Array<Uint8> data) {
    // Bits 0-1 = Load Solenoid [Source 84]
    int loadSol = data[0] & 0x03;
    if (loadSol == 2) {
      // Binary 10 = Error
      print("⚠️ Load Solenoid Error!");
    }
  }

  void _decodeUdsResponse(Array<Uint8> data) {
    // UDS Voltage Response (DID 0x220F) [Source 82]
    if (data[3] == 0x62 && data[4] == 0x22 && data[5] == 0x0F) {
      int raw = (data[6] << 8) | data[7];
      _voltage = raw / 10.0;
      _emitData();
    }
  }

  void _emitData() {
    _controller.add(
      SensorData(
        axle1: _a1,
        axle5: _a5,
        axle6: _a6,
        systemMessage: _voltage.toString(),
        a5Amp: 0.0,
        a6Amp: 0.0,
        a5Error: 0.0,
        a6Error: 0.0,
        a5lk1: false,
        a5lk2: false,
        a6lk1: false,
        a6lk2: false,
        ls: false,
        time: DateTime.now(),
      ),
    );
  }

  // --- CONTROLLER ACTIONS ---

  void calibrateAxle5() {
    // Write 0 to DID 0x2211 [Source 83]
    _sendFrame(0x1BDA08F1, [0x04, 0x2E, 0x22, 0x11, 0x00, 0x00, 0x00, 0x00]);
  }

  void requestVoltage() {
    // Read DID 0x220F [Source 82]
    _sendFrame(0x1BDA08F1, [0x03, 0x22, 0x22, 0x0F, 0x00, 0x00, 0x00, 0x00]);
  }

  void _sendFrame(int id, List<int> payload) {
    final frame = calloc<CanFrame>();
    frame.ref.canId = id | 0x80000000;
    frame.ref.canDlc = 8;
    for (int i = 0; i < 8; i++) {
      frame.ref.data[i] = payload[i];
    }

    write(_socketFd, frame, sizeOf<CanFrame>());
    calloc.free(frame);
  }

  void dispose() {
    _running = false;
    _controller.close();
  }
}
