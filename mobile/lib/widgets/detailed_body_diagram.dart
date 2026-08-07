import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/muscle_group.dart';
import '../theme/app_colors.dart';

/// Fractional (0-1) tap-hit regions per muscle — deliberately looser than
/// the visual shapes in [muscleShapeFor] so tapping near a muscle (not
/// pixel-perfect on its curved outline) still registers. Used only by the
/// interactive `MuscleActivationEditor`; the read-only [DetailedBodyDiagram]
/// doesn't need hit-testing at all.
Map<MuscleGroup, List<Rect>> bodyRegionsFor(bool front) {
  if (front) {
    return {
      MuscleGroup.chest: [const Rect.fromLTWH(0.34, 0.21, 0.32, 0.16)],
      MuscleGroup.abs: [const Rect.fromLTWH(0.40, 0.32, 0.20, 0.15)],
      MuscleGroup.obliques: [
        const Rect.fromLTWH(0.36, 0.32, 0.06, 0.15),
        const Rect.fromLTWH(0.58, 0.32, 0.06, 0.15),
      ],
      MuscleGroup.frontDelts: [
        const Rect.fromLTWH(0.16, 0.185, 0.13, 0.10),
        const Rect.fromLTWH(0.71, 0.185, 0.13, 0.10),
      ],
      MuscleGroup.sideDelts: [
        const Rect.fromLTWH(0.10, 0.195, 0.09, 0.10),
        const Rect.fromLTWH(0.81, 0.195, 0.09, 0.10),
      ],
      MuscleGroup.biceps: [
        const Rect.fromLTWH(0.10, 0.25, 0.13, 0.15),
        const Rect.fromLTWH(0.77, 0.25, 0.13, 0.15),
      ],
      MuscleGroup.forearms: [
        const Rect.fromLTWH(0.11, 0.38, 0.11, 0.16),
        const Rect.fromLTWH(0.78, 0.38, 0.11, 0.16),
      ],
      MuscleGroup.quads: [
        const Rect.fromLTWH(0.32, 0.50, 0.15, 0.22),
        const Rect.fromLTWH(0.53, 0.50, 0.15, 0.22),
      ],
      MuscleGroup.calves: [
        const Rect.fromLTWH(0.32, 0.75, 0.13, 0.18),
        const Rect.fromLTWH(0.55, 0.75, 0.13, 0.18),
      ],
    };
  }
  return {
    MuscleGroup.traps: [const Rect.fromLTWH(0.38, 0.15, 0.24, 0.10)],
    MuscleGroup.upperBack: [const Rect.fromLTWH(0.36, 0.23, 0.28, 0.11)],
    MuscleGroup.lats: [const Rect.fromLTWH(0.30, 0.24, 0.40, 0.17)],
    MuscleGroup.lowerBack: [const Rect.fromLTWH(0.37, 0.39, 0.26, 0.11)],
    MuscleGroup.rearDelts: [
      const Rect.fromLTWH(0.14, 0.185, 0.13, 0.09),
      const Rect.fromLTWH(0.73, 0.185, 0.13, 0.09),
    ],
    MuscleGroup.triceps: [
      const Rect.fromLTWH(0.10, 0.25, 0.13, 0.15),
      const Rect.fromLTWH(0.77, 0.25, 0.13, 0.15),
    ],
    MuscleGroup.glutes: [const Rect.fromLTWH(0.34, 0.48, 0.32, 0.13)],
    MuscleGroup.hamstrings: [
      const Rect.fromLTWH(0.32, 0.58, 0.14, 0.20),
      const Rect.fromLTWH(0.54, 0.58, 0.14, 0.20),
    ],
  };
}

/// Fractional (0-1) VISUAL muscle shapes — ovals, tapered wings, a
/// segmented ab grid, roughly following real muscle bellies rather than
/// plain rectangles, so the diagram reads as "muscles" at a glance. Every
/// shape is hand-drawn geometry (never traced from a photo or another
/// app's artwork) — deliberately stylized/schematic, not a medical atlas.
List<Path> muscleShapeFor(MuscleGroup m, bool front, double w, double h) {
  Path oval(double x, double y, double ow, double oh) =>
      Path()..addOval(Rect.fromLTWH(x * w, y * h, ow * w, oh * h));

  switch (m) {
    case MuscleGroup.chest:
      return [oval(0.335, 0.205, 0.155, 0.115), oval(0.51, 0.205, 0.155, 0.115)];
    case MuscleGroup.abs:
      final rows = [0.325, 0.375, 0.425];
      return [
        for (final y in rows) ...[
          _roundedRect(0.455 * w, y * h, 0.042 * w, 0.045 * h),
          _roundedRect(0.503 * w, y * h, 0.042 * w, 0.045 * h),
        ],
      ];
    case MuscleGroup.obliques:
      return [oval(0.365, 0.335, 0.065, 0.135), oval(0.57, 0.335, 0.065, 0.135)];
    case MuscleGroup.frontDelts:
      return [oval(0.175, 0.185, 0.115, 0.085), oval(0.71, 0.185, 0.115, 0.085)];
    case MuscleGroup.sideDelts:
      return [oval(0.105, 0.20, 0.075, 0.095), oval(0.82, 0.20, 0.075, 0.095)];
    case MuscleGroup.biceps:
      return [oval(0.115, 0.255, 0.105, 0.135), oval(0.78, 0.255, 0.105, 0.135)];
    case MuscleGroup.forearms:
      return [oval(0.125, 0.395, 0.085, 0.145), oval(0.79, 0.395, 0.085, 0.145)];
    case MuscleGroup.quads:
      return [oval(0.335, 0.51, 0.125, 0.20), oval(0.54, 0.51, 0.125, 0.20)];
    case MuscleGroup.calves:
      return [oval(0.335, 0.765, 0.10, 0.165), oval(0.565, 0.765, 0.10, 0.165)];
    case MuscleGroup.traps:
      return [_trapShape(w, h)];
    case MuscleGroup.upperBack:
      return [_roundedRect(0.37 * w, 0.245 * h, 0.26 * w, 0.095 * h, r: 0.04)];
    case MuscleGroup.lats:
      return [_latWing(w, h, mirrored: false), _latWing(w, h, mirrored: true)];
    case MuscleGroup.lowerBack:
      return [_roundedRect(0.375 * w, 0.395 * h, 0.25 * w, 0.09 * h, r: 0.04)];
    case MuscleGroup.rearDelts:
      return [oval(0.155, 0.185, 0.115, 0.085), oval(0.73, 0.185, 0.115, 0.085)];
    case MuscleGroup.triceps:
      return [oval(0.115, 0.255, 0.105, 0.135), oval(0.78, 0.255, 0.105, 0.135)];
    case MuscleGroup.glutes:
      return [oval(0.345, 0.475, 0.155, 0.135), oval(0.50, 0.475, 0.155, 0.135)];
    case MuscleGroup.hamstrings:
      return [oval(0.335, 0.59, 0.115, 0.185), oval(0.55, 0.59, 0.115, 0.185)];
  }
}

Path _roundedRect(double x, double y, double w, double h, {double r = 0.3}) {
  return Path()
    ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(w * r)));
}

Path _trapShape(double w, double h) {
  return Path()
    ..moveTo(w * 0.415, h * 0.155)
    ..lineTo(w * 0.585, h * 0.155)
    ..cubicTo(w * 0.58, h * 0.19, w * 0.565, h * 0.225, w * 0.545, h * 0.245)
    ..lineTo(w * 0.455, h * 0.245)
    ..cubicTo(w * 0.435, h * 0.225, w * 0.42, h * 0.19, w * 0.415, h * 0.155)
    ..close();
}

/// The lat "V-taper" — wide at the armpit, narrowing to the waist. Drawn
/// for the left side; [mirrored] reflects it across the body's centerline.
Path _latWing(double w, double h, {required bool mirrored}) {
  final path = Path()
    ..moveTo(w * 0.255, h * 0.255)
    ..cubicTo(w * 0.22, h * 0.30, w * 0.225, h * 0.35, w * 0.27, h * 0.40)
    ..cubicTo(w * 0.32, h * 0.415, w * 0.38, h * 0.415, w * 0.415, h * 0.40)
    ..cubicTo(w * 0.40, h * 0.34, w * 0.385, h * 0.29, w * 0.37, h * 0.255)
    ..cubicTo(w * 0.33, h * 0.24, w * 0.29, h * 0.24, w * 0.255, h * 0.255)
    ..close();
  if (!mirrored) return path;
  final matrix = Matrix4.identity()
    ..translateByDouble(w, 0.0, 0.0, 1.0)
    ..scaleByDouble(-1.0, 1.0, 1.0, 1.0);
  return path.transform(matrix.storage);
}

/// The base humanoid silhouette (head/neck/torso/arms/legs), drawn with
/// smooth tapered curves — a deltoid bulge at the shoulder, a bicep bulge
/// on the upper arm, a quad taper into the knee — instead of blocky
/// rectangles, so the figure itself already reads as a body with muscle
/// contours before any activation color is applied.
class _Silhouette {
  _Silhouette(double w, double h) {
    head = Path()..addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.072), width: w * 0.145, height: h * 0.10));

    neck = Path()
      ..moveTo(w * 0.455, h * 0.115)
      ..lineTo(w * 0.545, h * 0.115)
      ..lineTo(w * 0.565, h * 0.165)
      ..lineTo(w * 0.435, h * 0.165)
      ..close();

    torso = Path()
      ..moveTo(w * 0.435, h * 0.165)
      ..cubicTo(w * 0.32, h * 0.165, w * 0.265, h * 0.185, w * 0.255, h * 0.21)
      ..cubicTo(w * 0.25, h * 0.225, w * 0.265, h * 0.245, w * 0.30, h * 0.265)
      ..cubicTo(w * 0.32, h * 0.31, w * 0.335, h * 0.36, w * 0.35, h * 0.40)
      ..cubicTo(w * 0.345, h * 0.435, w * 0.35, h * 0.455, w * 0.365, h * 0.475)
      ..lineTo(w * 0.635, h * 0.475)
      ..cubicTo(w * 0.65, h * 0.455, w * 0.655, h * 0.435, w * 0.65, h * 0.40)
      ..cubicTo(w * 0.665, h * 0.36, w * 0.68, h * 0.31, w * 0.70, h * 0.265)
      ..cubicTo(w * 0.735, h * 0.245, w * 0.75, h * 0.225, w * 0.745, h * 0.21)
      ..cubicTo(w * 0.735, h * 0.185, w * 0.68, h * 0.165, w * 0.565, h * 0.165)
      ..close();

    leftArm = Path()
      ..moveTo(w * 0.255, h * 0.20)
      ..cubicTo(w * 0.19, h * 0.205, w * 0.145, h * 0.225, w * 0.14, h * 0.255)
      ..cubicTo(w * 0.135, h * 0.285, w * 0.125, h * 0.31, w * 0.125, h * 0.335)
      ..cubicTo(w * 0.125, h * 0.365, w * 0.135, h * 0.385, w * 0.145, h * 0.40)
      ..cubicTo(w * 0.13, h * 0.43, w * 0.125, h * 0.45, w * 0.13, h * 0.48)
      ..cubicTo(w * 0.128, h * 0.50, w * 0.14, h * 0.52, w * 0.155, h * 0.535)
      ..lineTo(w * 0.195, h * 0.535)
      ..cubicTo(w * 0.20, h * 0.51, w * 0.195, h * 0.48, w * 0.19, h * 0.45)
      ..cubicTo(w * 0.205, h * 0.43, w * 0.21, h * 0.41, w * 0.205, h * 0.385)
      ..cubicTo(w * 0.215, h * 0.365, w * 0.22, h * 0.345, w * 0.215, h * 0.32)
      ..cubicTo(w * 0.215, h * 0.29, w * 0.21, h * 0.26, w * 0.20, h * 0.235)
      ..cubicTo(w * 0.235, h * 0.225, w * 0.255, h * 0.215, w * 0.255, h * 0.20)
      ..close();

    leftLeg = Path()
      ..moveTo(w * 0.365, h * 0.472)
      ..cubicTo(w * 0.34, h * 0.50, w * 0.33, h * 0.53, w * 0.335, h * 0.565)
      ..cubicTo(w * 0.325, h * 0.61, w * 0.325, h * 0.66, w * 0.335, h * 0.705)
      ..cubicTo(w * 0.325, h * 0.735, w * 0.33, h * 0.765, w * 0.335, h * 0.79)
      ..cubicTo(w * 0.325, h * 0.835, w * 0.335, h * 0.885, w * 0.355, h * 0.955)
      ..lineTo(w * 0.415, h * 0.955)
      ..cubicTo(w * 0.425, h * 0.885, w * 0.42, h * 0.835, w * 0.415, h * 0.79)
      ..cubicTo(w * 0.425, h * 0.765, w * 0.425, h * 0.735, w * 0.415, h * 0.705)
      ..cubicTo(w * 0.435, h * 0.66, w * 0.435, h * 0.61, w * 0.42, h * 0.565)
      ..cubicTo(w * 0.435, h * 0.53, w * 0.45, h * 0.50, w * 0.485, h * 0.478)
      ..cubicTo(w * 0.45, h * 0.472, w * 0.40, h * 0.47, w * 0.365, h * 0.472)
      ..close();
  }

  late final Path head;
  late final Path neck;
  late final Path torso;
  late final Path leftArm;
  late final Path leftLeg;
}

/// Draws the anatomical silhouette plus every muscle region in
/// [activation], colored by intensity — shared by the read-only
/// [DetailedBodyDiagram] and the tappable `MuscleActivationEditor`.
class BodyDiagramPainter extends CustomPainter {
  BodyDiagramPainter({
    required this.front,
    required this.activation,
    required this.outline,
    required this.base,
    required this.accent,
    this.selected,
  });

  final bool front;
  final Map<MuscleGroup, double> activation;
  final MuscleGroup? selected;
  final Color outline;
  final Color base;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;
    final fillPaint = Paint()..color = base;

    final body = _Silhouette(w, h);
    canvas.drawPath(body.head, fillPaint);
    canvas.drawPath(body.head, outlinePaint);
    canvas.drawPath(body.neck, fillPaint);
    canvas.drawPath(body.neck, outlinePaint);
    canvas.drawPath(body.torso, fillPaint);
    canvas.drawPath(body.torso, outlinePaint);

    for (final limb in [body.leftArm, body.leftLeg]) {
      canvas.drawPath(limb, fillPaint);
      canvas.drawPath(limb, outlinePaint);
    }
    canvas.save();
    canvas.translate(w, 0);
    canvas.scale(-1, 1);
    for (final limb in [body.leftArm, body.leftLeg]) {
      canvas.drawPath(limb, fillPaint);
      canvas.drawPath(limb, outlinePaint);
    }
    canvas.restore();

    final regions = bodyRegionsFor(front);
    for (final key in regions.keys) {
      final value = activation[key];
      final isSelected = selected == key;
      final color = value != null && value > 0
          ? Color.lerp(accent.withValues(alpha: 0.3), accent, (value / 100).clamp(0.0, 1.0))!
          : outline.withValues(alpha: 0.10);
      final shapes = muscleShapeFor(key, front, w, h);
      for (final shape in shapes) {
        canvas.drawPath(shape, Paint()..color = color);
        canvas.drawPath(
          shape,
          Paint()
            ..color = isSelected ? accent : outline.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * (isSelected ? 0.012 : 0.006),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BodyDiagramPainter old) {
    return old.front != front ||
        old.activation != activation ||
        old.selected != selected ||
        old.outline != outline ||
        old.base != base ||
        old.accent != accent;
  }
}

/// Read-only front/back-toggleable body diagram + a text legend of every
/// involved muscle sorted by intensity — used to show exactly which
/// muscles an exercise trains and how much, for every exercise in the
/// shared database (not just the 7 broad categories).
class DetailedBodyDiagram extends StatefulWidget {
  const DetailedBodyDiagram({super.key, required this.activation, this.size = 200});

  /// [MuscleGroup] -> 0-100 intensity.
  final Map<MuscleGroup, double> activation;
  final double size;

  @override
  State<DetailedBodyDiagram> createState() => _DetailedBodyDiagramState();
}

class _DetailedBodyDiagramState extends State<DetailedBodyDiagram> {
  late bool _front;

  @override
  void initState() {
    super.initState();
    _front = _totalFor(true) >= _totalFor(false);
  }

  double _totalFor(bool front) {
    var sum = 0.0;
    for (final m in front ? kFrontMuscles : kBackMuscles) {
      sum += widget.activation[m] ?? 0;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final sorted = widget.activation.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_totalFor(true) > 0 && _totalFor(false) > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(t.actionFront)),
                ButtonSegment(value: false, label: Text(t.actionBack)),
              ],
              selected: {_front},
              onSelectionChanged: (s) => setState(() => _front = s.first),
            ),
          ),
        SizedBox(
          width: widget.size,
          height: widget.size / 0.55,
          child: CustomPaint(
            painter: BodyDiagramPainter(
              front: _front,
              activation: widget.activation,
              outline: colors.line,
              base: colors.card2,
              accent: colors.accent,
            ),
          ),
        ),
        if (sorted.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final entry in sorted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.card2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${muscleGroupLabel(t, entry.key)} · ${entry.value.round()}%',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colors.txt),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
