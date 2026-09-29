import 'package:calenlog/core/constants.dart';
import 'package:calenlog/models/app_data.dart';
import 'package:calenlog/models/habit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final habit = const Habit(id: '1', name: 'Habit A', color: '#c084fc');
  final day = DateTime(2026, 9, 14);

  AppData fresh() => AppData.initial(buildDefaultHabits());

  group('log keys', () {
    test('are formatted habitId-YYYY-MM-DD', () {
      expect(logKey('1', day), '1-2026-09-14');
      expect(logKey('42', DateTime(2026, 1, 5)), '42-2026-01-05');
      expect(isoDate(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('intensity cycling', () {
    test('walks 0 → 1 → 2 → 3 → 0', () {
      var data = fresh();
      expect(data.levelFor(habit.id, day), 0);

      data = data.cycle(habit.id, day);
      expect(data.levelFor(habit.id, day), 1);

      data = data.cycle(habit.id, day);
      expect(data.levelFor(habit.id, day), 2);

      data = data.cycle(habit.id, day);
      expect(data.levelFor(habit.id, day), 3);

      data = data.cycle(habit.id, day);
      expect(data.levelFor(habit.id, day), 0);
    });

    test('a wrapped-to-zero entry is removed from the store', () {
      var data = fresh();
      data = data.cycle(habit.id, day);
      expect(data.logs, contains(logKey(habit.id, day)));

      data = data.cycle(habit.id, day);
      data = data.cycle(habit.id, day);
      data = data.cycle(habit.id, day);
      expect(data.logs, isNot(contains(logKey(habit.id, day))));
    });

    test('days are independent', () {
      var data = fresh();
      data = data.cycle(habit.id, day);
      data = data.cycle(habit.id, DateTime(2026, 9, 15));
      data = data.cycle(habit.id, DateTime(2026, 9, 15));
      expect(data.levelFor(habit.id, day), 1);
      expect(data.levelFor(habit.id, DateTime(2026, 9, 15)), 2);
    });
  });

  group('stats', () {
    test('counts every level across the month', () {
      var data = fresh();
      // September 2026 has 30 days.
      for (var d = 1; d <= 3; d++) {
        data = data.cycle(habit.id, DateTime(2026, 9, d));
      }
      data = data.cycle(habit.id, DateTime(2026, 9, 4));
      data = data.cycle(habit.id, DateTime(2026, 9, 4));
      data = data.cycle(habit.id, DateTime(2026, 9, 5));
      data = data.cycle(habit.id, DateTime(2026, 9, 5));
      data = data.cycle(habit.id, DateTime(2026, 9, 5));

      final stats = data.statsFor(habit, DateTime(2026, 9));
      expect(stats[3], 1); // day 5 reached level 3
      expect(stats[2], 1); // day 4 reached level 2
      expect(stats[1], 3); // days 1–3 reached level 1
      expect(stats[0], 25); // everything else
      expect(stats[3]! + stats[2]! + stats[1]! + stats[0]!, 30);
    });

    test('a leap-year February is counted correctly', () {
      final data = fresh();
      final stats = data.statsFor(habit, DateTime(2028, 2));
      expect(stats[0], 29);
    });
  });

  group('JSON round trip', () {
    test('preserves habits, logs and darkMode', () {
      var data = fresh().copyWith(darkMode: true);
      data = data.cycle('1', day);

      final restored = AppData.fromJson(data.toJson());
      expect(restored.darkMode, isTrue);
      expect(restored.habits, data.habits);
      expect(restored.logs, data.logs);
      expect(restored.toJson(), data.toJson());
    });

    test('tolerates a missing or partial payload', () {
      final restored = AppData.fromJson(const {});
      expect(restored.habits, isEmpty);
      expect(restored.logs, isEmpty);
      expect(restored.darkMode, isFalse);
    });
  });

  group('habit helpers', () {
    test('next id is one past the largest numeric id', () {
      expect(fresh().nextHabitId(), '7');
      expect(
        AppData(
          habits: const [Habit(id: '30', name: 'x', color: '#000')],
          logs: const {},
          darkMode: false,
        ).nextHabitId(),
        '31',
      );
    });

    test('habitById returns null for an unknown id', () {
      expect(fresh().habitById('1'), isNotNull);
      expect(fresh().habitById('nope'), isNull);
    });

    test('seeded habits match the expected defaults', () {
      final data = fresh();
      expect(data.habits, hasLength(6));
      expect(data.habits.first.name, 'Habit A');
      expect(data.habits.first.color, '#c084fc');
      expect(data.habits.last.name, 'Habit F');
      expect(data.habits.last.color, '#2dd4bf');
      expect(data.darkMode, isFalse);
    });
  });
}
