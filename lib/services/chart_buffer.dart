import 'package:steering/models/sensor_data.dart';

class ChartBuffer {
  final int maxPoints;
  final List<CombinedState> _data = [];

  ChartBuffer({this.maxPoints = 100});

  void add(CombinedState d) {
    _data.add(d);
    if (_data.length > maxPoints) {
      _data.removeAt(0);
    }
  }

  List<CombinedState> get data => List.unmodifiable(_data);
}

class ChartUtils {
  // Calculate dynamic Y-axis range with intelligent scaling
  static ({double min, double max}) calculateDynamicRange({
    required List<double> values,
    double baseMin = -30,
    double baseMax = 30,
    double marginPercent = 0.1, // 10% margin
    double minStep = 5, // Minimum range expansion step
  }) {
    if (values.isEmpty) return (min: baseMin, max: baseMax);

    final currentMin = values.reduce((a, b) => a < b ? a : b);
    final currentMax = values.reduce((a, b) => a > b ? a : b);

    // Check if data exceeds base range
    final exceedsMin = currentMin < baseMin;
    final exceedsMax = currentMax > baseMax;

    if (!exceedsMin && !exceedsMax) {
      return (min: baseMin, max: baseMax);
    }

    // Calculate expanded range
    double expandedMin = baseMin;
    double expandedMax = baseMax;

    if (exceedsMin) {
      final diff = baseMin - currentMin;
      // Expand by diff + margin, rounded to nearest step
      expandedMin =
          baseMin -
          ((diff / minStep).ceil() * minStep) -
          (diff * marginPercent);
    }

    if (exceedsMax) {
      final diff = currentMax - baseMax;
      expandedMax =
          baseMax +
          ((diff / minStep).ceil() * minStep) +
          (diff * marginPercent);
    }

    // Ensure at least some expansion for visibility
    final range = expandedMax - expandedMin;
    final targetRange = (currentMax - currentMin) * (1 + marginPercent * 2);

    if (range < targetRange) {
      final extra = (targetRange - range) / 2;
      expandedMin -= extra;
      expandedMax += extra;
    }

    return (min: expandedMin, max: expandedMax);
  }

  // Pre-configured chart ranges for different axles
  static final Map<String, ({double min, double max})> axleRanges = {
    'AXLE1': (min: -30, max: 30),
    'AXLE5': (min: -15, max: 15),
    'AXLE6': (min: -15, max: 15),
    'PRESSURE': (min: 1, max: 7),
    'TEMPERATURE': (min: 0, max: 100),
  };
}
