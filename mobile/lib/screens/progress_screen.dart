import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../state/programs_provider.dart';
import '../state/train_state_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/radar_chart.dart';

// Anchored at `^` so grip/stance variants like "Bankdrücken (eng)" match
// while accessory lifts merely containing the word (e.g. "Hack Squat") do
// not — ported 1:1 from Progress.svelte's BIG_THREE / LIFT_CATEGORIES.
final RegExp _bigThree = RegExp(
  r'^(bench\s*press|bankdrücken|deadlift|kreuzheben|squats?)\b',
  caseSensitive: false,
);

class _LiftCategory {
  const _LiftCategory(this.label, this.pattern);
  final String label;
  final RegExp pattern;
}

final List<_LiftCategory> _liftCategories = [
  _LiftCategory('Deadlift', RegExp(r'^(deadlift|kreuzheben)\b', caseSensitive: false)),
  _LiftCategory('Bench Press', RegExp(r'^(bench\s*press|bankdrücken)\b', caseSensitive: false)),
  _LiftCategory('Squat', RegExp(r'^squats?\b', caseSensitive: false)),
];

class _ProgressRow {
  _ProgressRow({required this.name, required this.start, required this.now, required this.delta});
  final String name;
  final double start;
  final double now;
  final double delta;
}

/// "Fortschritt" tab — Start→Jetzt list + Kraft-Balance radar, computed
/// over EVERY exercise in the active plan (not just the viewed day).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final programsProvider = context.watch<ProgramsProvider>();
    final trainState = context.watch<TrainStateProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final programs = programsProvider.programs;

    if (programs.isEmpty) {
      return SafeArea(
        child: Center(
          child: Text('Noch kein Trainingsplan.', style: TextStyle(color: colors.mut)),
        ),
      );
    }

    final plan = programsProvider.byId(trainState.activePlanId) ?? programs.first;
    final allEx = [
      ...plan.dailyExercises,
      for (final d in plan.days) ...d.exercises,
    ];

    final rows = <_ProgressRow>[];
    for (final ex in allEx) {
      if (!_bigThree.hasMatch(ex.name)) continue;
      var now = 0.0;
      for (final s in ex.sets) {
        if (s.w > now) now = s.w;
      }
      if (now <= 0) continue;
      final delta = ((now - ex.startW) * 10).round() / 10;
      rows.add(_ProgressRow(name: ex.name, start: ex.startW, now: now, delta: delta));
    }

    final catSums = _liftCategories.map((cat) {
      var best = 0.0;
      for (final ex in allEx) {
        if (!cat.pattern.hasMatch(ex.name)) continue;
        var now = 0.0;
        for (final s in ex.sets) {
          if (s.w > now) now = s.w;
        }
        if (now > best) best = now;
      }
      return best;
    }).toList();
    final maxCat = catSums.fold<double>(1, (m, v) => v > m ? v : m);
    final radarValues = catSums.map((v) => v / maxCat * 100).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Text('Fortschritt', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Kraft-Balance', style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 12),
                  RadarChart(
                    labels: _liftCategories.map((c) => c.label).toList(),
                    values: radarValues,
                    lineColor: colors.line,
                    accentColor: colors.accent,
                    mutedColor: colors.mut,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Deadlift, Bench Press und Squat, bezogen auf deine stärkste der drei '
                    'Übungen im aktuellen Plan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.mut, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('START → JETZT', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Noch keine Übungen mit Gewicht erfasst.',
                style: TextStyle(color: colors.mut),
              ),
            )
          else
            for (final row in rows)
              Card(
                child: ListTile(
                  title: Text(row.name),
                  subtitle: Text('${fmt1(row.start)} kg → ${fmt1(row.now)} kg'),
                  trailing: row.delta == 0 ? null : _DeltaBadge(delta: row.delta, colors: colors),
                ),
              ),
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta, required this.colors});

  final double delta;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final positive = delta > 0;
    final color = positive ? colors.green : colors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${positive ? '+' : ''}${fmt1(delta)} kg',
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
