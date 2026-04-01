import 'dart:async';
import 'dart:ffi';
import 'package:steering/models/sensor_data.dart';
import 'package:steering/services/socketcan_interop.dart'; // Your FFI defines
import 'package:ffi/ffi.dart';

class CanSensorStream {
  final _controller = StreamController<CombinedState>.broadcast();
  Stream<CombinedState> get stream => _controller.stream;

  // Persistent state: This prevents the "Snap back to Zero"
  CombinedState _currentState = CombinedState.initial();

  late int _fd;
  bool _running = true;
  late Pointer<CanFrame> _frame; // Keep persistent for the loop

  CanSensorStream(String interface) {
    _init(interface);
  }

  void _init(String interface) {
    try {
      // 1. Open and Bind Socket (using your FFI methods)
      _fd = socket(pfCan, sockRaw, canRaw);
      // final ifr = calloc<IfReq>();
      // ... (Include your ioctl and bind logic here for 'interface')

      print('✅ SocketCAN listening on $interface');
      _startReadLoop();
    } catch (e) {
      _updateState(
        (current) => current.copyWith(
          uds: current.uds.copyWith(systemMessage: "ERROR: ${e.toString()}"),
        ),
      );
    }
  }

  void _startReadLoop() {
    _frame = calloc<CanFrame>();

    // We use a simplified loop. In a full app, move this to an Isolate.
    Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!_running) {
        timer.cancel();
        return;
      }

      final bytesRead = read(_fd, _frame, sizeOf<CanFrame>());
      if (bytesRead > 0) {
        print("CAN Frame: ${_frame.ref.canId}");
        _processCanFrame(_frame);
      }
    });
  }

  void _processCanFrame(Pointer<CanFrame> frame) {
    print("CAN Frame: ${_frame.ref.data}");
    final id = frame.ref.canId & canIdMask;

    // Update ONLY the fields present in this specific frame
    _updateState((current) {
      if (id == 0x18FF0108) {
        return current.copyWith(
          live: current.live.copyWith(
            axle1: _parseAxle(frame.ref.data[0], frame.ref.data[1]),
            axle5: _parseAxle(frame.ref.data[2], frame.ref.data[3]),
            axle6: _parseAxle(frame.ref.data[4], frame.ref.data[5]),
            time: DateTime.now(),
          ),
        );
      }

      if (id == 0x18FF0208) {
        return current.copyWith(
          live: current.live.copyWith(
            a5Amp: (frame.ref.data[0] << 8 | frame.ref.data[1]).toDouble(),
            a6Amp: (frame.ref.data[2] << 8 | frame.ref.data[3]).toDouble(),
          ),
        );
      }

      // Handle UDS Response for Polling
      if (id == 0x1BDAF108 && frame.ref.data[1] == 0x62) {
        final did = (frame.ref.data[2] << 8) | frame.ref.data[3];
        if (did == 0x2210) {
          // Axle 1 Poll DID
          return current.copyWith(
            live: current.live.copyWith(
              axle1: _parseAxle(frame.ref.data[4], frame.ref.data[5]),
            ),
          );
        }
      }

      return current; // Return unchanged if ID doesn't match
    });
  }

  // Common Parsing Logic
  double _parseAxle(int hi, int lo) {
    // Standard J1939-style parsing for angles
    return ((hi << 8) | lo) / 256.0 - 125.0;
  }

  // Helper to update state and notify UI
  void _updateState(CombinedState Function(CombinedState) updates) {
    _currentState = updates(_currentState);
    _controller.add(_currentState);
  }

  void dispose() {
    _running = false;
    close(_fd);
    _controller.close();
    calloc.free(_frame);
  }
}
