import 'package:steering/models/sensor_data.dart';
import 'package:steering/services/chart_buffer.dart';
import 'package:steering/themes/theme_provider.dart' show ThemeProvider;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget singleAxleChart(
  String title,
  Color color,
  double Function(SensorData) selector,
  double baseMinY,
  double baseMaxY,
  BuildContext context,
  ChartBuffer buffer,
) {
  final data = buffer.data;

  // ---------------- TIME → X AXIS ----------------
  const double sampleIntervalMs = 100; // 100 ms per sample

  final spots = List.generate(
    data.length,
    (index) => FlSpot(index * sampleIntervalMs, selector(data[index])),
  );
  if (spots.isEmpty) {
    return const SizedBox.shrink();
  }

  final minX = 0.0;

  // ---------------- Y AXIS AUTO SCALE ----------------
  final values = data.map(selector).toList();

  final baseRange = ChartUtils.axleRanges[title.replaceAll(' ', '')]!;

  final dynamicRange = ChartUtils.calculateDynamicRange(
    values: values,
    baseMin: baseRange.min,
    baseMax: baseRange.max,
  );

  final minY = dynamicRange.min;
  final maxY = dynamicRange.max;

  final gridInterval = (maxY - minY) / 2;

  // ---------------- UI ----------------
  return Consumer<ThemeProvider>(
    builder: (context, themeProvider, _) {
      final isDark = themeProvider.isDarkMode;
      final containerBgColor = isDark ? Color(0xFF1B1F2A) : Color(0xFFF5F5F5);
      final textColor = isDark ? Colors.white70 : Color(0xFF757575);
      final gridColor = isDark ? Colors.white12 : Color(0xFFE0E0E0);
      final borderColor = isDark ? Colors.white24 : Color(0xFFBDBDBD);
      final zeroLineColor = isDark ? Colors.white38 : Color(0xFF9E9E9E);

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: containerBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                _valueBadge(spots.last.y, isDark),
              ],
            ),
            const SizedBox(height: 8),

            Expanded(
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: 839 * 100,
                  minY: minY,
                  maxY: maxY,

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 2,
                      color: color,
                      dotData: FlDotData(show: false),
                    ),
                  ],

                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: zeroLineColor,
                        strokeWidth: 2,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: gridInterval,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: gridColor, strokeWidth: 1),
                  ),

                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: borderColor),
                  ),

                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false, interval: 5000),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: gridInterval,
                        getTitlesWidget: (value, meta) {
                          const epsilon = 0.01;

                          final exceedsMin = minY < baseMinY;
                          final exceedsMax = maxY > baseMaxY;

                          final showMin = exceedsMin ? minY : baseMinY;
                          final showMax = exceedsMax ? maxY : baseMaxY;

                          final isMin = (value - showMin).abs() < epsilon;
                          final isMax = (value - showMax).abs() < epsilon;
                          final isZero = value.abs() < epsilon;

                          // ✅ Show only MIN, ZERO, MAX
                          if (!isMin && !isZero && !isMax) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 9, color: textColor),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: gridInterval,
                        getTitlesWidget: (value, meta) {
                          const epsilon = 0.01;

                          final exceedsMin = minY < baseMinY;
                          final exceedsMax = maxY > baseMaxY;

                          final showMin = exceedsMin ? minY : baseMinY;
                          final showMax = exceedsMax ? maxY : baseMaxY;

                          final isMin = (value - showMin).abs() < epsilon;
                          final isMax = (value - showMax).abs() < epsilon;
                          final isZero = value.abs() < epsilon;

                          // ✅ Show only MIN, ZERO, MAX
                          if (!isMin && !isZero && !isMax) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            '  ${value.toInt().toString()}',
                            style: TextStyle(fontSize: 9, color: textColor),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
                duration: Duration.zero,
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _valueBadge(double value, bool isDarkMode) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isDarkMode ? Color(0xFF0E1116) : Color(0xFFFAFAFA),
      border: Border.all(
        color: isDarkMode ? Colors.white38 : Color(0xFFBDBDBD),
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      "${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}°",
      style: TextStyle(
        fontFamily: 'Courier',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.amber : Color(0xFF212121),
      ),
    ),
  );
}
