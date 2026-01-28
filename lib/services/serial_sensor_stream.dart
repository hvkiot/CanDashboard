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
        Datagram? dg = _socket!.receive();
        if (dg == null) return;

        // Convert bytes to string for parsing
        final dataStr = utf8.decode(dg.data, allowMalformed: true);
        _buffer += dataStr;

        _processBuffer();
      }
    });
  }

  void _processBuffer() {
    while (true) {
      final start = _buffer.indexOf('<');
      if (start == -1) {
        if (_buffer.length > 2048) _buffer = '';
        return;
      }

      final end = _buffer.indexOf('>', start);
      if (end == -1) return;

      final frame = _buffer.substring(start + 1, end).trim();
      _buffer = _buffer.substring(end + 1);

      // Ignore invalid frames
      if (!frame.contains(',')) continue;

      final parts = frame.split(',').map((e) => e.trim()).toList();

      try {
        // Adjust this depending on how many fields you actually have
        if (parts.length < 6) continue;

        _controller.add(
          SensorData(
            axle1: double.parse(parts[0]),
            axle5: double.parse(parts[1]),
            axle6: double.parse(parts[2]),
            pressure: double.parse(parts[3]),
            temp: double.parse(parts[4]),
            systemMessage: parts[5],
            // Optional: map the rest if present
            a5Error: parts.length > 6 ? double.parse(parts[6]) : 0,
            a6Error: parts.length > 7 ? double.parse(parts[7]) : 0,
            a5Amp: parts.length > 8 ? double.parse(parts[8]) : 0,
            a6Amp: parts.length > 9 ? double.parse(parts[9]) : 0,
            a5lk1: parts.length > 10
                ? parts[10].toLowerCase() == 'true'
                : false,
            a5lk2: parts.length > 11
                ? parts[11].toLowerCase() == 'true'
                : false,
            a6lk1: parts.length > 12
                ? parts[12].toLowerCase() == 'true'
                : false,
            a6lk2: parts.length > 13
                ? parts[13].toLowerCase() == 'true'
                : false,
            ls: parts.length > 14 ? parts[14].toLowerCase() == 'true' : false,
            time: DateTime.now(),
          ),
        );
      } catch (_) {
        // ignore malformed frames
      }
    }
  }

  void dispose() {
    _socket?.close();
    _controller.close();
  }
}
