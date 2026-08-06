import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../models/exercise.dart';
import '../models/history_entry.dart';
import '../services/log_parser.dart';
import '../state/toast_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../widgets/weight_ruler.dart';

String _formatRep(Object v) => v is int ? '$v' : v.toString().toUpperCase();

/// Single-exercise editor: drag-ruler weight picker, per-set reps, rename,
/// "Verlauf einfügen" paste-in, and reversed (most-recent-first) history.
/// Ported from `ExerciseDetail.svelte`.
///
/// Saving auto-advances to the next exercise in [exercises] instead of
/// closing, matching the original's multi-exercise "next" flow — the
/// screen only pops after saving the LAST exercise in the list.
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exercises,
    required this.startIdx,
    required this.onSave,
    this.onRename,
    this.onImportHistory,
  });

  final List<Exercise> exercises;
  final int startIdx;
  final void Function(int idx, double weight, List<Object> reps) onSave;
  final void Function(int idx, String newName)? onRename;
  final void Function(int idx, double weight, List<HistoryEntry> history)? onImportHistory;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late int _idx;
  late double _weight;
  List<TextEditingController> _repsControllers = [];
  bool _renaming = false;
  final TextEditingController _renameController = TextEditingController();
  bool _historyPasteOpen = false;
  final TextEditingController _historyPasteController = TextEditingController();

  Exercise get _ex => widget.exercises[_idx];

  @override
  void initState() {
    super.initState();
    _loadExercise(widget.startIdx);
  }

  void _loadExercise(int i) {
    for (final c in _repsControllers) {
      c.dispose();
    }
    final ex = widget.exercises[i];
    final lastSetWeight = ex.sets.isNotEmpty ? ex.sets.last.w : 0.0;
    _idx = i;
    _weight = lastSetWeight > 0 ? lastSetWeight : ex.startW;
    _repsControllers = List.generate(ex.sets.length, (_) => TextEditingController());
    _renaming = false;
    _historyPasteOpen = false;
    _historyPasteController.clear();
  }

  @override
  void dispose() {
    for (final c in _repsControllers) {
      c.dispose();
    }
    _renameController.dispose();
    _historyPasteController.dispose();
    super.dispose();
  }

  void _startRename() {
    setState(() {
      _renameController.text = _ex.name;
      _renaming = true;
    });
  }

  void _confirmRename() {
    final name = _renameController.text.trim();
    if (name.isNotEmpty) widget.onRename?.call(_idx, name);
    setState(() => _renaming = false);
  }

  bool get _hasRepsEntered => _repsControllers.any((c) => c.text.trim().isNotEmpty);

  void _importHistoryPaste() {
    final block = parseExerciseBlock(_historyPasteController.text);
    if (block.history.isEmpty) {
      context.read<ToastProvider>().show('Keine Sätze im eingefügten Text erkannt');
      return;
    }
    widget.onImportHistory?.call(_idx, block.weight, block.history);
    setState(() {
      if (block.weight > 0) _weight = block.weight;
      _historyPasteOpen = false;
      _historyPasteController.clear();
    });
    context.read<ToastProvider>().show('Verlauf übernommen ✅');
  }

  void _addSetRow() {
    setState(() => _repsControllers.add(TextEditingController()));
  }

  void _removeSetRow(int i) {
    setState(() {
      _repsControllers[i].dispose();
      _repsControllers.removeAt(i);
    });
  }

  void _save() {
    final reps = _repsControllers
        .map<Object>((c) => int.tryParse(c.text.trim()) ?? 0)
        .toList();
    widget.onSave(_idx, _weight, reps);
    if (_idx < widget.exercises.length - 1) {
      setState(() => _loadExercise(_idx + 1));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final ex = _ex;
    final isLastExercise = _idx == widget.exercises.length - 1;
    final canShowHistoryPaste = widget.onImportHistory != null && !_hasRepsEntered;
    // Chronological order, oldest first — history entries are already
    // appended in that order, so no reversal needed.
    final history = ex.history;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _renaming
            ? TextField(
                controller: _renameController,
                autofocus: true,
                onSubmitted: (_) => _confirmRename(),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(ex.name, overflow: TextOverflow.ellipsis)),
                  if (widget.onRename != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: _startRename,
                    ),
                ],
              ),
        actions: _renaming
            ? [IconButton(icon: const Icon(Icons.check), onPressed: _confirmRename)]
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (ex.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  ex.note,
                  style: TextStyle(color: colors.accent, fontWeight: FontWeight.w600),
                ),
              ),
            WeightRuler(value: _weight, onChanged: (v) => setState(() => _weight = v)),
            Center(
              child: Text(
                'Zum Ändern nach links oder rechts ziehen',
                style: TextStyle(color: colors.mut, fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < _repsControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 28, child: Text('${i + 1}', style: TextStyle(color: colors.mut))),
                    Expanded(
                      child: TextField(
                        controller: _repsControllers[i],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Wdh.'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeSetRow(i),
                    ),
                  ],
                ),
              ),
            TextButton(onPressed: _addSetRow, child: const Text('+ Satz')),
            const SizedBox(height: 12),
            if (canShowHistoryPaste) ...[
              if (!_historyPasteOpen)
                TextButton(
                  onPressed: () => setState(() => _historyPasteOpen = true),
                  child: const Text('+ Verlauf einfügen'),
                )
              else ...[
                TextField(
                  controller: _historyPasteController,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Log-Text für diese Übung einfügen …'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _historyPasteOpen = false),
                      child: const Text('Abbrechen'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _importHistoryPaste,
                      child: const Text('Übernehmen'),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isLastExercise ? 'Speichern' : 'Speichern & weiter'),
              ),
            ),
            const SizedBox(height: 28),
            if (history.isNotEmpty) ...[
              Text('VERLAUF', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => _HistoryCard(
                    entry: history[i],
                    isLatest: i == history.length - 1,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'X = weniger Gewicht verwendet · M = mehr Gewicht verwendet · '
                '✓ = erledigt, ohne Wiederholungszahl',
                style: TextStyle(color: colors.mut, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One session in the horizontally-scrolling history strip — oldest entries
/// on the left, newest (highlighted) on the right, weight as the leading
/// (top-left) label per entry.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.isLatest, required this.colors});

  final HistoryEntry entry;
  final bool isLatest;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(left: BorderSide(color: isLatest ? colors.green : colors.line, width: 3)),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                entry.weight > 0 ? '${fmt1(entry.weight)} kg' : 'BW',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (isLatest) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Aktuell',
                    style: TextStyle(color: colors.green, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entry.reps.map(_formatRep).join(' · '),
            style: TextStyle(color: colors.mut, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
