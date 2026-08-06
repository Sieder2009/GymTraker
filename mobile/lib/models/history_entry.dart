/// One historical session's per-set rep record for an exercise.
///
/// `reps` mixes actual rep counts (`int`) with letter markers carried over
/// from the hand-typed log format: `'✓'` = completed without a logged rep
/// count, `'x'` = weniger Gewicht verwendet, `'m'` = mehr Gewicht verwendet.
class HistoryEntry {
  HistoryEntry({required this.weight, required this.reps});

  double weight;
  List<Object> reps;

  Map<String, dynamic> toJson() => {'weight': weight, 'reps': reps};

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        weight: (json['weight'] as num).toDouble(),
        reps: List<Object>.from(json['reps'] as List),
      );
}
