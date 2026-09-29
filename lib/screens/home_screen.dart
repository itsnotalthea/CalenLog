/// The main app screen: sidebar + calendar, with the modal stack on top.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/habit.dart';
import '../state/controllers.dart';
import '../widgets/calendar_view.dart';
import '../widgets/modals.dart';
import '../widgets/sidebar.dart';

enum _Modal { none, options, category, delete, changePassword, reset, timeLock }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _Modal _modal = _Modal.none;

  /// Habit being edited; null means adding.
  Habit? _editing;

  String _timeLockMessage = '';

  void _close() {
    if (_modal != _Modal.none) setState(() => _modal = _Modal.none);
  }

  void _showTimeLock(String message) {
    setState(() {
      _timeLockMessage = message;
      _modal = _Modal.timeLock;
    });
  }

  void _banner(String message) =>
      ref.read(errorBannerProvider.notifier).show(message);

  void _addHabit() {
    if (ref.read(appDataProvider).habits.length >= maxHabits) {
      _banner(Messages.maxHabitsReached);
      return;
    }
    setState(() {
      _editing = null;
      _modal = _Modal.category;
    });
  }

  void _deleteHabit() {
    final data = ref.read(appDataProvider);
    if (data.habits.length <= 1) {
      _banner(Messages.cannotDeleteLast);
      return;
    }
    setState(() {
      _editing = ref.read(activeHabitProvider);
      _modal = _Modal.delete;
    });
  }

  void _editHabit(Habit habit) {
    setState(() {
      _editing = habit;
      _modal = _Modal.category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final active = ref.watch(activeHabitProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = Palette(isDark);

    return ColoredBox(
      color: palette.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(24), // p-6
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Sidebar(
                  habits: data.habits,
                  activeHabitId: active.id,
                  isDark: isDark,
                  onSelect: (habit) => ref
                      .read(selectedHabitIdProvider.notifier)
                      .select(habit.id),
                  onEdit: _editHabit,
                  onAdd: _addHabit,
                  onDelete: _deleteHabit,
                  onOptions: () => setState(() => _modal = _Modal.options),
                  onExit: () => SystemNavigator.pop(),
                ),
                const SizedBox(width: 24), // mr-6
                Expanded(child: CalendarView(onTimeLock: _showTimeLock)),
              ],
            ),
          ),
          if (_modal != _Modal.none) _buildModal(isDark, active),
        ],
      ),
    );
  }

  Widget _buildModal(bool isDark, Habit active) {
    switch (_modal) {
      case _Modal.none:
        return const SizedBox.shrink();

      case _Modal.options:
        return OptionsModal(
          isDark: isDark,
          onChangePassword: () =>
              setState(() => _modal = _Modal.changePassword),
          onToggleDarkMode: () =>
              ref.read(appDataProvider.notifier).setDarkMode(!isDark),
          onReset: () => setState(() => _modal = _Modal.reset),
          onClose: _close,
        );

      case _Modal.category:
        final editing = _editing;
        return CategoryModal(
          isDark: isDark,
          title: editing == null
              ? Messages.addCategoryTitle
              : Messages.editCategoryTitle,
          initialName:
              editing?.name ??
              defaultHabitName(ref.read(appDataProvider).habits.length),
          initialColor: editing?.color ?? defaultHabitColor,
          onCancel: _close,
          onSave: (name, color) {
            final controller = ref.read(appDataProvider.notifier);
            final saved = editing == null
                ? controller.addHabit(name: name, color: color)
                : controller.updateHabit(editing.id, name: name, color: color);
            if (saved) _close();
          },
        );

      case _Modal.delete:
        return DeleteHabitModal(
          isDark: isDark,
          text: 'Are you sure you want to delete "${active.name}"?',
          onCancel: _close,
          onConfirm: () {
            ref.read(appDataProvider.notifier).deleteHabit(active.id);
            _close();
          },
        );

      case _Modal.changePassword:
        return ChangePasswordModal(
          isDark: isDark,
          onCancel: _close,
          onUpdate: (current, next) => ref
              .read(authControllerProvider.notifier)
              .changePassword(current, next),
        );

      case _Modal.reset:
        return ResetModal(
          isDark: isDark,
          onCancel: _close,
          onConfirm: () async {
            _close();
            await ref.read(appDataProvider.notifier).resetAll();
          },
        );

      case _Modal.timeLock:
        return TimeLockModal(
          isDark: isDark,
          message: _timeLockMessage,
          onDismiss: _close,
        );
    }
  }
}
