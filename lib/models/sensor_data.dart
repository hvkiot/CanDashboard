class SensorData {
  /// ─── GAUGES ───
  final double axle1; // AXLE 01 angle
  final double axle5; // AXLE 05 angle
  final double axle6; // AXLE 06 angle

  /// ─── NUMERIC DATA ───
  final double a5Error; // A5 ERROR DEGREE
  final double a6Error; // A6 ERROR DEGREE
  final double a5Amp; // A5 CURRENT AMPERE
  final double a6Amp; // A6 CURRENT AMPERE

  /// ─── STATUS / TEXT ───
  final String systemMessage;

  /// ─── SOLENOIDS ───
  final bool a5lk1;
  final bool a5lk2;
  final bool a6lk1;
  final bool a6lk2;
  final bool ls;

  /// ─── TIME ───
  final DateTime time;

  SensorData({
    required this.axle1,
    required this.axle5,
    required this.axle6,
    required this.a5Error,
    required this.a6Error,
    required this.a5Amp,
    required this.a6Amp,
    required this.systemMessage,
    required this.a5lk1,
    required this.a5lk2,
    required this.a6lk1,
    required this.a6lk2,
    required this.ls,
    required this.time,
  });

  @override
  String toString() {
    return 'SensorData(axle1: $axle1, axle5: $axle5, axle6: $axle6, '
        'a5Error: $a5Error, a6Error: $a6Error, a5Amp: $a5Amp, a6Amp: $a6Amp, '
        'systemMessage: $systemMessage, time: $time)';
  }
}
