import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../analytics/analytics_engine.dart';
import '../data/constants.dart';
import '../l10n/app_localizations.dart';
import '../models/big_lift.dart';
import '../state/big_lifts_provider.dart';
import '../state/body_weight_provider.dart';
import '../state/programs_provider.dart';
import '../state/train_state_provider.dart';
import '../state/workout_history_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../widgets/app_shell.dart';
import '../widgets/chart_card.dart';
import '../widgets/plateau_notice.dart';
import '../widgets/trend_value.dart';

// Anchored at `^` so grip/stance variants like "Bankdrücken (eng)" match
// while accessory lifts merely containing the word (e.g. "Hack Squat") do
// not — ported 1:1 from Progress.svelte's BIG_THREE / LIFT_CATEGORIES.
final RegExp _bigThree = RegExp(
  r'^(bench\s*press|bankdrücken|deadlift|kreuzheben|squats?)\b',
  caseSensitive: false,
);

class _LiftCategory {
  const _LiftCategory(this.key, this.pattern);
  final String key; // matches BigLifts.byKey()
  final RegExp pattern;
}

final List<_LiftCategory> _liftCategories = [
  _LiftCategory('deadlift', RegExp(r'^(deadlift|kreuzheben)\b', caseSensitive: false)),
  _LiftCategory('bench', RegExp(r'^(bench\s*press|bankdrücken)\b', caseSensitive: false)),
  _LiftCategory('squat', RegExp(r'^squats?\b', caseSensitive: false)),
];

_LiftCategory? _categoryForName(String name) {
  for (final cat in _liftCategories) {
    if (cat.pattern.hasMatch(name)) return cat;
  }
  return null;
}

class _ProgressRow {
  _ProgressRow({required this.name, required this.start, required this.now, required this.delta});
  final String name;
  final double start;
  final double now;
  final double delta;
}

/// "Fortschritt"/Analytics tab — its own dedicated multi-section area
/// (Overview / Strength / Volume / Consistency), every number and chart
/// traced back to real logged data. Nothing here is guessed: charts show
/// an honest empty state instead of a flat line when there isn't enough
/// data yet (see analytics_engine.dart's [DataQuality]).
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final programsProvider = context.watch<ProgramsProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final programs = programsProvider.programs;
    final t = AppLocalizations.of(context)!;

    if (programs.isEmpty) {
      return SafeArea(
        child: Center(
          child: Text(t.emptyNoPlanShort, style: TextStyle(color: colors.mut)),
        ),
      );
    }

    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(t.tabProgress, style: Theme.of(context).textTheme.headlineLarge),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: colors.accent,
              unselectedLabelColor: colors.mut,
              indicatorColor: colors.accent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(text: t.tabAnalyticsOverview),
                Tab(text: t.tabAnalyticsStrength),
                Tab(text: t.tabAnalyticsVolume),
                Tab(text: t.tabAnalyticsConsistency),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(),
                  _StrengthTab(),
                  const _VolumeTab(),
                  const _ConsistencyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "central feature" summary — a plain-language read on how training
/// is going, plus a rolling weekly-volume chart for an at-a-glance trend
/// (see DESIGN.md §101.30).
class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final sessions = context.watch<WorkoutHistoryProvider>().sessions;

    final buckets = weeklyBuckets(sessions);
    final volumePoints = [
      for (final b in buckets) ChartPoint(b.weekStart, b.totalVolumeKg),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kFloatingNavClearance),
      children: [
        const _YourProgressCard(),
        const SizedBox(height: 16),
        LineChartCard(
          title: t.chartTitleWeeklyVolume,
          subtitle: t.labelLast8Weeks,
          points: volumePoints,
          emptyLabel: t.chartEmptyVolume,
          valueSuffix: ' kg',
          color: colors.teal,
        ),
      ],
    );
  }
}

/// Per-lift trend charts + Start→Now deltas (tap a row to enter that lift's
/// PR directly), generalized via [computeLiftTrend]/[liftHistoryPoints] so
/// this isn't special-cased to just showing PR numbers.
class _StrengthTab extends StatelessWidget {
  Future<void> _openPrDialog(
    BuildContext context,
    AppLocalizations t,
    String liftKey,
    String liftLabel,
    double currentPr,
  ) async {
    final controller = TextEditingController(text: currentPr > 0 ? fmt(currentPr) : '');
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.titleEnterLiftPr(liftLabel)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.actionCancel)),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(controller.text.replaceAll(',', '.'));
              Navigator.of(ctx).pop(v);
            },
            child: Text(t.actionSave),
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
    final lifts = context.watch<BigLiftsProvider>().lifts;
    final colors = Theme.of(context).extension<AppColors>()!;
    final t = AppLocalizations.of(context)!;
    final liftKeys = ['deadlift', 'bench', 'squat'];
    final liftLabelByKey = {'deadlift': t.labelDeadlift, 'bench': t.labelBenchPress, 'squat': t.labelSquat};

    final plan = programsProvider.byId(trainState.activePlanId) ?? programsProvider.programs.first;
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kFloatingNavClearance),
      children: [
        for (final key in liftKeys) ...[
          _LiftTrendCard(lift: lifts.byKey(key), label: liftLabelByKey[key]!),
          const SizedBox(height: 16),
        ],
        Text(t.labelStartToNow, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(t.emptyNoWeightedExercises, style: TextStyle(color: colors.mut)),
          )
        else
          for (final row in rows)
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                onTap: () {
                  final cat = _categoryForName(row.name);
                  if (cat == null) return;
                  _openPrDialog(context, t, cat.key, liftLabelByKey[cat.key]!, lifts.byKey(cat.key).pr);
                },
                child: ListTile(
                  title: Text(row.name),
                  subtitle: Text(t.weightRange(fmt1(row.start), fmt1(row.now))),
                  trailing: row.delta == 0 ? null : _DeltaBadge(delta: row.delta, colors: colors),
                ),
              ),
            ),
      ],
    );
  }
}

class _LiftTrendCard extends StatelessWidget {
  const _LiftTrendCard({required this.lift, required this.label});

  final BigLift lift;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final trend = computeLiftTrend(lift);
    final plateaued = isLiftPlateaued(lift);
    final points = [
      for (final p in liftHistoryPoints(lift)) ChartPoint(p.key, p.value),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LineChartCard(
          title: label,
          subtitle: t.labelTrend30Days,
          points: points,
          emptyLabel: t.chartEmptyExercise,
          valueSuffix: ' kg',
          color: colors.accent,
          height: 150,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TrendValue(stat: trend, formatDelta: (d) => '${d.toStringAsFixed(1)}%'),
        ),
        if (plateaued == true) ...[
          const SizedBox(height: 8),
          PlateauNotice(label: label),
        ],
      ],
    );
  }
}

/// Weekly training volume — total kg logged per rolling 7-day window,
/// backed by [WorkoutHistoryProvider] sessions.
class _VolumeTab extends StatelessWidget {
  const _VolumeTab();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final sessions = context.watch<WorkoutHistoryProvider>().sessions;
    final week = computeWeekSummary(sessions);
    final buckets = weeklyBuckets(sessions);
    final bars = [
      for (final b in buckets) BarPoint('${b.weekStart.day}.${b.weekStart.month}', b.totalVolumeKg),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kFloatingNavClearance),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: t.labelThisWeek,
                value: '${fmt1(week.totalVolumeKg)} kg',
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: t.labelWorkouts,
                value: '${week.workoutCount}',
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BarChartCard(
          title: t.chartTitleWeeklyVolume,
          subtitle: t.labelLast8Weeks,
          bars: bars,
          emptyLabel: t.chartEmptyVolume,
          color: colors.teal,
        ),
      ],
    );
  }
}

/// Streaks + workouts-per-week, backed by [computeConsistency] /
/// [weeklyBuckets] — never a fabricated streak when there's no logged
/// history to compute one from.
class _ConsistencyTab extends StatelessWidget {
  const _ConsistencyTab();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final sessions = context.watch<WorkoutHistoryProvider>().sessions;
    final consistency = computeConsistency(sessions);
    final buckets = weeklyBuckets(sessions);
    final bars = [
      for (final b in buckets) BarPoint('${b.weekStart.day}.${b.weekStart.month}', b.workoutCount.toDouble()),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kFloatingNavClearance),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: t.labelCurrentStreak,
                value: t.unitDays(consistency.currentStreakDays),
                colors: colors,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: t.labelBestStreak,
                value: t.unitDays(consistency.bestStreakDays),
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatTile(label: t.labelWorkoutsThisMonth, value: '${consistency.workoutsThisMonth}', colors: colors, fullWidth: true),
        const SizedBox(height: 16),
        BarChartCard(
          title: t.chartTitleWorkoutsPerWeek,
          subtitle: t.labelLast8Weeks,
          bars: bars,
          emptyLabel: t.chartEmptyConsistency,
          color: colors.purple,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.colors, this.fullWidth = false});

  final String label;
  final String value;
  final AppColors colors;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: colors.mut, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: colors.txt)),
          ],
        ),
      ),
    );
  }
}

class _YourProgressCard extends StatelessWidget {
  const _YourProgressCard();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;

    final sessions = context.watch<WorkoutHistoryProvider>().sessions;
    final lifts = context.watch<BigLiftsProvider>().lifts;
    final bodyWeight = context.watch<BodyWeightProvider>().entries;

    final week = computeWeekSummary(sessions);
    final consistency = computeConsistency(sessions);
    final strengthTrend = bestLiftImprovement(
      lifts,
      labels: {'bench': t.labelBenchPress, 'deadlift': t.labelDeadlift, 'squat': t.labelSquat},
    );
    final recentPrs = countRecentLiftPrs(lifts);
    final bodyWeightTrend = computeBodyWeightTrend(bodyWeight);

    final message = strengthTrend != null && strengthTrend.changePercent > 0
        ? t.progressMessageImproving
        : week.workoutCount > 0
            ? t.progressMessageSteady
            : t.progressMessageNoData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.titleYourProgress, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(message, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _ProgressStatRow(
              label: t.labelStrength,
              child: strengthTrend != null
                  ? TrendValue(
                      stat: TrendStat(delta: strengthTrend.changePercent, quality: DataQuality.good, sampleCount: 2),
                      formatDelta: (d) => '${d.toStringAsFixed(1)}%',
                    )
                  : Text(t.insufficientDataShort, style: TextStyle(color: colors.mut, fontSize: 12.5)),
            ),
            _ProgressStatRow(
              label: t.labelVolume,
              child: TrendValue(
                stat: TrendStat(
                  delta: week.volumeChangePercent,
                  quality: week.quality,
                  sampleCount: week.workoutCount,
                ),
                formatDelta: (d) => '${d.toStringAsFixed(1)}%',
              ),
            ),
            _ProgressStatRow(
              label: t.labelConsistency,
              child: Text(
                t.unitDays(consistency.currentStreakDays),
                style: TextStyle(fontWeight: FontWeight.w700, color: colors.txt),
              ),
            ),
            _ProgressStatRow(
              label: t.labelPRs,
              child: Text('$recentPrs', style: TextStyle(fontWeight: FontWeight.w700, color: colors.txt)),
            ),
            _ProgressStatRow(
              label: t.labelBodyweightTitle,
              child: TrendValue(
                stat: bodyWeightTrend,
                formatDelta: (d) => '${fmt1(d)} kg',
              ),
            ),
            if (strengthTrend != null) ...[
              const Divider(height: 24),
              Text(t.labelBestImprovement, style: TextStyle(color: colors.mut, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(strengthTrend.label, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressStatRow extends StatelessWidget {
  const _ProgressStatRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colors.mut)),
          child,
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
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Text(
        '${positive ? '+' : ''}${fmt1(delta)} kg',
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
