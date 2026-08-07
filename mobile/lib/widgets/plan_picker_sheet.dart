import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/program.dart';
import '../theme/app_colors.dart';

/// Shared "choose a plan" list, used both for the forced plan-choice prompt
/// at launch (multiple saved plans, non-dismissible) and the manual "Alle
/// Pläne" button (dismissible). Deleting a plan asks for confirmation first
/// (it takes the plan's full logged history with it) and never closes the
/// sheet itself — [onDelete] handles that.
class PlanPickerSheet extends StatelessWidget {
  const PlanPickerSheet({
    super.key,
    required this.programs,
    required this.activeId,
    required this.onSelect,
    required this.onDelete,
  });

  final List<Program> programs;
  final String? activeId;
  final ValueChanged<Program> onSelect;
  final ValueChanged<Program> onDelete;

  Future<void> _confirmDelete(BuildContext context, Program p) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deletePlanTitle),
        content: Text(t.deletePlanBody(p.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.actionCancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.actionDelete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete(p);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.titlePlanPicker, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            for (final p in programs)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(p.mode == 'weekday' ? t.planSubtitleWeekday : t.modeRotation),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.id == activeId)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.check_circle, color: colors.accent),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: t.actionDelete,
                        onPressed: () => _confirmDelete(context, p),
                      ),
                    ],
                  ),
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
  required ValueChanged<Program> onDelete,
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
      onDelete: onDelete,
    ),
  );
}
