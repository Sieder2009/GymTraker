import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../l10n/app_localizations.dart';
import '../models/program.dart';
import '../services/log_parser.dart';
import '../state/big_lifts_provider.dart';
import '../state/programs_provider.dart';
import '../state/toast_provider.dart';
import '../state/train_state_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// "Log importieren" — paste-in log parsing + preview + save, ported
/// from `ImportLog.svelte`. [initialText]/[initialName] pre-fill and
/// auto-analyze immediately, matching how the original loads the bundled
/// "Beispielplan laden" example without any user action. v1 has no file
/// picker (paste-only) — more natural on a phone, and one less dependency.
class ImportLogScreen extends StatefulWidget {
  const ImportLogScreen({
    super.key,
    this.initialText,
    this.initialName = 'Importierter Plan',
  });

  final String? initialText;
  final String initialName;

  @override
  State<ImportLogScreen> createState() => _ImportLogScreenState();
}

class _ImportLogScreenState extends State<ImportLogScreen> {
  late final TextEditingController _textController;
  late final TextEditingController _nameController;
  ParsedLog? _parsed;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _nameController = TextEditingController(text: widget.initialName);
    if ((widget.initialText ?? '').trim().isNotEmpty) {
      _parsed = parseLog(widget.initialText!);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _analyze() {
    final text = _textController.text;
    if (text.trim().isEmpty) {
      context.read<ToastProvider>().show(AppLocalizations.of(context)!.toastLogRequired);
      return;
    }
    setState(() => _parsed = parseLog(text));
  }

  void _back() => setState(() => _parsed = null);

  void _savePlan() {
    final parsed = _parsed;
    if (parsed == null || parsed.days.isEmpty) return;

    final program = Program(
      id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim().isEmpty
          ? widget.initialName
          : _nameController.text.trim(),
      mode: 'weekday',
      startDate: todayIso(),
      days: toWeekdayPlan(parsed.days),
      dailyExercises: toDailyExercises(parsed.dailyExercises),
    );

    context.read<ProgramsProvider>().addProgram(program);
    final idx = todayIndexForProgram(mode: program.mode, currentDayIdx: program.currentDayIdx);
    context.read<TrainStateProvider>().selectPlan(program.id, viewedDayIdx: idx);

    if (parsed.pr.bench != null || parsed.pr.deadlift != null || parsed.pr.squat != null) {
      context.read<BigLiftsProvider>().mergeParsedPr(
            bench: parsed.pr.bench,
            deadlift: parsed.pr.deadlift,
            squat: parsed.pr.squat,
            date: parsed.pr.date,
          );
    }

    context.read<ToastProvider>().show(AppLocalizations.of(context)!.toastLogImported);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(t.titleImportLog),
      ),
      body: SafeArea(child: parsed == null ? _buildInputView(t) : _buildPreviewView(parsed, t)),
    );
  }

  Widget _buildInputView(AppLocalizations t) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.infoImportLogHelp, style: TextStyle(color: colors.mut)),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          maxLines: 16,
          decoration: InputDecoration(hintText: t.hintLogPaste),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: _analyze, child: Text(t.actionAnalyze)),
        ),
      ],
    );
  }

  Widget _buildPreviewView(ParsedLog parsed, AppLocalizations t) {
    if (parsed.days.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final w in parsed.warnings) _WarningCard(text: w),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _back, child: Text(t.actionBack)),
        ],
      );
    }

    final hasPr = parsed.pr.bench != null || parsed.pr.deadlift != null || parsed.pr.squat != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: t.labelPlanName),
        ),
        const SizedBox(height: 12),
        for (final w in parsed.warnings) _WarningCard(text: w),
        if (hasPr)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.headerDetectedPrs}${parsed.pr.date != null ? ' (${fmtDate(parsed.pr.date!)})' : ''}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (parsed.pr.bench != null) Text('${t.labelBenchPress}: ${fmt(parsed.pr.bench!)} kg'),
                  if (parsed.pr.deadlift != null) Text('${t.labelDeadlift}: ${fmt(parsed.pr.deadlift!)} kg'),
                  if (parsed.pr.squat != null) Text('${t.labelSquat}: ${fmt(parsed.pr.squat!)} kg'),
                ],
              ),
            ),
          ),
        if (parsed.dailyExercises.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(t.headerEveryTrainingDay, style: Theme.of(context).textTheme.labelSmall),
          for (final ex in parsed.dailyExercises) _ExercisePreviewTile(exercise: ex, t: t),
        ],
        const SizedBox(height: 8),
        Text(t.headerDays, style: Theme.of(context).textTheme.labelSmall),
        for (final day in parsed.days)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.dayNumber(day.num), style: Theme.of(context).textTheme.headlineMedium),
                  for (final ex in day.exercises) _ExercisePreviewTile(exercise: ex, t: t),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: _back, child: Text(t.actionBack))),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(onPressed: _savePlan, child: Text(t.actionSavePlan)),
            ),
          ],
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.yellow),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Text(text, style: TextStyle(color: colors.yellow)),
    );
  }
}

class _ExercisePreviewTile extends StatelessWidget {
  const _ExercisePreviewTile({required this.exercise, required this.t});
  final ParsedExercise exercise;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final weightLabel = exercise.weight > 0 ? '${fmt1(exercise.weight)} kg' : t.labelBodyweightAbbr;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(exercise.name)),
          Text(
            '$weightLabel · ${exercise.setCount}x${exercise.reps}',
            style: TextStyle(color: colors.mut),
          ),
        ],
      ),
    );
  }
}
