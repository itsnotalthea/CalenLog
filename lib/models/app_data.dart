/// Persisted application state.
library;

import 'habit.dart';

/// Intensity levels cycled by clicking a cell: 0 → 1 → 2 → 3 → 0.
const int maxLevel = 3;

/// Builds the storage key for one habit/day pair, e.g. `1-2026-09-28`.
String logKey(String habitId, DateTime day) => '$habitId-${_isoDate(day)}';

/// Zero-padded `yyyy-mm-dd` stamp.
String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String isoDate(DateTime d) => _isoDate(d);

class AppData {
  AppData({
    required List<Habit> habits,
    required Map<String, int> logs,
    required this.darkMode,
  }) : habits = List.unmodifiable(habits),
       logs = Map.unmodifiable(logs);

  factory AppData.initial(List<Habit> habits) =>
      AppData(habits: habits, logs: const {}, darkMode: false);

  /// Ordered habit list, max 15.
  final List<Habit> habits;

  /// `habitId-YYYY-MM-DD` → intensity 0–3.
  final Map<String, int> logs;

  final bool darkMode;

  factory AppData.fromJson(Map<String, dynamic> json) {
    final habitsJson = json['habits'] as List<dynamic>? ?? const [];
    final logsJson = json['logs'] as Map<String, dynamic>? ?? const {};

    return AppData(
      habits: habitsJson
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList(),
      logs: logsJson.map((key, value) => MapEntry(key, (value as num).toInt())),
      darkMode: json['darkMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'habits': habits.map((h) => h.toJson()).toList(),
    'logs': logs,
    'darkMode': darkMode,
  };

  AppData copyWith({
    List<Habit>? habits,
    Map<String, int>? logs,
    bool? darkMode,
  }) => AppData(
    habits: habits ?? this.habits,
    logs: logs ?? this.logs,
    darkMode: darkMode ?? this.darkMode,
  );

  int levelFor(String habitId, DateTime day) => logs[logKey(habitId, day)] ?? 0;

  AppData cycle(String habitId, DateTime day) {
    final key = logKey(habitId, day);
    final next = ((logs[key] ?? 0) + 1) % (maxLevel + 1);
    final updated = Map<String, int>.from(logs);
    if (next == 0) {
      updated.remove(key);
    } else {
      updated[key] = next;
    }
    return copyWith(logs: updated);
  }

  /// Count of days at each level (3, 2, 1, 0) for [habit], in stats-bar order.
  Map<int, int> statsFor(Habit habit, DateTime month) {
    final year = month.year;
    final monthNumber = month.month;
    final daysInMonth = DateTime(year, monthNumber + 1, 0).day;

    final counts = {3: 0, 2: 0, 1: 0, 0: 0};
    for (var day = 1; day <= daysInMonth; day++) {
      final level = levelFor(habit.id, DateTime(year, monthNumber, day));
      counts[level] = (counts[level] ?? 0) + 1;
    }
    return counts;
  }

  Habit? habitById(String id) {
    for (final habit in habits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  String nextHabitId() {
    var max = 0;
    for (final habit in habits) {
      final parsed = int.tryParse(habit.id);
      if (parsed != null && parsed > max) max = parsed;
    }
    return (max + 1).toString();
  }
}
