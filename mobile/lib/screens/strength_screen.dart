import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/constants.dart';
import '../state/big_lifts_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/strength_line_chart.dart';

/// "Kraft" tab — Bench/Deadlift/Squat PR tracker.
class StrengthScreen extends StatelessWidget {
  const StrengthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Text('Kraft', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          _LiftCard(liftKey: 'bench', label: 'Bench Press', color: colors.teal),
          _LiftCard(liftKey: 'deadlift', label: 'Deadlift', color: colors.purple),
          _LiftCard(liftKey: 'squat', label: 'Squat', color: colors.yellow),
        ],
      ),
    );
  }
}

class _LiftCard extends StatefulWidget {
  const _LiftCard({required this.liftKey, required this.label, required this.color});

  final String liftKey;
  final String label;
  final Color color;

  @override
  State<_LiftCard> createState() => _LiftCardState();
}

class _LiftCardState extends State<_LiftCard> {
  late final TextEditingController _prController;
  final TextEditingController _entryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Lazily seed once from the store's current PR — mirrors the original's
    // reactive `if (prInputs[key]==='') prInputs[key] = pr || ''` guard,
    // which never overwrites what the user is actively typing.
    final lift = context.read<BigLiftsProvider>().lifts.byKey(widget.liftKey);
    _prController = TextEditingController(text: lift.pr > 0 ? fmt(lift.pr) : '');
  }

  @override
  void dispose() {
    _prController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _savePr() {
    final v = double.tryParse(_prController.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return;
    context.read<BigLiftsProvider>().savePr(widget.liftKey, v);
  }

  void _addEntry() {
    final v = double.tryParse(_entryController.text.replaceAll(',', '.'));
    if (v == null || v <= 0) return;
    context.read<BigLiftsProvider>().addEntry(widget.liftKey, v);
    _entryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final lift = context.watch<BigLiftsProvider>().lifts.byKey(widget.liftKey);
    final colors = Theme.of(context).extension<AppColors>()!;
    final points = lift.history.length > 8
        ? lift.history.sublist(lift.history.length - 8)
        : lift.history;
    final prLabel = lift.pr > 0
        ? 'PR ${fmt(lift.pr)} kg${lift.prDate != null ? ' · ${fmtDate(lift.prDate!)}' : ''}'
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(widget.label, style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: 12),
            if (points.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  prLabel ?? 'Noch keine Einträge — trag deinen aktuellen Wert unten ein.',
                  style: TextStyle(color: colors.mut),
                ),
              )
            else ...[
              StrengthLineChart(
                points: points.map((p) => p.v).toList(),
                pr: lift.pr,
                color: widget.color,
                lineColor: colors.line,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Eintrag'),
                  if (prLabel != null) ...[
                    const SizedBox(width: 16),
                    Text(prLabel, style: TextStyle(color: colors.mut)),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _prController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'PR (kg)'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: _savePr, child: const Text('Speichern')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _entryController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'kg heute'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _addEntry, child: const Text('+ Eintrag')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
