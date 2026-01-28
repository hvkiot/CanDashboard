import 'dart:io';
import 'package:steering/models/sensor_data.dart';
import 'package:steering/screens/graph_screen.dart';
import 'package:steering/services/mock_sensor_stream.dart';
import 'package:steering/services/serial_sensor_stream.dart';
import 'package:flutter/material.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});
  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  late final UdpSensorStream serial;
  late final Stream<SensorData> stream;
  dynamic _source;

  @override
  void initState() {
    super.initState();

    if (Platform.isLinux) {
      serial = UdpSensorStream(ip: '192.168.0.107', port: 5005);
      _source = serial;
      stream = serial.stream;
    } else {
      _source = MockSensorStream();
      stream = _source.stream;
    }
  }

  @override
  void dispose() {
    // serial.dispose(); // close serial properly
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: GraphScreen(stream: stream));
  }
}
