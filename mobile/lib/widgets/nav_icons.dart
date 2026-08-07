import 'package:flutter/material.dart';

/// Bottom-nav glyphs ported 1:1 from the web app's hand-drawn SVG paths
/// (`TabBar.svelte`) so the Flutter tab bar matches the web app pixel-for-
/// pixel instead of falling back to generic Material icons: a barbell rack
/// for Training, weight plates for Kraft, a bar chart for Fortschritt.
class NavIcon extends StatelessWidget {
  const NavIcon(this.type, {super.key, this.size = 21, this.color});

  final NavIconType type;
  final double size;

  /// Falls back to the ambient [IconTheme] color — [BottomNavigationBar]
  /// already wraps each item in the right selected/unselected [IconTheme],
  /// so this matches how a plain [Icon] picks up its color for free.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _NavIconPainter(type, color ?? IconTheme.of(context).color ?? Colors.black),
    );
  }
}

enum NavIconType { training, strength, progress, exercises }

class _NavIconPainter extends CustomPainter {
  _NavIconPainter(this.type, this.color);

  final NavIconType type;
  final Color color;

  // Paths are defined on a 24x24 grid, same as the original SVG viewBox.
  static const double _grid = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _grid;
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final segment in _segments(type)) {
      final path = Path()..moveTo(segment.first.dx, segment.first.dy);
      for (final point in segment.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  static List<List<Offset>> _segments(NavIconType type) {
    switch (type) {
      case NavIconType.training:
        // Barbell rack: two uprights + a crossbar.
        return const [
          [Offset(6, 7), Offset(6, 17)],
          [Offset(18, 7), Offset(18, 17)],
          [Offset(2, 10), Offset(2, 14)],
          [Offset(22, 10), Offset(22, 14)],
          [Offset(6, 12), Offset(18, 12)],
        ];
      case NavIconType.strength:
        // Weight plates on a bar.
        return const [
          [Offset(4, 9), Offset(4, 15)],
          [Offset(8, 7), Offset(8, 17)],
          [Offset(16, 7), Offset(16, 17)],
          [Offset(20, 9), Offset(20, 15)],
          [Offset(8, 12), Offset(16, 12)],
        ];
      case NavIconType.progress:
        // Ascending bar chart.
        return const [
          [Offset(5, 21), Offset(5, 11)],
          [Offset(12, 21), Offset(12, 4)],
          [Offset(19, 21), Offset(19, 14)],
        ];
      case NavIconType.exercises:
        // A short checklist — 3 rows of tick + line.
        return const [
          [Offset(4, 6), Offset(6, 8), Offset(9, 4)],
          [Offset(12, 6), Offset(20, 6)],
          [Offset(4, 13), Offset(6, 15), Offset(9, 11)],
          [Offset(12, 13), Offset(20, 13)],
          [Offset(4, 20), Offset(6, 22), Offset(9, 18)],
          [Offset(12, 20), Offset(20, 20)],
        ];
    }
  }

  @override
  bool shouldRepaint(covariant _NavIconPainter old) {
    return old.type != type || old.color != color;
  }
}
