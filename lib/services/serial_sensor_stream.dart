import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:steering/models/sensor_data.dart';

class UdpSensorStream {
  final _controller = StreamController<SensorData>.broadcast();
  Stream<SensorData> get stream => _controller.stream;

  final String _ip;
  final int _port;

  String _buffer = '';
  RawDatagramSocket? _socket;

  UdpSensorStream({required String ip, required int port})
    : _ip = ip,
      _port = port {
    _init();
  }

  void _init() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
    print('Listening for UDP on $_ip:$_port');

    _socket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final dg = _socket!.receive();
        if (dg == null) return;

        final dataStr = utf8.decode(dg.data, allowMalformed: true);
        _buffer += dataStr;
        // print('UDP Data Received: $dataStr');
        _processBuffer();
      }
    });
  }

  void _processBuffer() {
    while (true) {
      final start = _buffer.indexOf('<');
      if (start == -1) {
        if (_buffer.length > 4096) _buffer = '';
        return;
      }

      final end = _buffer.indexOf('>', start);
      if (end == -1) return;

      final frame = _buffer.substring(start + 1, end);
      _buffer = _buffer.substring(end + 1);

      try {
        final Map<String, dynamic> json =
            jsonDecode(frame) as Map<String, dynamic>;

        _controller.add(
          SensorData(
            axle1: double.parse((json['Axle1'] ?? 0).toStringAsFixed(1)),
            axle5: double.parse((json['Axle5'] ?? 0).toStringAsFixed(1)),
            axle6: double.parse((json['Axle6'] ?? 0).toStringAsFixed(1)),

            a5Error: double.parse((json['A5_Err'] ?? 0).toStringAsFixed(1)),
            a6Error: double.parse((json['A6_Err'] ?? 0).toStringAsFixed(1)),
            a5Amp: double.parse((json['A5_C'] ?? 0).toStringAsFixed(1)),
            a6Amp: double.parse((json['A6_C'] ?? 0).toStringAsFixed(1)),

            // Solenoids (0 / 1 / 2)
            a5lk1: json['SOL1'] == 'ON' ? false : true,
            a5lk2: json['SOL2'] == 'ON' ? false : true,
            a6lk1: json['SOL3'] == 'ON' ? false : true,
            a6lk2: json['SOL4'] == 'ON' ? false : true,
            ls: json['SOL5'] == 'ON' ? false : true,
            systemMessage: json['system_message'] ?? 'NO MESSAGE',

            time: DateTime.now(),
          ),
        );
      } catch (e) {
        // Ignore malformed or partial frames
        print('Error parsing UDP frame: $e');
      }
    }
  }

  void dispose() {
    _socket?.close();
    _controller.close();
  }
}
