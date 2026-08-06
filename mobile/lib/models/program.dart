import 'day.dart';
import 'exercise.dart';

class Program {
  Program({
    required this.id,
    required this.name,
    required this.mode,
    this.completed = 0,
    this.currentDayIdx = 0,
    required this.startDate,
    required this.days,
    List<Exercise>? dailyExercises,
  }) : dailyExercises = dailyExercises ?? [];

  String id;
  String name;
  String mode; // 'weekday' | 'rotation'
  int completed;
  int currentDayIdx; // used only in rotation mode
  String startDate; // 'YYYY-MM-DD'
  List<Day> days; // 7 entries if mode == 'weekday'
  List<Exercise> dailyExercises; // done on every training day, not just one

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode,
        'completed': completed,
        'currentDayIdx': currentDayIdx,
        'startDate': startDate,
        'days': days.map((d) => d.toJson()).toList(),
        'dailyExercises': dailyExercises.map((e) => e.toJson()).toList(),
      };

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: json['id'] as String,
        name: json['name'] as String,
        mode: json['mode'] as String,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        currentDayIdx: (json['currentDayIdx'] as num?)?.toInt() ?? 0,
        startDate: json['startDate'] as String,
        days: (json['days'] as List? ?? [])
            .map((d) => Day.fromJson(d as Map<String, dynamic>))
            .toList(),
        dailyExercises: (json['dailyExercises'] as List? ?? [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
