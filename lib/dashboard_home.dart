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
  late final RapsCanService canService;
  late final Stream<SensorData> stream;

  @override
  void initState() {
    super.initState();
    canService = RapsCanService();
    canService.initialize();

    // Try assigning it directly to see if the error moves
    final localStream = canService.stream;
    stream = localStream;

    Future.delayed(Duration(seconds: 1), () {
      canService.requestVoltage();
    });
  }

  @override
  void dispose() {
    canService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: GraphScreen(stream: stream));
  }
}
