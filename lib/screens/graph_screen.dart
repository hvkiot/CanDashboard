import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:steering/widgets/circular_gauge.dart';
import 'package:steering/widgets/theme_toggle_button.dart';
import 'package:steering/themes/theme_provider.dart';
import 'package:steering/services/chart_buffer.dart';
import 'package:steering/models/sensor_data.dart';
import 'package:steering/services/raps_can_service.dart';

class GraphScreen extends StatefulWidget {
  final Stream<SensorData> stream;
  final RapsCanService service;

  const GraphScreen({super.key, required this.stream, required this.service});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final buffer = ChartBuffer(maxPoints: 840);
  late Stream<SensorData> stream;
  late DateTime date = DateTime.now();
  StreamSubscription? _sub;

  String get _formattedDate {
    return "${date.day.toString().padLeft(2, '0')}:${date.month.toString().padLeft(2, '0')}:${date.year.toString().substring(2)}/"
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    stream = widget.stream;
    _setupMessageListener();

    // Update clock every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          date = DateTime.now();
        });
      }
    });
  }

  /// NEW LOGIC: Listens for UDS Success messages to show SnackBar
  void _setupMessageListener() {
    _sub = stream.listen((data) {
      if (data.systemMessage.contains("Successful") ||
          data.systemMessage.contains("Success")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data.systemMessage),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
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
                children: [
                  SizedBox(height: height * 0.05),

                  // Keep your Old Wide/Narrow Layout Toggle
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

  // --- OLD UI: Wide Layout ---
  Widget _wideLayout(AsyncSnapshot<SensorData> snapshot, BuildContext context) {
    return Column(
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
        const SizedBox(height: 65),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sideGauge("AXLE 05", snapshot.data?.axle5 ?? 0.0, Colors.red),
            _dataSection(snapshot),
            _sideGauge("AXLE 06", snapshot.data?.axle6 ?? 0.0, Colors.green),
          ],
        ),
      ],
    );
  }

  // --- OLD UI: Narrow Layout ---
  Widget _narrowLayout(
    AsyncSnapshot<SensorData> snapshot,
    BuildContext context,
  ) {
    return Column(
      children: [
        _sideGauge("AXLE 01", snapshot.data?.axle1 ?? 0.0, Colors.amber),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _sideGauge("AXLE 05", snapshot.data?.axle5 ?? 0.0, Colors.red),
            _sideGauge("AXLE 06", snapshot.data?.axle6 ?? 0.0, Colors.green),
          ],
        ),
        const SizedBox(height: 40),
        _dataSection(snapshot),
      ],
    );
  }

  Widget _sideGauge(String label, double value, Color color) {
    return SizedBox(
      width: 200,
      height: 150,
      child: FullCircularGauge(
        label: label,
        value: value,
        min: -20,
        max: 20,
        unit: "",
        color: color,
      ),
    );
  }

  // --- MERGED LOGIC: Data Section with UDS Panel ---
  Widget _dataSection(AsyncSnapshot<SensorData> snapshot) {
    final d = snapshot.data;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 40,
            children: [
              _dataBox("A5 ERROR", "${d?.a5Error ?? 0}"),
              _dataBox("A6 ERROR", "${d?.a6Error ?? 0}"),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 40,
            children: [
              _dataBox("A5 AMP", "${d?.a5Amp ?? 0}"),
              _dataBox("A6 AMP", "${d?.a6Amp ?? 0}"),
            ],
          ),
          const SizedBox(height: 25),

          // NEW LOGIC: UDS Control Panel integrated into Old UI
          _udsSection(snapshot),

          const SizedBox(height: 25),
          _solenoidStatusPanel(d),
        ],
      ),
    );
  }

  Widget _udsSection(AsyncSnapshot<SensorData> snapshot) {
    final d = snapshot.data;
    final hasData = snapshot.hasData;
    // Don't show "Success" text in the voltage field
    final voltageDisp = (d != null && !d.systemMessage.contains("Success"))
        ? d.systemMessage
        : "0.0";

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        border: Border.all(
          color: Colors.blueAccent.withOpacity(0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Text(
            "UDS CONTROLS",
            style: TextStyle(
              fontSize: 12,
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.bolt, color: Colors.yellow),
                    onPressed: hasData
                        ? () => widget.service.requestVoltage()
                        : null,
                  ),
                  Text(
                    "$voltageDisp V",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: hasData ? () => _showCalibrationDialog() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  "CALIBRATE",
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dataBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(minWidth: 70),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white12,
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _solenoidStatusPanel(SensorData? d) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white12,
        border: Border.all(color: Colors.grey.shade600),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          SolStatus("A5LK1", d?.a5lk1 ?? false),
          SolStatus("A5LK2", d?.a5lk2 ?? false),
          SolStatus("A6LK1", d?.a6lk1 ?? false),
          SolStatus("A6LK2", d?.a6lk2 ?? false),
          SolStatus("LS", d?.ls ?? false),
        ],
      ),
    );
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          "Confirm Calibration",
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          "Ensure axles are at 0°. This sends UDS Write (0x2E).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              widget.service.calibrateAxle5();
              Navigator.pop(context);
            },
            child: const Text(
              "EXECUTE",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, tp, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Legend(color: Colors.red, text: "Axle 5", isDarkMode: tp.isDarkMode),
          const SizedBox(width: 20),
          _Legend(
            color: Colors.amber,
            text: "Axle 1",
            isDarkMode: tp.isDarkMode,
          ),
          const SizedBox(width: 20),
          _Legend(
            color: Colors.green,
            text: "Axle 6",
            isDarkMode: tp.isDarkMode,
          ),
        ],
      ),
    );
  }
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
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
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
        Text(label, style: const TextStyle(fontSize: 10)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isOn ? "ON" : "OFF",
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
