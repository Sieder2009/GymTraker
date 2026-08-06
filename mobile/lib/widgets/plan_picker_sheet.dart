import 'package:flutter/material.dart';

import '../models/program.dart';
import '../theme/app_colors.dart';

/// Shared "choose a plan" list, used both for the forced plan-choice prompt
/// at launch (multiple saved plans, non-dismissible) and the manual "Alle
/// Pläne" button (dismissible).
class PlanPickerSheet extends StatelessWidget {
  const PlanPickerSheet({
    super.key,
    required this.programs,
    required this.activeId,
    required this.onSelect,
  });

  final List<Program> programs;
  final String? activeId;
  final ValueChanged<Program> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trainingsplan wählen', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            for (final p in programs)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.mode == 'weekday' ? 'Wochentag-Plan' : 'Rotation'),
                  trailing: p.id == activeId
                      ? Icon(Icons.check_circle, color: colors.accent)
                      : null,
                  onTap: () => onSelect(p),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows [PlanPickerSheet] as a modal bottom sheet. [isDismissible] set to
/// false enforces a choice (used for the launch-time forced prompt).
Future<Program?> showPlanPicker(
  BuildContext context, {
  required List<Program> programs,
  required String? activeId,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<Program>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    isScrollControlled: true,
    builder: (ctx) => PlanPickerSheet(
      programs: programs,
      activeId: activeId,
      onSelect: (p) => Navigator.of(ctx).pop(p),
    ),
  );
}
