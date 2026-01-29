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

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      axle1: (json['axle1'] as num).toDouble(),
      axle5: (json['axle5'] as num).toDouble(),
      axle6: (json['axle6'] as num).toDouble(),

      a5Error: (json['a5_error'] as num).toDouble(),
      a6Error: (json['a6_error'] as num).toDouble(),
      a5Amp: (json['a5_amp'] as num).toDouble(),
      a6Amp: (json['a6_amp'] as num).toDouble(),

      systemMessage: json['system_message'] ?? "SYSTEM OK",

      a5lk1: json['a5lk1'] == 1,
      a5lk2: json['a5lk2'] == 1,
      a6lk1: json['a6lk1'] == 1,
      a6lk2: json['a6lk2'] == 1,
      ls: json['ls'] == 1,

      time: DateTime.now(), // auto timestamp
    );
  }
}
