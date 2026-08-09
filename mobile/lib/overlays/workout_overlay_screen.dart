import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../l10n/app_localizations.dart';
import '../models/exercise.dart';
import '../state/health_provider.dart';
import '../state/programs_provider.dart';
import '../state/toast_provider.dart';
import '../state/workout_history_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../widgets/rest_ring.dart';

String _formatElapsed(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}

/// Guided, sequential set-by-set workout session, ported from
/// `WorkoutOverlay.svelte` and since extended with a live session clock,
/// a wall-clock rest timer, and mid-session exercise reordering.
///
/// Weight adjustments persist immediately via [ProgramsProvider] even if
/// the screen is force-closed mid-rest — the [_ticker] is cancelled in
/// [dispose], which `Navigator.pop` reliably triggers.
///
/// Both the elapsed-session clock and the rest countdown are computed from
/// wall-clock [DateTime] timestamps rather than a decrementing tick
/// counter, and re-synced on [AppLifecycleState.resumed] -- a plain
/// `Timer.periodic` only fires while the app is actually running, so
/// counting down "one tick per callback" would silently freeze (or worse,
/// undercount) the whole time the phone was locked or the app was
/// backgrounded mid-rest, which is exactly when people actually background
/// this screen. Recomputing from timestamps on every tick and on resume
/// means the displayed numbers are always correct regardless of how long
/// the app was away.
class WorkoutOverlayScreen extends StatefulWidget {
  const WorkoutOverlayScreen(
      {super.key, required this.programId, required this.dayIdx});

  final String programId;
  final int dayIdx;

  @override
  State<WorkoutOverlayScreen> createState() => _WorkoutOverlayScreenState();
}

class _WorkoutOverlayScreenState extends State<WorkoutOverlayScreen>
    with WidgetsBindingObserver {
  int _exIdx = 0;
  int _setIdx = 0;
  DateTime? _restEndsAt;
  int _restTotal = 0;
  int? _rpe;
  Timer? _ticker;
  final DateTime _startedAt = DateTime.now();
  double _sessionVolumeKg = 0;
  int _sessionSets = 0;

  /// Session-local exercise order (indices into the plan day's exercise
  /// list) -- reordering here only changes what order *this* workout walks
  /// through, it never touches the saved plan template.
  late List<int> _order;

  bool get _resting => _restEndsAt != null;

  ProgramsProvider get _programs => context.read<ProgramsProvider>();

  List<Exercise> _rawExercises() {
    final plan = _programs.byId(widget.programId)!;
    return plan.days[widget.dayIdx].exercises;
  }

  List<Exercise> _ordered(List<Exercise> raw) =>
      [for (final i in _order) raw[i]];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _order = List.generate(_rawExercises().length, (i) => i);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onTick();
  }

  void _onTick() {
    if (!mounted) return;
    final restEndsAt = _restEndsAt;
    if (restEndsAt != null && !DateTime.now().isBefore(restEndsAt)) {
      _advance(_ordered(_rawExercises()));
      return;
    }
    setState(
        () {}); // just re-render the live clock / rest ring off DateTime.now()
  }

  /// Best-effort numeric rep count from a target-reps string like "8" or a
  /// range like "8-10" (averaged) — used only to estimate session volume,
  /// since the guided workout doesn't collect actual reps performed.
  static double _repsForVolume(String r) {
    final numbers = RegExp(r'\d+(?:[.,]\d+)?')
        .allMatches(r)
        .map((m) => double.parse(m.group(0)!.replaceAll(',', '.')))
        .toList();
    if (numbers.isEmpty) return 0;
    return numbers.reduce((a, b) => a + b) / numbers.length;
  }

  int _totalSets(List<Exercise> exercises) {
    var total = 0;
    for (final e in exercises) {
      total += e.sets.length;
    }
    return total < 1 ? 1 : total;
  }

  int _doneBefore(List<Exercise> exercises) {
    var done = 0;
    for (var i = 0; i < _exIdx; i++) {
      done += exercises[i].sets.length;
    }
    return done + _setIdx;
  }

  void _step(List<Exercise> exercises, double delta) {
    _programs.adjustWeight(exercises, _exIdx, _setIdx, delta);
  }

  void _completeSet(List<Exercise> exercises) {
    _programs.toggleSet(exercises, _exIdx, _setIdx);

    final set = exercises[_exIdx].sets[_setIdx];
    _sessionVolumeKg += set.w * _repsForVolume(set.r);
    _sessionSets += 1;

    final currentSets = exercises[_exIdx].sets.length;
    final isLastSetOfExercise = _setIdx >= currentSets - 1;
    final isLastExercise = _exIdx >= exercises.length - 1;

    if (isLastSetOfExercise && isLastExercise) {
      final plan = _programs.byId(widget.programId)!;
      _programs.finishWorkout(plan);
      final minutes = DateTime.now().difference(_startedAt).inMinutes;
      context.read<WorkoutHistoryProvider>().logSession(
            date: todayIso(),
            durationMinutes: minutes < 1 ? 1 : minutes,
            planName: plan.name,
            totalVolumeKg: _sessionVolumeKg,
            totalSets: _sessionSets,
          );
      // Best-effort, never blocks finishing the workout — Health Connect/
      // HealthKit access can fail for reasons entirely outside the app's
      // control (not connected, permission revoked, ...).
      unawaited(context.read<HealthProvider>().writeWorkout(
            start: _startedAt,
            end: DateTime.now(),
            title: plan.name,
          ));
      context
          .read<ToastProvider>()
          .show(AppLocalizations.of(context)!.toastWorkoutFinished);
      Navigator.of(context).pop();
      return;
    }

    final restSeconds = exercises[_exIdx].rest;
    setState(() {
      _restTotal = restSeconds;
      _restEndsAt = DateTime.now().add(Duration(seconds: restSeconds));
      _rpe = null;
    });
  }

  void _advance(List<Exercise> exercises) {
    final currentSets = exercises[_exIdx].sets.length;
    setState(() {
      _restEndsAt = null;
      _rpe = null;
      if (_setIdx < currentSets - 1) {
        _setIdx += 1;
      } else {
        _exIdx += 1;
        _setIdx = 0;
      }
    });
  }

  Future<void> _openReorderSheet() async {
    // Only the exercises still ahead of the current one are reorderable —
    // rearranging ones already done (or the one mid-set right now) would
    // desync the visible "done" dots from what's actually logged.
    final upcoming = _order.sublist(_exIdx + 1);
    if (upcoming.isEmpty) return;
    final reordered = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ReorderSheet(
        upcomingIndices: upcoming,
        exerciseName: (i) => _rawExercises()[i].name,
      ),
    );
    if (reordered != null) {
      setState(() => _order.replaceRange(_exIdx + 1, _order.length, reordered));
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<ProgramsProvider>().byId(widget.programId)!;
    final exercises = _ordered(plan.days[widget.dayIdx].exercises);
    final colors = Theme.of(context).extension<AppColors>()!;

    if (_exIdx >= exercises.length) {
      // finish already pops before this can render; guard defensively.
      return const SizedBox.shrink();
    }

    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: _resting
            ? _buildRestView(colors, t)
            : _buildMainView(exercises, colors, t),
      ),
    );
  }

  Widget _buildMainView(
      List<Exercise> exercises, AppColors colors, AppLocalizations t) {
    final ex = exercises[_exIdx];
    final sets = ex.sets;
    final weight = sets[_setIdx].w;
    final targetReps = sets[_setIdx].r;
    final isLast = _exIdx == exercises.length - 1 && _setIdx == sets.length - 1;
    final progress = _doneBefore(exercises) / _totalSets(exercises);
    final hasUpcoming = _exIdx < exercises.length - 1;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop()),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0, 1).toDouble(),
                    backgroundColor: colors.card2,
                    color: colors.accent,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert),
                tooltip: t.actionReorderExercises,
                onPressed: hasUpcoming ? _openReorderSheet : null,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 14, color: colors.mut),
                const SizedBox(width: 4),
                Text(
                  _formatElapsed(DateTime.now().difference(_startedAt)),
                  style: TextStyle(
                    color: colors.mut,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ex.name,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            t.exerciseSetProgress(
                _exIdx + 1, exercises.length, _setIdx + 1, sets.length),
            style: TextStyle(color: colors.mut),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
                onPressed: () => _step(exercises, -2.5),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  weight > 0 ? '${fmt1(weight)} kg' : t.labelBodyweightAbbr,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
                onPressed: () => _step(exercises, 2.5),
              ),
            ],
          ),
          Center(
            child: Text(t.targetReps(targetReps),
                style: TextStyle(color: colors.mut)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < sets.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        ex.done.contains(i) ? colors.green : Colors.transparent,
                    border: Border.all(
                        color: i == _setIdx ? colors.accent : colors.line),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t.headerRpe,
              style: TextStyle(color: colors.mut), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              for (var v = 5; v <= 10; v++)
                ChoiceChip(
                  label: Text('$v'),
                  selected: _rpe == v,
                  onSelected: (_) => setState(() => _rpe = v),
                ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _completeSet(exercises),
            child: Text(isLast ? t.actionFinishWorkout : t.actionCompleteSet),
          ),
        ],
      ),
    );
  }

  Widget _buildRestView(AppColors colors, AppLocalizations t) {
    final restEndsAt = _restEndsAt!;
    final restLeft =
        restEndsAt.difference(DateTime.now()).inSeconds.clamp(0, _restTotal);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RestRing(
            progress: _restTotal == 0 ? 0 : restLeft / _restTotal,
            trackColor: colors.card2,
            progressColor: colors.accent,
            child: Text('$restLeft',
                style: Theme.of(context).textTheme.headlineLarge),
          ),
          const SizedBox(height: 16),
          Text(t.secondsPause, style: TextStyle(color: colors.mut)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => _advance(_ordered(_rawExercises())),
            child: Text(t.actionSkipRest),
          ),
        ],
      ),
    );
  }
}

/// Drag-to-reorder sheet for the exercises still ahead in this session.
/// Purely session-local — the caller applies the result to [_order], never
/// to the saved plan.
class _ReorderSheet extends StatefulWidget {
  const _ReorderSheet(
      {required this.upcomingIndices, required this.exerciseName});

  final List<int> upcomingIndices;
  final String Function(int planIndex) exerciseName;

  @override
  State<_ReorderSheet> createState() => _ReorderSheetState();
}

class _ReorderSheetState extends State<_ReorderSheet> {
  late final List<int> _local;

  @override
  void initState() {
    super.initState();
    _local = List.of(widget.upcomingIndices);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.titleReorderExercises,
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text(t.hintReorderExercises,
                            style:
                                TextStyle(color: colors.mut, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_local),
                    child: Text(t.actionSave),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                itemCount: _local.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _local.removeAt(oldIndex);
                    _local.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, i) {
                  final planIdx = _local[i];
                  return ListTile(
                    key: ValueKey(planIdx),
                    leading:
                        Text('${i + 1}', style: TextStyle(color: colors.mut)),
                    title: Text(widget.exerciseName(planIdx)),
                    trailing: const Icon(Icons.drag_handle),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
