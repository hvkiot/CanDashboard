import 'package:steering/models/sensor_data.dart';
import 'package:steering/screens/graph_screen.dart';
import 'package:steering/services/raps_can_service.dart';
import 'package:flutter/material.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});
  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  RapsCanService? canService;
  Stream<SensorData>? stream;

  @override
  void initState() {
    super.initState();

    canService = RapsCanService();
    canService!.initialize();

    // The stream is available immediately as it's a broadcast controller
    stream = canService!.stream;

    // Small delay before requesting the first voltage readout
    Future.delayed(Duration(seconds: 1), () {
      canService?.requestVoltage();
    });
  }

  @override
  void dispose() {
    canService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (stream == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(body: GraphScreen(stream: stream!));
  }
}
