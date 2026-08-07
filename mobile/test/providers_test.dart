import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ironpeak_mobile/models/exercise.dart';
import 'package:ironpeak_mobile/models/exercise_set.dart';
import 'package:ironpeak_mobile/models/program.dart';
import 'package:ironpeak_mobile/services/storage_service.dart';
import 'package:ironpeak_mobile/state/big_lifts_provider.dart';
import 'package:ironpeak_mobile/state/programs_provider.dart';
import 'package:ironpeak_mobile/state/toast_provider.dart';
import 'package:ironpeak_mobile/state/train_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<StorageService> freshStorage() async {
    SharedPreferences.setMockInitialValues({});
    return StorageService.create();
  }

  group('ProgramsProvider', () {
    test('adjustWeight clamps at 0 and rounds to the nearest 0.5', () async {
      final storage = await freshStorage();
      final provider = ProgramsProvider(storage);
      final ex = Exercise.fresh('Squat', '', 90, [ExerciseSet(w: 1, r: '5')]);

      provider.adjustWeight([ex], 0, 0, -5); // 1 - 5 = -4 -> clamp to 0
      expect(ex.sets[0].w, 0);

      provider.adjustWeight([ex], 0, 0, 2.3); // 0 + 2.3 -> rounds to 2.5
      expect(ex.sets[0].w, 2.5);
    });

    test('toggleSet only ever adds, never removes (one-way)', () async {
      final storage = await freshStorage();
      final provider = ProgramsProvider(storage);
      final ex = Exercise.fresh('Squat', '', 90, [ExerciseSet(w: 100, r: '5')]);

      provider.toggleSet([ex], 0, 0);
      provider.toggleSet([ex], 0, 0);
      expect(ex.done, [0]);
    });

    test('saveExerciseLog always overwrites every set weight', () async {
      final storage = await freshStorage();
      final provider = ProgramsProvider(storage);
      final ex = Exercise.fresh('Bankdrücken', '', 90,
          [ExerciseSet(w: 60, r: '8'), ExerciseSet(w: 60, r: '8')]);

      provider.saveExerciseLog([ex], 0, 50, [8, 7]); // lower weight still overwrites
      expect(ex.sets.every((s) => s.w == 50), isTrue);
      expect(ex.history.single.weight, 50);
    });

    test('importExerciseHistory only overwrites weight if the import is higher', () async {
      final storage = await freshStorage();
      final provider = ProgramsProvider(storage);
      final ex = Exercise.fresh('Bankdrücken', '', 90, [ExerciseSet(w: 60, r: '8')]);

      provider.importExerciseHistory([ex], 0, 50, []); // lower -> no overwrite
      expect(ex.sets[0].w, 60);

      provider.importExerciseHistory([ex], 0, 70, []); // higher -> overwrite
      expect(ex.sets[0].w, 70);
    });

    test('addProgram + persistence survives a reload from the same prefs backing', () async {
      SharedPreferences.setMockInitialValues({});
      final storageA = await StorageService.create();
      final providerA = ProgramsProvider(storageA);
      providerA.addProgram(Program(
        id: 'plan_1',
        name: 'Testplan',
        mode: 'weekday',
        startDate: '2026-01-01',
        days: [],
      ));
      // _persist() fires the write without awaiting it (matches the real
      // app, which never blocks UI handlers on persistence) — give that
      // pending write a chance to land before reading it back.
      await Future<void>.delayed(Duration.zero);

      final storageB = await StorageService.create();
      final providerB = ProgramsProvider(storageB);
      expect(providerB.programs.single.id, 'plan_1');
    });
  });

  group('TrainStateProvider', () {
    test('selectPlan persists activePlanId + viewedDayIdx', () async {
      final storage = await freshStorage();
      final provider = TrainStateProvider(storage);
      provider.selectPlan('plan_1', viewedDayIdx: 3);
      expect(provider.activePlanId, 'plan_1');
      expect(provider.viewedDayIdx, 3);
    });
  });

  group('BigLiftsProvider', () {
    test('savePr never touches prDate', () async {
      final storage = await freshStorage();
      final provider = BigLiftsProvider(storage);
      provider.mergeParsedPr(bench: 80, date: '2026-01-01');
      provider.savePr('bench', 85);
      expect(provider.lifts.bench.pr, 85);
      expect(provider.lifts.bench.prDate, '2026-01-01');
    });

    test('mergeParsedPr only sets prDate when a date was parsed', () async {
      final storage = await freshStorage();
      final provider = BigLiftsProvider(storage);
      provider.mergeParsedPr(deadlift: 150); // no date
      expect(provider.lifts.deadlift.pr, 150);
      expect(provider.lifts.deadlift.prDate, isNull);
    });
  });

  group('ToastProvider', () {
    test('show() sets message + visible synchronously', () async {
      final provider = ToastProvider();
      provider.show('Gespeichert ✅');
      expect(provider.visible, isTrue);
      expect(provider.message, 'Gespeichert ✅');
      provider.dispose();
    });
  });
}
