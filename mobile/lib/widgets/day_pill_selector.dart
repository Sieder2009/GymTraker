import 'package:flutter/material.dart';

import '../data/constants.dart';
import '../theme/app_colors.dart';

/// Horizontal Mo–So day-pill row for weekday-mode plans. Today gets an
/// outline, the viewed day gets a filled accent background.
class DayPillSelector extends StatelessWidget {
  const DayPillSelector({
    super.key,
    required this.todayIdx,
    required this.selectedIdx,
    required this.onSelect,
  });

  final int todayIdx;
  final int selectedIdx;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kWeekdaysShort.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final isToday = i == todayIdx;
          final isSelected = i == selectedIdx;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colors.accent : colors.card2,
                borderRadius: BorderRadius.circular(22),
                border: isToday && !isSelected
                    ? Border.all(color: colors.accent, width: 1.5)
                    : null,
              ),
              child: Text(
                kWeekdaysShort[i],
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.txt,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
