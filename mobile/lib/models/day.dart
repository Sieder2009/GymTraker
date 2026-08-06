import 'exercise.dart';

class Day {
  Day({required this.label, required this.rest, List<Exercise>? exercises})
      : exercises = exercises ?? [];

  String label;
  bool rest;
  List<Exercise> exercises;

  Map<String, dynamic> toJson() => {
        'label': label,
        'rest': rest,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Day.fromJson(Map<String, dynamic> json) => Day(
        label: json['label'] as String,
        rest: json['rest'] as bool? ?? false,
        exercises: (json['exercises'] as List? ?? [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
