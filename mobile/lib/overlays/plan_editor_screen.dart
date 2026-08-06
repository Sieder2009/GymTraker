import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../models/day.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/program.dart';
import '../state/programs_provider.dart';
import '../state/toast_provider.dart';
import '../state/train_state_provider.dart';

class _DraftExercise {
  _DraftExercise()
      : name = TextEditingController(),
        sets = TextEditingController(text: '3'),
        reps = TextEditingController(text: '8'),
        weight = TextEditingController(text: '0');

  final TextEditingController name;
  final TextEditingController sets;
  final TextEditingController reps;
  final TextEditingController weight;

  void dispose() {
    name.dispose();
    sets.dispose();
    reps.dispose();
    weight.dispose();
  }
}

class _DraftDay {
  _DraftDay({required this.label, this.rest = false, List<_DraftExercise>? exercises})
      : labelController = TextEditingController(text: label),
        exercises = exercises ?? [];

  final String label;
  final TextEditingController labelController;
  bool rest;
  List<_DraftExercise> exercises;

  void dispose() {
    labelController.dispose();
    for (final e in exercises) {
      e.dispose();
    }
  }
}

/// "+ Neuer Plan" — full-screen plan builder, ported from `PlanEditor.svelte`.
/// Switching weekday/rotation mode discards whatever was entered and resets
/// to a fresh skeleton, matching the original.
class PlanEditorScreen extends StatefulWidget {
  const PlanEditorScreen({super.key});

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _mode = 'weekday';
  late List<_DraftDay> _days;

  @override
  void initState() {
    super.initState();
    _days = _weekdaySkeleton();
  }

  List<_DraftDay> _weekdaySkeleton() =>
      kWeekdays.map((label) => _DraftDay(label: label)).toList();

  List<_DraftDay> _rotationSkeleton() =>
      List.generate(3, (i) => _DraftDay(label: 'Tag ${i + 1}'));

  void _setMode(String mode) {
    if (mode == _mode) return;
    for (final d in _days) {
      d.dispose();
    }
    setState(() {
      _mode = mode;
      _days = mode == 'weekday' ? _weekdaySkeleton() : _rotationSkeleton();
    });
  }

  void _addRotationDay() {
    setState(() => _days.add(_DraftDay(label: 'Tag ${_days.length + 1}')));
  }

  void _removeDay(int i) {
    setState(() {
      _days[i].dispose();
      _days.removeAt(i);
    });
  }

  void _addExercise(int dayIdx) {
    setState(() => _days[dayIdx].exercises.add(_DraftExercise()));
  }

  void _removeExercise(int dayIdx, int exIdx) {
    setState(() {
      _days[dayIdx].exercises[exIdx].dispose();
      _days[dayIdx].exercises.removeAt(exIdx);
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.read<ToastProvider>().show('Bitte einen Namen vergeben ✏️');
      return;
    }

    final days = _days.map((d) {
      final isRest = _mode == 'weekday' && d.rest;
      final exercises = isRest
          ? <Exercise>[]
          : d.exercises.where((e) => e.name.text.trim().isNotEmpty).map((e) {
              final parsedSets = int.tryParse(e.sets.text.trim()) ?? 1;
              final setCount = parsedSets < 1 ? 1 : parsedSets;
              final w = double.tryParse(e.weight.text.trim().replaceAll(',', '.')) ?? 0;
              final r = e.reps.text.trim().isEmpty ? '—' : e.reps.text.trim();
              return Exercise.fresh(
                e.name.text.trim(),
                '',
                90,
                List.generate(setCount, (_) => ExerciseSet(w: w, r: r)),
              );
            }).toList();
      final label = d.labelController.text.trim().isEmpty ? d.label : d.labelController.text.trim();
      return Day(label: label, rest: isRest, exercises: exercises);
    }).toList();

    final program = Program(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      mode: _mode,
      startDate: todayIso(),
      days: days,
    );

    context.read<ProgramsProvider>().addProgram(program);
    final idx = todayIndexForProgram(mode: program.mode, currentDayIdx: program.currentDayIdx);
    context.read<TrainStateProvider>().selectPlan(program.id, viewedDayIdx: idx);
    context.read<ToastProvider>().show('Trainingsplan gespeichert ✅');
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final d in _days) {
      d.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Neuer Plan'),
        actions: [TextButton(onPressed: _save, child: const Text('Speichern'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name des Plans'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'weekday', label: Text('Wochentag')),
                ButtonSegment(value: 'rotation', label: Text('Rotation')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => _setMode(s.first),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _days.length; i++) _buildDayCard(i),
            if (_mode == 'rotation')
              OutlinedButton(
                onPressed: _addRotationDay,
                child: const Text('+ Tag/Routine hinzufügen'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(int i) {
    final day = _days[i];
    final hidden = _mode == 'weekday' && day.rest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _mode == 'rotation'
                      ? TextField(
                          controller: day.labelController,
                          decoration: const InputDecoration(labelText: 'Bezeichnung'),
                        )
                      : Text(day.label, style: Theme.of(context).textTheme.headlineMedium),
                ),
                if (_mode == 'weekday') ...[
                  const Text('Ruhetag'),
                  Checkbox(
                    value: day.rest,
                    onChanged: (v) => setState(() => day.rest = v ?? false),
                  ),
                ],
                if (_mode == 'rotation')
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeDay(i),
                  ),
              ],
            ),
            if (!hidden) ...[
              for (var j = 0; j < day.exercises.length; j++) _buildExerciseRow(i, j),
              TextButton(
                onPressed: () => _addExercise(i),
                child: const Text('+ Übung hinzufügen'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRow(int dayIdx, int exIdx) {
    final ex = _days[dayIdx].exercises[exIdx];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: ex.name,
              decoration: const InputDecoration(hintText: 'Übung'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: ex.sets,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Sätze'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: ex.reps,
              decoration: const InputDecoration(hintText: 'Wdh.'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: ex.weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'kg'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _removeExercise(dayIdx, exIdx),
          ),
        ],
      ),
    );
  }
}
