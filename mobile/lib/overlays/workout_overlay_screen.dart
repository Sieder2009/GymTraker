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

/// Guided, sequential set-by-set workout session, ported from
/// `WorkoutOverlay.svelte`. Weight adjustments persist immediately via
/// [ProgramsProvider] even if the screen is force-closed mid-rest — the
/// [Timer] is cancelled in [dispose], which `Navigator.pop` reliably
/// triggers.
class WorkoutOverlayScreen extends StatefulWidget {
  const WorkoutOverlayScreen({super.key, required this.programId, required this.dayIdx});

  final String programId;
  final int dayIdx;

  @override
  State<WorkoutOverlayScreen> createState() => _WorkoutOverlayScreenState();
}

class _WorkoutOverlayScreenState extends State<WorkoutOverlayScreen> {
  int _exIdx = 0;
  int _setIdx = 0;
  bool _resting = false;
  int _restLeft = 0;
  int _restTotal = 0;
  int? _rpe;
  Timer? _timer;
  final DateTime _startedAt = DateTime.now();
  double _sessionVolumeKg = 0;
  int _sessionSets = 0;

  ProgramsProvider get _programs => context.read<ProgramsProvider>();

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
      context.read<ToastProvider>().show(AppLocalizations.of(context)!.toastWorkoutFinished);
      Navigator.of(context).pop();
      return;
    }

    final restSeconds = exercises[_exIdx].rest;
    setState(() {
      _restTotal = restSeconds;
      _restLeft = restSeconds;
      _resting = true;
      _rpe = null;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _restLeft -= 1);
      if (_restLeft <= 0) _advance(exercises);
    });
  }

  void _advance(List<Exercise> exercises) {
    _timer?.cancel();
    final currentSets = exercises[_exIdx].sets.length;
    setState(() {
      _resting = false;
      _rpe = null;
      if (_setIdx < currentSets - 1) {
        _setIdx += 1;
      } else {
        _exIdx += 1;
        _setIdx = 0;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<ProgramsProvider>().byId(widget.programId)!;
    final exercises = plan.days[widget.dayIdx].exercises;
    final colors = Theme.of(context).extension<AppColors>()!;

    if (_exIdx >= exercises.length) {
      // finish already pops before this can render; guard defensively.
      return const SizedBox.shrink();
    }

    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: _resting ? _buildRestView(colors, t) : _buildMainView(exercises, colors, t),
      ),
    );
  }

  Widget _buildMainView(List<Exercise> exercises, AppColors colors, AppLocalizations t) {
    final ex = exercises[_exIdx];
    final sets = ex.sets;
    final weight = sets[_setIdx].w;
    final targetReps = sets[_setIdx].r;
    final isLast = _exIdx == exercises.length - 1 && _setIdx == sets.length - 1;
    final progress = _doneBefore(exercises) / _totalSets(exercises);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
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
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            ex.name,
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            t.exerciseSetProgress(_exIdx + 1, exercises.length, _setIdx + 1, sets.length),
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
            child: Text(t.targetReps(targetReps), style: TextStyle(color: colors.mut)),
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
                    color: ex.done.contains(i) ? colors.green : Colors.transparent,
                    border: Border.all(color: i == _setIdx ? colors.accent : colors.line),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t.headerRpe, style: TextStyle(color: colors.mut), textAlign: TextAlign.center),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RestRing(
            progress: _restTotal == 0 ? 0 : _restLeft / _restTotal,
            trackColor: colors.card2,
            progressColor: colors.accent,
            child: Text('$_restLeft', style: Theme.of(context).textTheme.headlineLarge),
          ),
          const SizedBox(height: 16),
          Text(t.secondsPause, style: TextStyle(color: colors.mut)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              final plan = context.read<ProgramsProvider>().byId(widget.programId)!;
              _advance(plan.days[widget.dayIdx].exercises);
            },
            child: Text(t.actionSkipRest),
          ),
        ],
      ),
    );
  }
}
