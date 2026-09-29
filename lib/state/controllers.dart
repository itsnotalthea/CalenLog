/// Screen flow, error banner, auth and data mutations.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/app_data.dart';
import '../models/habit.dart';
import 'providers.dart';

enum AppStage { splash, auth, home }

class StageController extends Notifier<AppStage> {
  @override
  AppStage build() => AppStage.splash;

  void show(AppStage stage) => state = stage;
}

final NotifierProvider<StageController, AppStage> stageProvider =
    NotifierProvider<StageController, AppStage>(StageController.new);

class ErrorBannerController extends Notifier<String?> {
  Timer? _timer;

  @override
  String? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(String message) {
    state = message;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 5), () => state = null);
  }

  void clear() {
    _timer?.cancel();
    state = null;
  }
}

final NotifierProvider<ErrorBannerController, String?> errorBannerProvider =
    NotifierProvider<ErrorBannerController, String?>(ErrorBannerController.new);

class AppDataController extends Notifier<AppData> {
  Timer? _saveTimer;

  @override
  AppData build() {
    ref.onDispose(() => _saveTimer?.cancel());
    return ref.watch(initialDataProvider);
  }

  void _set(AppData next) {
    state = next;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 150), () {
      ref.read(dataRepositoryProvider).save(state);
    });
  }

  void _banner(String message) =>
      ref.read(errorBannerProvider.notifier).show(message);

  void setDarkMode(bool value) => _set(state.copyWith(darkMode: value));

  /// Advances [habitId]'s intensity for one day: 0 → 1 → 2 → 3 → 0.
  /// [habitId] comes from the caller: [activeHabitProvider] watches this
  /// notifier, so reading it here would form a cycle.
  void cycle(String habitId, DateTime day) {
    _set(state.cycle(habitId, day));
  }

  bool addHabit({required String name, required String color}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (state.habits.length >= maxHabits) {
      _banner(Messages.maxHabitsReached);
      return false;
    }
    if (_nameTaken(trimmed)) {
      _banner(Messages.habitNameTaken);
      return false;
    }

    // Milliseconds since the epoch.
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _set(
      state.copyWith(
        habits: [
          ...state.habits,
          Habit(id: id, name: trimmed, color: color),
        ],
      ),
    );
    ref.read(selectedHabitIdProvider.notifier).select(id);
    return true;
  }

  bool updateHabit(String id, {required String name, required String color}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (_nameTaken(trimmed, excludingId: id)) {
      _banner(Messages.habitNameTaken);
      return false;
    }
    _set(
      state.copyWith(
        habits: [
          for (final habit in state.habits)
            if (habit.id == id)
              habit.copyWith(name: trimmed, color: color)
            else
              habit,
        ],
      ),
    );
    return true;
  }

  bool deleteHabit(String id) {
    if (state.habits.length <= 1) {
      _banner(Messages.cannotDeleteLast);
      return false;
    }
    final remaining = state.habits.where((h) => h.id != id).toList();
    _set(state.copyWith(habits: remaining));
    ref.read(selectedHabitIdProvider.notifier).clear();
    return true;
  }

  Future<void> resetAll() async {
    _saveTimer?.cancel();
    await ref.read(dataRepositoryProvider).clear();
    await ref.read(authRepositoryProvider).clear();
    state = AppData.initial(buildDefaultHabits());
    ref.read(selectedHabitIdProvider.notifier).clear();
    ref.read(authControllerProvider.notifier).reset();
    ref.read(errorBannerProvider.notifier).clear();
    ref.read(stageProvider.notifier).show(AppStage.splash);
  }

  bool _nameTaken(String name, {String? excludingId}) {
    final needle = name.toLowerCase();
    return state.habits.any(
      (habit) => habit.id != excludingId && habit.name.toLowerCase() == needle,
    );
  }
}

final NotifierProvider<AppDataController, AppData> appDataProvider =
    NotifierProvider<AppDataController, AppData>(AppDataController.new);

class SelectedHabitController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;

  void clear() => state = null;
}

final NotifierProvider<SelectedHabitController, String?>
selectedHabitIdProvider = NotifierProvider<SelectedHabitController, String?>(
  SelectedHabitController.new,
);

final Provider<Habit> activeHabitProvider = Provider<Habit>((ref) {
  final data = ref.watch(appDataProvider);
  final selected = ref.watch(selectedHabitIdProvider);
  if (selected != null) {
    final match = data.habitById(selected);
    if (match != null) return match;
  }
  return data.habits.first;
});

class AuthState {
  const AuthState({required this.hasPassword, this.unlocked = false});

  final bool hasPassword;
  final bool unlocked;

  AuthState copyWith({bool? hasPassword, bool? unlocked}) => AuthState(
    hasPassword: hasPassword ?? this.hasPassword,
    unlocked: unlocked ?? this.unlocked,
  );
}

class AuthController extends Notifier<AuthState> {
  Timer? _debounce;

  @override
  AuthState build() {
    ref.onDispose(() => _debounce?.cancel());
    return AuthState(hasPassword: ref.watch(initialHasPasswordProvider));
  }

  void _banner(String message) =>
      ref.read(errorBannerProvider.notifier).show(message);

  Future<void> submitSetup(String password, String confirmation) async {
    if (password.length < minPasswordLength) {
      _banner(Messages.passwordTooShort);
      return;
    }
    if (password != confirmation) {
      _banner(Messages.passwordMismatch);
      return;
    }
    await ref.read(authRepositoryProvider).setPassword(password);
    _unlock();
  }

  /// Called on every change, debounced by the view. A wrong password shows no
  /// banner: it would flash while the user is still typing.
  void onLoginChanged(String value) {
    _debounce?.cancel();
    if (value.isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final ok = await ref.read(authRepositoryProvider).verify(value);
      if (ok) _unlock();
    });
  }

  Future<bool> changePassword(String current, String next) async {
    final auth = ref.read(authRepositoryProvider);
    if (!await auth.verify(current)) {
      _banner(Messages.incorrectOldPassword);
      return false;
    }
    if (next.length < minPasswordLength) {
      _banner(Messages.passwordTooShort);
      return false;
    }
    if (await auth.verify(next)) {
      _banner(Messages.passwordUnchanged);
      return false;
    }
    await auth.setPassword(next);
    return true;
  }

  void reset() {
    _debounce?.cancel();
    state = const AuthState(hasPassword: false);
  }

  void _unlock() {
    if (state.unlocked) return;
    state = state.copyWith(unlocked: true);
    ref.read(stageProvider.notifier).show(AppStage.home);
  }
}

final NotifierProvider<AuthController, AuthState> authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
