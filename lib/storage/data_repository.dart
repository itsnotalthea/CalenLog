/// One JSON file in the app-support directory.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_data.dart';
import '../models/habit.dart';

class DataRepository {
  DataRepository({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectory;

  static const String _fileName = 'data.json';

  Future<File> file() async {
    final support = await _supportDirectory();
    final folder = Directory(
      '${support.path}${Platform.pathSeparator}calenlog',
    );
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return File('${folder.path}${Platform.pathSeparator}$_fileName');
  }

  /// Loads persisted data, falling back to [seed] on first launch or when the
  /// file is unreadable (a corrupt file must never brick the app).
  Future<AppData> load({required List<Habit> seed}) async {
    try {
      final target = await file();
      if (!await target.exists()) return AppData.initial(seed);
      final contents = await target.readAsString();
      if (contents.trim().isEmpty) return AppData.initial(seed);
      final decoded = jsonDecode(contents);
      if (decoded is! Map<String, dynamic>) return AppData.initial(seed);
      final data = AppData.fromJson(decoded);
      // A habit list can never be empty — the UI needs at least one.
      return data.habits.isEmpty ? AppData.initial(seed) : data;
    } catch (_) {
      return AppData.initial(seed);
    }
  }

  /// Writes state atomically (temp file + rename) so a crash mid-write can't
  /// truncate the file.
  Future<void> save(AppData data) async {
    final target = await file();
    final temp = File('${target.path}.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    await temp.writeAsString(encoder.convert(data.toJson()), flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await temp.rename(target.path);
  }

  Future<void> clear() async {
    try {
      final target = await file();
      if (await target.exists()) await target.delete();
      final temp = File('${target.path}.tmp');
      if (await temp.exists()) await temp.delete();
    } catch (_) {
      // Best effort: a leftover file simply reloads as first-launch data.
    }
  }
}
