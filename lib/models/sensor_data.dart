class SensorData {
  /// ─── GAUGES ───
  final double axle1, axle5, axle6; // Axle Angles

  /// ─── NUMERIC DATA ───
  final double a5Error, a6Error; // Error Angles
  final double a5Amp, a6Amp; // Valve Currents
  final double voltage; // System Voltage (UDS)

  /// ─── STATUS / TEXT ───
  final String systemMessage; // System Health Message [Source 2]

  /// ─── SOLENOIDS ───
  final bool a5lk1,
      a5lk2,
      a6lk1,
      a6lk2,
      ls; // Solenoid Statuses (True = Error/Fault) [Source 57]

  /// ─── TIME ───
  final DateTime time;

  SensorData({
    this.axle1 = 0,
    this.axle5 = 0,
    this.axle6 = 0,
    this.a5Error = 0,
    this.a6Error = 0,
    this.a5Amp = 0,
    this.a6Amp = 0,
    this.voltage = 0,
    this.systemMessage = "Initializing...",
    this.a5lk1 = false,
    this.a5lk2 = false,
    this.a6lk1 = false,
    this.a6lk2 = false,
    this.ls = false,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  @override
  String toString() {
    return 'SensorData(axle1: $axle1, axle5: $axle5, axle6: $axle6, '
        'a5Error: $a5Error, a6Error: $a6Error, a5Amp: $a5Amp, a6Amp: $a6Amp, '
        'systemMessage: $systemMessage, time: $time)';
  }
}
