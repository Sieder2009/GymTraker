import 'package:flutter/foundation.dart';

import '../data/constants.dart';
import '../models/exercise.dart';
import '../models/history_entry.dart';
import '../models/program.dart';
import '../services/storage_service.dart';

const String _kProgramsKey = 'ironpeak:programs';

/// Owns every saved [Program]. Exercise-mutation methods take the already
/// resolved `List<Exercise>` (either `program.days[i].exercises` or
/// `program.dailyExercises`) rather than duplicating a parallel set of
/// "daily" handlers as the original Svelte screen does — since Dart lists
/// are references, mutating the passed-in list mutates the Program itself.
class ProgramsProvider extends ChangeNotifier {
  ProgramsProvider(this._storage) : _programs = _initial(_storage);

  final StorageService _storage;
  List<Program> _programs;

  List<Program> get programs => List.unmodifiable(_programs);

  static List<Program> _initial(StorageService storage) {
    final decoded = storage.readJson<List<Program>>(
      _kProgramsKey,
      (raw) => (raw as List)
          .map((e) => Program.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return decoded ?? [];
  }

  void _persist() {
    _storage.writeJson(
      _kProgramsKey,
      () => _programs.map((p) => p.toJson()).toList(),
    );
  }

  Program? byId(String? id) {
    if (id == null) return null;
    for (final p in _programs) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addProgram(Program program) {
    _programs.add(program);
    _persist();
    notifyListeners();
  }

  void removeProgram(String id) {
    _programs.removeWhere((p) => p.id == id);
    _persist();
    notifyListeners();
  }

  void adjustWeight(
    List<Exercise> exercises,
    int exIdx,
    int setIdx,
    double delta,
  ) {
    final set = exercises[exIdx].sets[setIdx];
    var next = set.w + delta;
    if (next < 0) next = 0;
    next = (next * 2).round() / 2;
    set.w = next;
    _persist();
    notifyListeners();
  }

  void toggleSet(List<Exercise> exercises, int exIdx, int setIdx) {
    final ex = exercises[exIdx];
    if (!ex.done.contains(setIdx)) {
      ex.done.add(setIdx);
      _persist();
      notifyListeners();
    }
  }

  /// Pushes a new history entry AND overwrites every current set's weight
  /// to [weight] — matches the original's `saveExerciseLog` exactly (it
  /// always overwrites, unlike [importExerciseHistory] below).
  void saveExerciseLog(
    List<Exercise> exercises,
    int exIdx,
    double weight,
    List<Object> reps,
  ) {
    final ex = exercises[exIdx];
    ex.history.add(HistoryEntry(weight: weight, reps: reps, date: todayIso()));
    for (final s in ex.sets) {
      s.w = weight;
    }
    _persist();
    notifyListeners();
  }

  void renameExercise(List<Exercise> exercises, int exIdx, String newName) {
    exercises[exIdx].name = newName;
    _persist();
    notifyListeners();
  }

  /// Appends pasted history and only overwrites the current set weights if
  /// the imported weight exceeds the existing max (unlike [saveExerciseLog],
  /// which always overwrites).
  void importExerciseHistory(
    List<Exercise> exercises,
    int exIdx,
    double weight,
    List<HistoryEntry> history,
  ) {
    final ex = exercises[exIdx];
    ex.history.addAll(history);
    var currentMax = 0.0;
    for (final s in ex.sets) {
      if (s.w > currentMax) currentMax = s.w;
    }
    if (weight > currentMax) {
      for (final s in ex.sets) {
        s.w = weight;
      }
    }
    _persist();
    notifyListeners();
  }

  void finishWorkout(Program program) {
    program.completed += 1;
    _persist();
    notifyListeners();
  }
}
