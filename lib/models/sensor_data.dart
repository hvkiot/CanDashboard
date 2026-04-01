class LiveSensorData {
  /// ─── GAUGES ───
  final double axle1; // AXLE 01 angle
  final double axle5; // AXLE 05 angle
  final double axle6; // AXLE 06 angle

  /// ─── NUMERIC DATA ───
  final double a5Error; // A5 ERROR DEGREE
  final double a6Error; // A6 ERROR DEGREE
  final double a5Amp; // A5 CURRENT AMPERE
  final double a6Amp; // A6 CURRENT AMPERE

  /// ─── SOLENOIDS ───
  final bool a5lk1;
  final bool a5lk2;
  final bool a6lk1;
  final bool a6lk2;
  final bool ls;

  /// ─── TIME ───
  final DateTime time;

  LiveSensorData({
    required this.axle1,
    required this.axle5,
    required this.axle6,
    required this.a5Error,
    required this.a6Error,
    required this.a5Amp,
    required this.a6Amp,
    required this.a5lk1,
    required this.a5lk2,
    required this.a6lk1,
    required this.a6lk2,
    required this.ls,
    required this.time,
  });

  factory LiveSensorData.initial() {
    return LiveSensorData(
      axle1: 0.0,
      axle5: 0.0,
      axle6: 0.0,
      a5Error: 0.0,
      a6Error: 0.0,
      a5Amp: 0.0,
      a6Amp: 0.0,
      a5lk1: false,
      a5lk2: false,
      a6lk1: false,
      a6lk2: false,
      ls: false,
      time: DateTime.now(),
    );
  }

  LiveSensorData copyWith({
    double? axle1,
    double? axle5,
    double? axle6,
    double? a5Error,
    double? a6Error,
    double? a5Amp,
    double? a6Amp,
    bool? a5lk1,
    bool? a5lk2,
    bool? a6lk1,
    bool? a6lk2,
    bool? ls,
    DateTime? time,
  }) {
    return LiveSensorData(
      axle1: axle1 ?? this.axle1,
      axle5: axle5 ?? this.axle5,
      axle6: axle6 ?? this.axle6,
      a5Error: a5Error ?? this.a5Error,
      a6Error: a6Error ?? this.a6Error,
      a5Amp: a5Amp ?? this.a5Amp,
      a6Amp: a6Amp ?? this.a6Amp,
      a5lk1: a5lk1 ?? this.a5lk1,
      a5lk2: a5lk2 ?? this.a5lk2,
      a6lk1: a6lk1 ?? this.a6lk1,
      a6lk2: a6lk2 ?? this.a6lk2,
      ls: ls ?? this.ls,
      time: time ?? this.time,
    );
  }
}

class UdsSystemData {
  final double voltage;
  final String firmwareVersion;
  final int ecuSerial;
  final String systemMessage;

  UdsSystemData({
    required this.voltage,
    required this.firmwareVersion,
    required this.ecuSerial,
    required this.systemMessage,
  });

  factory UdsSystemData.initial() {
    return UdsSystemData(
      voltage: 0.0,
      firmwareVersion: "Checking...",
      ecuSerial: 0,
      systemMessage: "INITIALIZING",
    );
  }

  UdsSystemData copyWith({
    double? voltage,
    String? firmwareVersion,
    int? ecuSerial,
    String? systemMessage,
  }) {
    return UdsSystemData(
      voltage: voltage ?? this.voltage,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      ecuSerial: ecuSerial ?? this.ecuSerial,
      systemMessage: systemMessage ?? this.systemMessage,
    );
  }
}

class CombinedState {
  final LiveSensorData live;
  final UdsSystemData uds;

  CombinedState({
    required this.live,
    required this.uds,
  });

  factory CombinedState.initial() {
    return CombinedState(
      live: LiveSensorData.initial(),
      uds: UdsSystemData.initial(),
    );
  }

  CombinedState copyWith({
    LiveSensorData? live,
    UdsSystemData? uds,
  }) {
    return CombinedState(
      live: live ?? this.live,
      uds: uds ?? this.uds,
    );
  }
}
