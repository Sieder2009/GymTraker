import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../models/big_lift.dart';
import '../state/big_lifts_provider.dart';
import '../state/programs_provider.dart';
import '../state/train_state_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/strength_line_chart.dart';

// Anchored at `^` so grip/stance variants like "Bankdrücken (eng)" match
// while accessory lifts merely containing the word (e.g. "Hack Squat") do
// not — ported 1:1 from Progress.svelte's BIG_THREE / LIFT_CATEGORIES.
final RegExp _bigThree = RegExp(
  r'^(bench\s*press|bankdrücken|deadlift|kreuzheben|squats?)\b',
  caseSensitive: false,
);

class _LiftCategory {
  const _LiftCategory(this.key, this.label, this.pattern);
  final String key; // matches BigLifts.byKey()
  final String label;
  final RegExp pattern;
}

final List<_LiftCategory> _liftCategories = [
  _LiftCategory('deadlift', 'Deadlift', RegExp(r'^(deadlift|kreuzheben)\b', caseSensitive: false)),
  _LiftCategory(
      'bench', 'Bench Press', RegExp(r'^(bench\s*press|bankdrücken)\b', caseSensitive: false)),
  _LiftCategory('squat', 'Squat', RegExp(r'^squats?\b', caseSensitive: false)),
];

_LiftCategory? _categoryForName(String name) {
  for (final cat in _liftCategories) {
    if (cat.pattern.hasMatch(name)) return cat;
  }
  return null;
}

/// Buckets [history] into ISO-ish weeks (Monday start) and keeps the max
/// value logged in each week, chronologically — the data behind the
/// "wöchentlicher Fortschritt" chart. Points without a date (shouldn't
/// happen for anything logged going forward) are skipped.
List<double> _weeklyMaxValues(List<BigLiftPoint> history) {
  final byWeek = <DateTime, double>{};
  for (final p in history) {
    final dateStr = p.date;
    if (dateStr == null) continue;
    DateTime d;
    try {
      d = DateTime.parse(dateStr);
    } catch (_) {
      continue;
    }
    final weekStart =
        DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
    final existing = byWeek[weekStart];
    if (existing == null || p.v > existing) {
      byWeek[weekStart] = p.v;
    }
  }
  final sortedWeeks = byWeek.keys.toList()..sort();
  return [for (final w in sortedWeeks) byWeek[w]!];
}

class _ProgressRow {
  _ProgressRow({required this.name, required this.start, required this.now, required this.delta});
  final String name;
  final double start;
  final double now;
  final double delta;
}

/// "Fortschritt" tab — wöchentlicher PR-Fortschritt (Deadlift/Bench/Squat)
/// + Start→Jetzt-Liste (tippbar, um direkt einen PR einzutragen), berechnet
/// über JEDE Übung im aktiven Plan (nicht nur den angezeigten Tag).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  Future<void> _openPrDialog(
    BuildContext context,
    String liftKey,
    String liftLabel,
    double currentPr,
  ) async {
    final controller = TextEditingController(text: currentPr > 0 ? fmt(currentPr) : '');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$liftLabel-PR eintragen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              Navigator.of(ctx).pop(v);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (result != null && result > 0 && context.mounted) {
      context.read<BigLiftsProvider>().savePr(liftKey, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final programsProvider = context.watch<ProgramsProvider>();
    final trainState = context.watch<TrainStateProvider>();
    final bigLifts = context.watch<BigLiftsProvider>().lifts;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wöchentlicher Fortschritt', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Höchster PR-Eintrag pro Woche für Deadlift, Bench Press und Squat.',
                    style: TextStyle(color: colors.mut, fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  _WeeklyLiftRow(
                    label: 'Deadlift',
                    color: colors.purple,
                    points: _weeklyMaxValues(bigLifts.deadlift.history),
                    pr: bigLifts.deadlift.pr,
                  ),
                  const SizedBox(height: 18),
                  _WeeklyLiftRow(
                    label: 'Bench Press',
                    color: colors.teal,
                    points: _weeklyMaxValues(bigLifts.bench.history),
                    pr: bigLifts.bench.pr,
                  ),
                  const SizedBox(height: 18),
                  _WeeklyLiftRow(
                    label: 'Squat',
                    color: colors.yellow,
                    points: _weeklyMaxValues(bigLifts.squat.history),
                    pr: bigLifts.squat.pr,
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final cat = _categoryForName(row.name);
                    if (cat == null) return;
                    _openPrDialog(context, cat.key, cat.label, bigLifts.byKey(cat.key).pr);
                  },
                  child: ListTile(
                    title: Text(row.name),
                    subtitle: Text('${fmt1(row.start)} kg → ${fmt1(row.now)} kg'),
                    trailing: row.delta == 0 ? null : _DeltaBadge(delta: row.delta, colors: colors),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _WeeklyLiftRow extends StatelessWidget {
  const _WeeklyLiftRow({
    required this.label,
    required this.color,
    required this.points,
    required this.pr,
  });

  final String label;
  final Color color;
  final List<double> points;
  final double pr;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        if (points.length < 2)
          Text(
            'Noch nicht genug wöchentliche Einträge (mind. 2 Wochen nötig).',
            style: TextStyle(color: colors.mut, fontSize: 12),
          )
        else
          StrengthLineChart(points: points, pr: pr, color: color, lineColor: colors.line),
      ],
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
