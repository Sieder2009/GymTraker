import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/exercise_template.dart';
import '../state/exercise_database_provider.dart';
import '../theme/app_colors.dart';

const List<String> kExerciseCategories = [
  'chest', 'back', 'shoulders', 'legs', 'arms', 'core', 'cardio',
];

String categoryLabel(AppLocalizations t, String category) {
  switch (category) {
    case 'chest':
      return t.categoryChest;
    case 'back':
      return t.categoryBack;
    case 'shoulders':
      return t.categoryShoulders;
    case 'legs':
      return t.categoryLegs;
    case 'arms':
      return t.categoryArms;
    case 'core':
      return t.categoryCore;
    case 'cardio':
      return t.categoryCardio;
    default:
      return category;
  }
}

/// Search + category-filter + list, shared between the standalone
/// "Übungen" tab and the plan editor's picker sheet — one implementation,
/// two call sites (see [ExercisesScreen] and `exercise_picker_sheet.dart`).
class ExerciseListView extends StatefulWidget {
  const ExerciseListView({super.key, required this.onTap});

  final ValueChanged<ExerciseTemplate> onTap;

  @override
  State<ExerciseListView> createState() => _ExerciseListViewState();
}

class _ExerciseListViewState extends State<ExerciseListView> {
  final TextEditingController _search = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = Theme.of(context).extension<AppColors>()!;
    final db = context.watch<ExerciseDatabaseProvider>();
    final query = _search.text.trim().toLowerCase();

    final filtered = db.exercises.where((e) {
      if (_category != null && e.category != _category) return false;
      if (query.isNotEmpty && !e.name.toLowerCase().contains(query)) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t.hintSearchExercise,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(t.categoryAll),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
              ),
              for (final c in kExerciseCategories)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(categoryLabel(t, c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = _category == c ? null : c),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    db.isLoading ? '…' : t.emptyExerciseSearch,
                    style: TextStyle(color: colors.mut),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final ex = filtered[i];
                    return Card(
                      child: ListTile(
                        title: Text(ex.name),
                        subtitle: Text(categoryLabel(t, ex.category)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onTap(ex),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
