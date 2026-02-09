import 'dart:async';
import 'package:flutter/material.dart';
import 'package:steering/models/sensor_data.dart';
import 'package:steering/services/raps_can_service.dart';
import 'package:steering/widgets/circular_gauge.dart';

class GraphScreen extends StatelessWidget {
  final Stream<SensorData> stream;
  final RapsCanService service;

  const GraphScreen({super.key, required this.stream, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Industrial Dark
      appBar: AppBar(
        title: const Text("RAPS SYSTEM DASHBOARD"),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: StreamBuilder<SensorData>(
        stream: stream,
        builder: (context, snapshot) {
          final data = snapshot.data ?? SensorData();

          return SingleChildScrollView(
            child: Column(
              children: [
                /// --- HEADER: Voltage & Message ---
                _buildHeader(data),

                const SizedBox(height: 20),

                /// --- MAIN GAUGE: Axle 1 (Top Center) ---
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 250,
                    child: FullCircularGauge(
                      label: "AXLE 1",
                      value: data.axle1,
                      min: -35,
                      max: 35,
                      unit: "°",
                      color: Colors.blueAccent,
                      size: 280,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                /// --- ROW: Axle 5 & 6 ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 180,
                      child: FullCircularGauge(
                        label: "AXLE 5",
                        value: data.axle5,
                        min: -20,
                        max: 20,
                        unit: "°",
                        color: Colors.greenAccent,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      height: 180,
                      child: FullCircularGauge(
                        label: "AXLE 6",
                        value: data.axle6,
                        min: -20,
                        max: 20,
                        unit: "°",
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                /// --- FOOTER: Solenoid Status Indicators ---
                const Text(
                  "SOLENOID FAULT MONITOR",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSolenoidPanel(data),

                const SizedBox(height: 40),

                /// --- CONTROLS: Technician Access ---
                _buildControlPanel(context, snapshot.hasData),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(SensorData d) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      decoration: const BoxDecoration(
        color: Colors.black26,
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "SYSTEM HEALTH",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                d.systemMessage.toUpperCase(),
                style: TextStyle(
                  color: d.systemMessage.contains("FAULT")
                      ? Colors.redAccent
                      : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "UDS VOLTAGE",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                "${d.voltage.toStringAsFixed(2)} V",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSolenoidPanel(SensorData d) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 15,
      children: [
        _statusLight("LS", d.ls),
        _statusLight("A5 LK1", d.a5lk1),
        _statusLight("A5 LK2", d.a5lk2),
        _statusLight("A6 LK1", d.a6lk1),
        _statusLight("A6 LK2", d.a6lk2),
      ],
    );
  }

  Widget _statusLight(String label, bool isFault) {
    final color = isFault ? Colors.redAccent : Colors.greenAccent;
    return Column(
      children: [
        Container(
          width: 60,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isFault ? "FAULT" : "OK",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildControlPanel(BuildContext context, bool isOnline) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Text(
            "TECHNICIAN CONTROLS (UDS)",
            style: TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("REFRESH VOLTAGE"),
                onPressed: isOnline ? () => service.requestVoltage() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings_backup_restore),
                label: const Text("CALIBRATE AXLE 5"),
                onPressed: isOnline
                    ? () => _showCalibrateDialog(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCalibrateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          "WARNING",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure? This will reset Axle 5 sensor to ZERO via UDS Write (0x2E).",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              service.calibrateAxle5();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Calibration Request Sent (0x2E)"),
                ),
              );
            },
            child: const Text("EXECUTE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
