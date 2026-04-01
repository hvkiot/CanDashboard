import 'package:steering/models/sensor_data.dart';
import 'package:steering/screens/graph_screen.dart';
import 'package:steering/services/serial_sensor_stream.dart';
import 'package:flutter/material.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});
  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  late final CanSensorStream canStream;
  late final Stream<CombinedState> stream;

  @override
  void initState() {
    super.initState();
    canStream = CanSensorStream('can1'); // Standard SocketCAN interface
    stream = canStream.stream;
  }

  @override
  void dispose() {
    canStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: GraphScreen(stream: stream));
  }
}
