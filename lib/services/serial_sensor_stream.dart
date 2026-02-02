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
        print(dataStr);
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
        final Map<String, dynamic> json = jsonDecode(frame);

        // Extract data with proper type conversion
        final sensorData = SensorData(
          // Axles - your JSON has "Axle1", "Axle5", "Axle6" (capital A)
          axle1: _parseDouble(json['Axle1']),
          axle5: _parseDouble(json['Axle5']),
          axle6: _parseDouble(json['Axle6']),

          // Errors - your JSON has "A5_Err", "A6_Err"
          a5Error: _parseDouble(json['A5_Err']),
          a6Error: _parseDouble(json['A6_Err']),

          // Currents - your JSON has "A5_C", "A6_C"
          a5Amp: _parseDouble(json['A5_C']),
          a6Amp: _parseDouble(json['A6_C']),

          // Solenoids - your JSON has "SOL1", "SOL2", etc. with "ON"/"OFF"
          a5lk1: json['SOL1'] == 'ON',
          a5lk2: json['SOL2'] == 'ON',
          a6lk1: json['SOL3'] == 'ON',
          a6lk2: json['SOL4'] == 'ON',
          ls: json['SOL5'] == 'ON',

          // System message
          systemMessage: json['system_message']?.toString() ?? 'NO MESSAGE',

          time: DateTime.now(),
        );

        // Debug print
        print(
          '📦 Received: ${sensorData.axle1}, ${sensorData.axle5}, ${sensorData.axle6}',
        );

        _controller.add(sensorData);
      } catch (e) {
        print('❌ Error parsing JSON: $e');
        print('   Raw frame: $frame');
      }
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  void dispose() {
    _socket?.close();
    _controller.close();
  }
}
