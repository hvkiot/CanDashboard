import 'dart:async';
import 'dart:math';
import '../models/sensor_data.dart';

class MockSensorStream {
  final _controller = StreamController<SensorData>.broadcast();
  Stream<SensorData> get stream => _controller.stream;

  Timer? _timer;
  double _t = 0.0; // time accumulator

  MockSensorStream() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _t += 0.1;

      /// ─── AXLE ANGLES (GAUGES) ───
      final axle1 = _fix(35 * sin(_t)); // -35 .. +35
      final axle5 = _fix(20 * sin(_t * 0.8)); // -20 .. +20
      final axle6 = _fix(20 * sin(_t * 0.6)); // -20 .. +20

      /// ─── ERROR DEGREES ───
      final a5Error = _fix(axle1 - axle5);
      final a6Error = _fix(axle1 - axle6);

      /// ─── CURRENT (AMPERE) ───
      final a5Amp = _fix(1.5 + 1.2 * sin(_t * 1.2)); // ~0.3–2.7 A
      final a6Amp = _fix(1.6 + 1.0 * sin(_t * 1.0));

      /// ─── HYDRAULICS ───
      final pressure = _fix(150 + 20 * sin(_t * 0.3)); // BAR
      final temp = _fix(45 + 8 * sin(_t * 0.2)); // °C

      /// ─── SOLENOID STATES ───
      final a5lk1 = axle5.abs() > 2;
      final a5lk2 = axle5.abs() > 5;
      final a6lk1 = axle6.abs() > 2;
      final a6lk2 = axle6.abs() > 5;
      final ls = pressure > 140;

      /// ─── SYSTEM MESSAGE ───
      final systemMessage = (pressure < 120)
          ? "LOW PRESSURE"
          : (temp > 60)
          ? "HIGH OIL TEMP"
          : "SYSTEM NORMAL";

      _controller.add(
        SensorData(
          axle1: axle1,
          axle5: axle5,
          axle6: axle6,

          a5Error: a5Error,
          a6Error: a6Error,
          a5Amp: a5Amp,
          a6Amp: a6Amp,

          pressure: pressure,
          temp: temp,

          systemMessage: systemMessage,

          a5lk1: a5lk1,
          a5lk2: a5lk2,
          a6lk1: a6lk1,
          a6lk2: a6lk2,
          ls: ls,

          time: DateTime.now(),
        ),
      );
    });
  }

  double _fix(double v) => double.parse(v.toStringAsFixed(1));

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
