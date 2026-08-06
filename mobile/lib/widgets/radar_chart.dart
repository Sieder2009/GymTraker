import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Generic N-axis spider/radar chart, ported 1:1 from the original's pure
/// SVG `RadarChart.svelte`. [values] are 0..100, same length as [labels].
class RadarChart extends StatelessWidget {
  const RadarChart({
    super.key,
    required this.labels,
    required this.values,
    required this.lineColor,
    required this.accentColor,
    required this.mutedColor,
    this.size = 260,
  });

  final List<String> labels;
  final List<double> values;
  final Color lineColor;
  final Color accentColor;
  final Color mutedColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarChartPainter(
          labels: labels,
          values: values,
          lineColor: lineColor,
          accentColor: accentColor,
          mutedColor: mutedColor,
        ),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter({
    required this.labels,
    required this.values,
    required this.lineColor,
    required this.accentColor,
    required this.mutedColor,
  });

  final List<String> labels;
  final List<double> values;
  final Color lineColor;
  final Color accentColor;
  final Color mutedColor;

  static const double _r = 92;
  static const List<double> _rings = [0.25, 0.5, 0.75, 1.0];

  double _angle(int i, int n) => -pi / 2 + (i * 2 * pi / n);

  Offset _pt(Offset c, int i, int n, double frac) {
    final a = _angle(i, n);
    return c + Offset(cos(a), sin(a)) * _r * frac;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    if (n == 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final gridPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final f in _rings) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = _pt(c, i, n, f);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, _pt(c, i, n, 1.0), gridPaint);
    }

    final valuePath = Path();
    for (var i = 0; i < n; i++) {
      final frac = max(0.04, values[i] / 100); // 4% floor so 0 stays visible
      final p = _pt(c, i, n, frac);
      if (i == 0) {
        valuePath.moveTo(p.dx, p.dy);
      } else {
        valuePath.lineTo(p.dx, p.dy);
      }
    }
    valuePath.close();
    canvas.drawPath(
      valuePath,
      Paint()
        ..color = accentColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      valuePath,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < n; i++) {
      final frac = max(0.04, values[i] / 100);
      canvas.drawCircle(_pt(c, i, n, frac), 3, Paint()..color = accentColor);
    }

    for (var i = 0; i < n; i++) {
      final p = _pt(c, i, n, 1.28); // just outside the outer ring
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: mutedColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) {
    return old.values != values ||
        old.labels != labels ||
        old.accentColor != accentColor ||
        old.lineColor != lineColor ||
        old.mutedColor != mutedColor;
  }
}
