/// App-wide constants and user-facing copy.
library;

import '../models/habit.dart';

/// Hard backward boundary: the calendar can never navigate earlier.
final DateTime minDate = DateTime(2026, 1, 1);

const int maxHabits = 15;

const int minPasswordLength = 5;

/// Wheel delta per month: 110 is 10% above a standard tick of ~100, so one
/// flick moves one month rather than several.
const double wheelScrollThreshold = 110;

/// scrypt parameter defaults.
const int scryptN = 16384;
const int scryptR = 8;
const int scryptP = 1;

/// 64-byte derived key.
const int scryptKeyLength = 64;

/// 16-byte random salt.
const int saltLength = 16;

const String githubUrl = 'https://github.com/itsnotalthea';

const String defaultHabitColor = '#f87171';

List<Habit> buildDefaultHabits() => const [
  Habit(id: '1', name: 'Habit A', color: '#c084fc'),
  Habit(id: '2', name: 'Habit B', color: '#fbbf24'),
  Habit(id: '3', name: 'Habit C', color: '#f87171'),
  Habit(id: '4', name: 'Habit D', color: '#f472b6'),
  Habit(id: '5', name: 'Habit E', color: '#38bdf8'),
  Habit(id: '6', name: 'Habit F', color: '#2dd4bf'),
];

String defaultHabitName(int currentCount) =>
    'Habit ${String.fromCharCode(65 + currentCount)}';

/// Every message the app can display.
abstract final class Messages {
  static const String passwordTooShort =
      'Password must be at least 5 characters long.';
  static const String passwordMismatch = 'Passwords do not match.';
  static const String incorrectOldPassword = 'Incorrect old password.';
  static const String passwordUnchanged =
      'This is already your current password';

  static const String habitNameTaken = 'A habit with this name already exists.';
  static const String cannotDeleteLast = 'Cannot delete last habit!';
  static const String maxHabitsReached =
      "You've reached the maximum of 15 habits.";

  static const String pastWall = "Don't get stuck in the past :)";
  static const List<String> futureWalls = [
    "Too excited? Let's finish the current year first before moving forward.",
    "Woah there buddy, we don't have a time machine!",
  ];

  static const String splashSubtitle = 'Track habits and routines over time.';
  static const String welcomeSubtitle = 'Welcome!';
  static const String welcomeBackSubtitle = 'Glad to have you back.';
  static const String setPasswordHint = 'Set Password (min 5 chars)';
  static const String confirmPasswordHint = 'Confirm Password';
  static const String loginHint = '**********';
  static const String letsGo = "Let's Go";
  static const String githubLinkLabel = 'GitHub';

  static const String optionsTitle = 'Options';
  static const String changePasswordTitle = 'Change Password';
  static const String oldPasswordHint = 'Old Password';
  static const String newPasswordHint = 'New Password (min 5 chars)';
  static const String addCategoryTitle = 'Add Category';
  static const String editCategoryTitle = 'Edit Category';
  static const String categoryNameHint = 'Category Name';
  static const String categoryColorLabel = 'Category Color';
  static const String deleteHabitTitle = 'Delete Habit';
  static const String deleteHabitDefaultText =
      'Are you sure you want to delete this habit?';
  static const String resetTitle = 'Reset All Data';
  static const String resetBody =
      'This will clear all logs, habits, and your password. '
      'This action cannot be undone.';

  static const String closeButton = 'Close';
  static const String cancelButton = 'Cancel';
  static const String saveButton = 'Save';
  static const String deleteButton = 'Delete';
  static const String updateButton = 'Update';
  static const String resetButton = 'Reset Everything';
  static const String gotItButton = 'Got it';
}
