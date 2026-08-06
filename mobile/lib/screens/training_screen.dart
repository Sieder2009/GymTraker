import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../data/example_log.dart';
import '../models/exercise.dart';
import '../models/program.dart';
import '../overlays/exercise_detail_screen.dart';
import '../overlays/import_log_screen.dart';
import '../overlays/plan_editor_screen.dart';
import '../overlays/workout_overlay_screen.dart';
import '../state/programs_provider.dart';
import '../state/train_state_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/day_pill_selector.dart';
import '../widgets/exercise_card.dart';
import '../widgets/plan_picker_sheet.dart';
import '../widgets/theme_toggle_button.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  @override
  void initState() {
    super.initState();
    // Runs once (this screen stays mounted for the app's lifetime inside
    // the shell's IndexedStack) — matches the original's onMount-time
    // forced plan prompt when multiple plans exist.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeForcePlanPrompt());
  }

  Future<void> _maybeForcePlanPrompt() async {
    if (!mounted) return;
    final programs = context.read<ProgramsProvider>().programs;
    if (programs.length <= 1) return;
    final trainState = context.read<TrainStateProvider>();
    final chosen = await showPlanPicker(
      context,
      programs: programs,
      activeId: trainState.activePlanId,
      isDismissible: false,
    );
    if (chosen != null) _selectPlan(chosen);
  }

  void _selectPlan(Program p) {
    final idx = todayIndexForProgram(mode: p.mode, currentDayIdx: p.currentDayIdx);
    context.read<TrainStateProvider>().selectPlan(p.id, viewedDayIdx: idx);
  }

  void _openExerciseDetail(String programId, int? dayIdx, int startIdx) {
    final programs = context.read<ProgramsProvider>();
    final plan = programs.byId(programId)!;
    final exercises = dayIdx == null ? plan.dailyExercises : plan.days[dayIdx].exercises;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ExerciseDetailScreen(
        exercises: exercises,
        startIdx: startIdx,
        onSave: (idx, weight, reps) => programs.saveExerciseLog(exercises, idx, weight, reps),
        onRename: (idx, name) => programs.renameExercise(exercises, idx, name),
        onImportHistory: (idx, weight, history) =>
            programs.importExerciseHistory(exercises, idx, weight, history),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final programsProvider = context.watch<ProgramsProvider>();
    final trainState = context.watch<TrainStateProvider>();
    final colors = Theme.of(context).extension<AppColors>()!;
    final programs = programsProvider.programs;

    if (programs.isEmpty) {
      return _EmptyState(
        onNewPlan: () => Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PlanEditorScreen(),
        )),
        onImportLog: () => Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const ImportLogScreen(),
        )),
        onLoadExample: () => Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const ImportLogScreen(
            initialText: exampleLog,
            initialName: 'Beispielplan',
          ),
        )),
      );
    }

    final plan = programsProvider.byId(trainState.activePlanId) ?? programs.first;
    final todayIdx =
        todayIndexForProgram(mode: plan.mode, currentDayIdx: plan.currentDayIdx);
    final dayIdx = plan.mode == 'weekday' ? trainState.viewedDayIdx : plan.currentDayIdx;
    final day = (plan.days.isNotEmpty && dayIdx < plan.days.length) ? plan.days[dayIdx] : null;
    final isRestDay = day?.rest ?? true;
    final exercises = isRestDay ? const <Exercise>[] : (day?.exercises ?? const <Exercise>[]);
    final dailyExercises = isRestDay ? const <Exercise>[] : plan.dailyExercises;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: Theme.of(context).textTheme.headlineLarge),
                    Text(
                      isRestDay
                          ? '${day?.label ?? ''} · Ruhetag'
                          : '${day?.label ?? ''} · ${plan.completed} Workouts',
                      style: TextStyle(color: colors.mut),
                    ),
                  ],
                ),
              ),
              const ThemeToggleButton(),
              IconButton(
                icon: const Icon(Icons.list_alt),
                tooltip: 'Alle Pläne',
                onPressed: () async {
                  final chosen =
                      await showPlanPicker(context, programs: programs, activeId: plan.id);
                  if (chosen != null) _selectPlan(chosen);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (plan.mode == 'weekday')
            DayPillSelector(
              todayIdx: todayIdx,
              selectedIdx: dayIdx,
              onSelect: (i) => context.read<TrainStateProvider>().setViewedDayIdx(i),
            ),
          const SizedBox(height: 16),
          if (isRestDay)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Ruhetag — heute keine geplanten Übungen.',
                  style: TextStyle(color: colors.mut),
                ),
              ),
            )
          else ...[
            if (exercises.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => WorkoutOverlayScreen(programId: plan.id, dayIdx: dayIdx),
                    )),
                    child: const Text('Workout starten'),
                  ),
                ),
              ),
            if (dailyExercises.isNotEmpty) ...[
              Text('JEDEN TRAININGSTAG', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              for (var i = 0; i < dailyExercises.length; i++)
                ExerciseCard(
                  exercise: dailyExercises[i],
                  onTapName: () => _openExerciseDetail(plan.id, null, i),
                  onAdjustWeight: (setIdx, delta) => context
                      .read<ProgramsProvider>()
                      .adjustWeight(plan.dailyExercises, i, setIdx, delta),
                  onToggleSet: (setIdx) => context
                      .read<ProgramsProvider>()
                      .toggleSet(plan.dailyExercises, i, setIdx),
                ),
              const SizedBox(height: 16),
            ],
            if (exercises.isNotEmpty) ...[
              Text('HEUTIGER TAG', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              for (var i = 0; i < exercises.length; i++)
                ExerciseCard(
                  exercise: exercises[i],
                  onTapName: () => _openExerciseDetail(plan.id, dayIdx, i),
                  onAdjustWeight: (setIdx, delta) => context
                      .read<ProgramsProvider>()
                      .adjustWeight(plan.days[dayIdx].exercises, i, setIdx, delta),
                  onToggleSet: (setIdx) => context
                      .read<ProgramsProvider>()
                      .toggleSet(plan.days[dayIdx].exercises, i, setIdx),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onNewPlan,
    required this.onImportLog,
    required this.onLoadExample,
  });

  final VoidCallback onNewPlan;
  final VoidCallback onImportLog;
  final VoidCallback onLoadExample;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Noch kein Trainingsplan angelegt.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onNewPlan, child: const Text('+ Neuer Plan')),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onImportLog,
                child: const Text('📄 Log importieren'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onLoadExample,
                child: const Text('⭐ Beispielplan laden'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
