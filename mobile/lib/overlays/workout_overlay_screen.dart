import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../models/exercise.dart';
import '../state/programs_provider.dart';
import '../state/toast_provider.dart';
import '../theme/app_colors.dart';
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

  ProgramsProvider get _programs => context.read<ProgramsProvider>();

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

    final currentSets = exercises[_exIdx].sets.length;
    final isLastSetOfExercise = _setIdx >= currentSets - 1;
    final isLastExercise = _exIdx >= exercises.length - 1;

    if (isLastSetOfExercise && isLastExercise) {
      final plan = _programs.byId(widget.programId)!;
      _programs.finishWorkout(plan);
      context.read<ToastProvider>().show('Workout abgeschlossen 💪');
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

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: _resting ? _buildRestView(colors) : _buildMainView(exercises, colors),
      ),
    );
  }

  Widget _buildMainView(List<Exercise> exercises, AppColors colors) {
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
                  borderRadius: BorderRadius.circular(4),
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
            'Übung ${_exIdx + 1}/${exercises.length} · Satz ${_setIdx + 1}/${sets.length}',
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
                  weight > 0 ? '${fmt1(weight)} kg' : 'BW',
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
            child: Text('Ziel: $targetReps Wdh.', style: TextStyle(color: colors.mut)),
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
          Text('RPE', style: TextStyle(color: colors.mut), textAlign: TextAlign.center),
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
            child: Text(isLast ? 'Workout beenden' : 'Satz abschließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildRestView(AppColors colors) {
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
          Text('Sekunden Pause', style: TextStyle(color: colors.mut)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              final plan = context.read<ProgramsProvider>().byId(widget.programId)!;
              _advance(plan.days[widget.dayIdx].exercises);
            },
            child: const Text('Überspringen →'),
          ),
        ],
      ),
    );
  }
}
