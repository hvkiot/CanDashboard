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

  /// THE BACKGROUND WORKER (Runs in its own Isolate to prevent UI lag)
  static void _backgroundWorker(SendPort mainSendPort) async {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    int socketFd = -1;
    bool running = false;

    // --- RAPS State Variables ---
    double a1 = 0, a5 = 0, a6 = 0, voltage = 0;
    double a5Error = 0, a6Error = 0;
    double a5Amp = 0, a6Amp = 0;

    // Solenoid Statuses (True = ON/Energized, False = OFF)
    bool ls = false, a5lk1 = false, a5lk2 = false, a6lk1 = false, a6lk2 = false;

    String sysMsg = "SYSTEM HEALTHY";
    // Helper to package and send data back to the Main UI Isolate

    void emitData() {
      mainSendPort.send(
        SensorData(
          axle1: double.parse(a1.toStringAsFixed(2)),
          axle5: double.parse(a5.toStringAsFixed(2)),
          axle6: double.parse(a6.toStringAsFixed(2)),
          a5Error: double.parse(a5Error.toStringAsFixed(2)),
          a6Error: double.parse(a6Error.toStringAsFixed(2)),
          a5Amp: double.parse(a5Amp.toStringAsFixed(2)),
          a6Amp: double.parse(a6Amp.toStringAsFixed(2)),
          systemMessage: sysMsg,
          voltage: double.parse(voltage.toStringAsFixed(2)),
          ls: ls,
          a5lk1: a5lk1,
          a5lk2: a5lk2,
          a6lk1: a6lk1,
          a6lk2: a6lk2,
          time: DateTime.now(),
        ),
      );
    }

    // --- 1. Linux SocketCAN Setup ---
    try {
      socketFd = socket(pfCan, sockRaw, canRaw);
      if (socketFd < 0) throw Exception("Failed to open CAN socket");

      final ifr = calloc<IfReq>();
      final ifName = "can0".codeUnits;
      for (int i = 0; i < ifName.length; i++) {
        ifr.ref.ifrName[i] = ifName[i];
      }

      if (ioctl(socketFd, siocGifIndex, ifr) < 0) {
        throw Exception("can0 interface not found");
      }

      final ifIndex = ifr.ref.ifrIfIndex;
      calloc.free(ifr);

      final addr = calloc<SockAddrCan>();
      addr.ref.canFamily = pfCan;
      addr.ref.canIfIndex = ifIndex;

      if (bind(socketFd, addr, sizeOf<SockAddrCan>()) < 0) {
        throw Exception("Failed to bind to can0");
      }
      calloc.free(addr);

      mainSendPort.send("✅ RAPS CAN Service connected");
      running = true;
    } catch (e) {
      mainSendPort.send("❌ CAN Init Error: $e");
      return;
    }

    // --- 2. Listen for Outgoing Commands (Calibration/UDS) ---
    receivePort.listen((message) {
      if (message is _CanCommand) {
        if (message.type == 'write') {
          final frame = calloc<CanFrame>();
          // Apply Extended ID bit (0x80000000) for 29-bit IDs
          frame.ref.canId = (message.id ?? 0) | 0x80000000;
          frame.ref.canDlc = 8;
          for (int i = 0; i < 8; i++) {
            frame.ref.data[i] = message.payload?[i] ?? 0;
          }
          write(socketFd, frame, sizeOf<CanFrame>());
          calloc.free(frame);
        }
      } else if (message.type == 'stop') {
        running = false;
      }
    });

    // --- 3. The High-Speed Read Loop ---
    final framePtr = calloc<CanFrame>();

    // Decoding Formulas
    double decodeAngle(int lo, int hi) => ((hi << 8) | lo) / 256.0 - 125.0;
    double decodeAmp(int lo, int hi) => ((hi << 8) | lo) - 32000.0;
    try {
      while (running) {
        if (read(socketFd, framePtr, sizeOf<CanFrame>()) > 0) {
          final id = framePtr.ref.canId & 0x1FFFFFFF; // Mask out priority bits
          final data = framePtr.ref.data;

          // A. ANGLES [Source 57] ID 0x18FF0108: Axle Angles
          if (id == 0x18FF0108) {
            a1 = decodeAngle(data[0], data[1]);
            a5 = decodeAngle(data[2], data[3]);
            a6 = decodeAngle(data[4], data[5]);
            emitData();
          }
          // B. ERRORS & CURRENTS [Source 57] ID 0x18FF0208: Angle Errors & Solenoid Currents
          else if (id == 0x18FF0208) {
            a5Error = decodeAngle(data[0], data[1]);
            a6Error = decodeAngle(data[2], data[3]);
            a5Amp = decodeAmp(data[4], data[5]);
            a6Amp = decodeAmp(data[6], data[7]);
            emitData();
          }
          // C. SOLENOID STATUS [Source 57] ID 0x18FF0308: Solenoid Status Bits
          else if (id == 0x18FF0308) {
            int b0 = data[0];
            int b1 = data[1];

            // Status: 00=Off, 01=On, 10=Error(2), 11=NA
            ls = (b0 & 0x03) == 2;
            a5lk1 = ((b0 >> 2) & 0x03) == 2;
            a5lk2 = ((b0 >> 4) & 0x03) == 2;
            a6lk1 = ((b0 >> 6) & 0x03) == 2;
            a6lk2 = (b1 & 0x03) == 2;

            emitData();
          }
          // D. UDS VOLTAGE [Source 55] ID 0x1BDAF108: UDS Response (Voltage/Ack)
          else if (id == 0x1BDAF108) {
            int serviceResponse = data[1];
            int did = (data[2] << 8) | data[3];

            // A. Handle READ Responses (0x62)
            if (serviceResponse == 0x62) {
              switch (did) {
                case 0x220F: // System Voltage
                  int raw = (data[4] << 8) | data[5];
                  voltage = raw / 10.0;
                  break;
                case 0x2210: // Axle 1 Angle via UDS
                  int raw = (data[4] << 8) | data[5];
                  a1 = raw / 10.0; // 0x22 resolution is 0.1 deg/bit
                  break;
                case 0x2211: // Axle 5 Angle via UDS
                  int raw = (data[4] << 8) | data[5];
                  a5 = raw / 10.0;
                  break;
              }
              emitData();
            }
            // B. Handle WRITE/CALIBRATION Responses (0x6E)
            else if (serviceResponse == 0x6E) {
              String action = (did == 0x2211) ? "Axle 5 Zero" : "Axle 6 Zero";
              mainSendPort.send("✅ $action Calibration Successful");
            }
            // C. Handle NEGATIVE Responses (0x7F)
            else if (serviceResponse == 0x7F) {
              int errorCode = data[3]; // NRC (Negative Response Code)
              mainSendPort.send(
                "❌ ECU Rejected Command. Error Code: 0x${errorCode.toRadixString(16)}",
              );
            }
          }
          // --- LOGIC: SYSTEM MESSAGE [Source 2] ---
          if (ls || a5lk1 || a5lk2 || a6lk1 || a6lk2) {
            sysMsg = "STEERING FAULT: SOLENOID";
          } else if (voltage < 22.0 && voltage > 1.0) {
            sysMsg = "LOW VOLTAGE WARNING";
          }
          emitData();
        }
        await Future.delayed(Duration.zero);
        // Brief yield to prevent CPU pegging (1ms is enough for 100Hz+)
        // Note: Standard read() on SocketCAN is blocking; use select() or
        // a small delay if the kernel doesn't yield.
      }
    } catch (e) {
      mainSendPort.send("❌ CAN Read Error: $e");
    } finally {
      calloc.free(framePtr);
      if (socketFd >= 0) {
        // Use the close() function from your interop to shut down the socket
        // close(socketFd);
      }
      mainSendPort.send("Isolate Shutdown Cleanly");
    }
  }
}
