import 'dart:convert';
import 'dart:io';

import 'package:calenlog/core/constants.dart';
import 'package:calenlog/models/app_data.dart';
import 'package:calenlog/models/habit.dart';
import 'package:calenlog/storage/data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late DataRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('calenlog_test');
    repository = DataRepository(supportDirectory: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('first load returns the seeded state and creates no file', () async {
    final data = await repository.load(seed: buildDefaultHabits());
    expect(data.habits, hasLength(6));
    expect(data.logs, isEmpty);

    final file = await repository.file();
    expect(await file.exists(), isFalse);
  });

  test('save then load round-trips every field', () async {
    var data = AppData.initial(buildDefaultHabits()).copyWith(darkMode: true);
    data = data.cycle('3', DateTime(2026, 9, 28));
    data = data.cycle('3', DateTime(2026, 9, 28));
    data = data.copyWith(
      habits: [
        ...data.habits,
        const Habit(id: '9', name: 'Water', color: '#22c55e'),
      ],
    );

    await repository.save(data);
    final restored = await repository.load(seed: buildDefaultHabits());

    expect(restored.darkMode, isTrue);
    expect(restored.habits, data.habits);
    expect(restored.logs, data.logs);
    expect(restored.toJson(), data.toJson());
  });

  test('the file uses the expected key shape', () async {
    await repository.save(AppData.initial(buildDefaultHabits()));
    final file = await repository.file();
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;

    expect(decoded.keys, containsAll(['habits', 'logs', 'darkMode']));
    expect(decoded['habits'], isA<List<dynamic>>());
    expect(decoded['logs'], isA<Map<String, dynamic>>());
    expect(decoded['darkMode'], isFalse);
  });

  test(
    'a corrupt file falls back to the seeded state instead of throwing',
    () async {
      final file = await repository.file();
      await file.writeAsString('{ this is not json');

      final data = await repository.load(seed: buildDefaultHabits());
      expect(data.habits, hasLength(6));
      expect(data.logs, isEmpty);
    },
  );

  test('saving twice leaves no temporary file behind', () async {
    await repository.save(AppData.initial(buildDefaultHabits()));
    await repository.save(
      AppData.initial(buildDefaultHabits()).cycle('1', DateTime(2026, 1, 2)),
    );

    final file = await repository.file();
    expect(await file.exists(), isTrue);
    expect(await File('${file.path}.tmp').exists(), isFalse);
  });

  test('clear removes the data file', () async {
    await repository.save(AppData.initial(buildDefaultHabits()));
    await repository.clear();

    final file = await repository.file();
    expect(await file.exists(), isFalse);

    final data = await repository.load(seed: buildDefaultHabits());
    expect(data.habits, hasLength(6));
  });
}
