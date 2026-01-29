import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:steering/themes/theme_provider.dart';

class FullCircularGauge extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final double? size;
  final Color color;

  const FullCircularGauge({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SizedBox(
          width: size ?? 200,
          height: size != null ? size! * 0.75 : 160,
          child: CustomPaint(
            painter: _FullGaugePainter(
              value,
              min,
              max,
              label,
              unit,
              color,
              themeProvider.isDarkMode,
            ),
          ),
        );
      },
    );
  }
}

class _FullGaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final String label;
  final String unit;
  final Color positiveColor;
  final bool isDarkMode;

  _FullGaugePainter(
    this.value,
    this.min,
    this.max,
    this.label,
    this.unit,
    this.positiveColor,
    this.isDarkMode,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 14;

    const startAngle = pi * 3 / 4; // 135°
    const sweepAngle = pi * 3 / 2; // 270°

    /// Zero position
    final zeroPercent = (0 - min) / (max - min);

    /// Needle percent
    final needlePercent = ((value - min) / (max - min)).clamp(0.0, 1.0);

    /// Positive / Negative progress
    double positivePercent = 0.0;
    double negativePercent = 0.0;

    if (value > 0) {
      positivePercent = (value / max).clamp(0.0, 1.0);
    } else if (value < 0) {
      negativePercent = (value.abs() / min.abs()).clamp(0.0, 1.0);
    }

    /// Background Arc
    final bgPaint = Paint()
      ..color = isDarkMode ? Colors.white12 : Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    /// 🔵 NEGATIVE ARC (0 → min)
    if (negativePercent > 0) {
      final negPaint = Paint()
        ..color = positiveColor
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final negSweep = sweepAngle * (zeroPercent * negativePercent);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweepAngle * zeroPercent - negSweep,
        negSweep,
        false,
        negPaint,
      );
    }

    /// 🔴 POSITIVE ARC (0 → max)
    if (positivePercent > 0) {
      final posPaint = Paint()
        ..color = positiveColor
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweepAngle * zeroPercent,
        sweepAngle * ((1 - zeroPercent) * positivePercent),
        false,
        posPaint,
      );
    }

    /// Tick Marks
    final tickPaint = Paint()
      ..color = isDarkMode ? Colors.white70 : const Color(0xFF757575)
      ..strokeWidth = 1;

    const totalTicks = 40;
    for (int i = 0; i <= totalTicks; i++) {
      final angle = startAngle + (sweepAngle / totalTicks) * i;
      final isMajor = i % 5 == 0;

      final inner = radius - (isMajor ? 16 : 8);
      final outer = radius - 2;

      canvas.drawLine(
        Offset(center.dx + inner * cos(angle), center.dy + inner * sin(angle)),
        Offset(center.dx + outer * cos(angle), center.dy + outer * sin(angle)),
        tickPaint,
      );

      if (isMajor) {
        final tickValue = min + (max - min) * (i / totalTicks);

        final tp = TextPainter(
          text: TextSpan(
            text: tickValue.toInt().toString(),
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.white70 : const Color(0xFF757575),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();

        final textRadius = radius - 32;
        tp.paint(
          canvas,
          Offset(
            center.dx + textRadius * cos(angle) - tp.width / 2,
            center.dy + textRadius * sin(angle) - tp.height / 2,
          ),
        );
      }
    }

    /// Needle
    final needleAngle = startAngle + sweepAngle * needlePercent;

    final needlePaint = Paint()
      ..color = const Color(0xFF7C6BFF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius - 28) * cos(needleAngle),
        center.dy + (radius - 28) * sin(needleAngle),
      ),
      needlePaint,
    );

    canvas.drawCircle(
      center,
      5,
      Paint()..color = isDarkMode ? Colors.white : const Color(0xFF212121),
    );

    /// Value
    final valuePainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: "$value $unit",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : const Color(0xFF212121),
        ),
      ),
    );
    valuePainter.layout();
    valuePainter.paint(
      canvas,
      Offset(
        center.dx - valuePainter.width / 2,
        center.dy + 100 - valuePainter.height / 2,
      ),
    );

    /// Label
    final labelPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.white70 : const Color(0xFF757575),
        ),
      ),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy + 70),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
