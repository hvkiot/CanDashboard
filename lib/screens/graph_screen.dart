// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:steering/widgets/circular_gauge.dart';
import 'package:steering/widgets/theme_toggle_button.dart';
import 'package:steering/themes/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:steering/services/chart_buffer.dart';
import 'package:steering/models/sensor_data.dart';

class GraphScreen extends StatefulWidget {
  final Stream<SensorData> stream;
  const GraphScreen({super.key, required this.stream});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final buffer = ChartBuffer(maxPoints: 840);
  late Stream<SensorData> stream;
  late DateTime startTime;
  late DateTime date = DateTime.now();

  String get _formattedDate {
    return "${date.day.toString().padLeft(2, '0')}:${date.month.toString().padLeft(2, '0')}:${date.year.toString().substring(2)}/"
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    stream = widget.stream;
    startTime = DateTime.now();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          date = DateTime.now();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: const Text(
          "REAR AXLE POWER STEERING SIMULATOR",
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildLegend(context),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 18),
            child: Center(child: ThemeToggleButton(iconSize: 24)),
          ),
        ],
      ),
      body: StreamBuilder<SensorData>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            buffer.add(snapshot.data!);
          }
          final width = MediaQuery.of(context).size.width;
          final height = MediaQuery.of(context).size.height;
          final isWide = width >= 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: height * 0.02),
                  isWide
                      ? _wideLayout(snapshot, context)
                      : _narrowLayout(snapshot, context),
                  SizedBox(height: height * 0.05),
                  Text(
                    _formattedDate,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _wideLayout(AsyncSnapshot<SensorData> snapshot, BuildContext context) {
    return Column(
      children: [
        /// ─── AXLE 01 (TOP CENTER) ───
        SizedBox(
          width: 200,
          height: 150,
          child: FullCircularGauge(
            label: "AXLE 01",
            value: snapshot.data?.axle1 ?? 0.0,
            min: -35,
            max: 35,
            unit: "",
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 65),

        /// ─── AXLE 05 & AXLE 06 ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200,
              height: 150,
              child: FullCircularGauge(
                label: "AXLE 05",
                value: snapshot.data?.axle5 ?? 0.0,
                min: -20,
                max: 20,
                unit: "",
                color: Colors.red,
              ),
            ),
            _dataSection(snapshot),
            SizedBox(
              width: 200,
              height: 150,
              child: FullCircularGauge(
                label: "AXLE 06",
                value: snapshot.data?.axle6 ?? 0.0,
                min: -20,
                max: 20,
                unit: "",
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _narrowLayout(
    AsyncSnapshot<SensorData> snapshot,
    BuildContext context,
  ) {
    final height = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 42),
      child: SizedBox(
        height: max(
          height,
          (height * 0.25 + max(height * 0.02, 60)) + (220 + 12) * 3,
        ),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 200,
                height: 150,
                child: FullCircularGauge(
                  label: "AXLE 01",
                  value: snapshot.data?.axle1 ?? 0.0,
                  min: -35,
                  max: 35,
                  unit: "",
                  color: Colors.amber,
                ),
              ),

              const SizedBox(height: 62),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 150,
                        child: FullCircularGauge(
                          label: "AXLE 05",
                          value: snapshot.data?.axle5 ?? 0.0,
                          min: -20,
                          max: 20,
                          unit: "",
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        height: 150,
                        child: FullCircularGauge(
                          label: "AXLE 06",
                          value: snapshot.data?.axle6 ?? 0.0,
                          min: -20,
                          max: 20,
                          unit: "",
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 45),

                  _dataSection(snapshot),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(
              color: Colors.red,
              text: "Axle 5",
              isDarkMode: themeProvider.isDarkMode,
            ),
            const SizedBox(width: 20),
            _Legend(
              color: Colors.amber,
              text: "Axle 1",
              isDarkMode: themeProvider.isDarkMode,
            ),
            const SizedBox(width: 20),
            _Legend(
              color: Colors.green,
              text: "Axle 6",
              isDarkMode: themeProvider.isDarkMode,
            ),
          ],
        );
      },
    );
  }

  Widget _dataSection(AsyncSnapshot<SensorData> snapshot) {
    final d = snapshot.data;
    Widget dataBox(String label, String value) {
      return Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 70),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white12,
              border: Border.all(color: Colors.grey.shade600),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          /// ERROR DEGREE
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 40,
            runSpacing: 12,
            children: [
              dataBox("A5 ERROR", "${d?.a5Error ?? 0}"),
              dataBox("A6 ERROR", "${d?.a6Error ?? 0}"),
            ],
          ),

          const SizedBox(height: 15),

          /// CURRENT AMPERE
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 40,
            runSpacing: 12,
            children: [
              dataBox("A5 AMP", "${d?.a5Amp ?? 0}"),
              dataBox("A6 AMP", "${d?.a6Amp ?? 0}"),
            ],
          ),
          const SizedBox(height: 15),

          /// SYSTEM MESSAGE
          // Container(
          //   width: double.infinity,
          //   constraints: const BoxConstraints(maxWidth: 420),
          //   padding: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: Colors.white12,
          //     border: Border.all(color: Colors.grey.shade600),
          //     borderRadius: BorderRadius.circular(6),
          //   ),
          //   child: Text(
          //     d?.systemMessage ?? "SYSTEM OK",
          //     textAlign: TextAlign.center,
          //     style: TextStyle(
          //       fontWeight: FontWeight.bold,
          //       color: _messageColor(d?.systemMessage),
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 15),

          /// SOLENOID STATUS
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white12,
              border: Border.all(color: Colors.grey.shade600),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                const Text(
                  "SOLENOID STATUS",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SolStatus("A5LK1", d?.a5lk1 ?? false),
                    SolStatus("A5LK2", d?.a5lk2 ?? false),
                    SolStatus("A6LK1", d?.a6lk1 ?? false),
                    SolStatus("A6LK2", d?.a6lk2 ?? false),
                    SolStatus("LS", d?.ls ?? false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Color _messageColor(String? msg) {
  //   if (msg == null) return Colors.green;
  //   if (msg.contains("LOW") || msg.contains("HIGH")) {
  //     return Colors.redAccent;
  //   }
  //   return Colors.green;
  // }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  final bool isDarkMode;

  const _Legend({
    required this.color,
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Color(0xFF757575),
          ),
        ),
      ],
    );
  }
}

class SolStatus extends StatelessWidget {
  final String label;
  final bool isOn;

  const SolStatus(this.label, this.isOn, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = isOn ? Colors.green : Colors.red;

    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 6),
        Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isOn ? "ON" : "OFF",
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}
