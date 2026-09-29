/// Date navigation rules for month traversal and day locking.
library;

import 'dart:math';

import 'constants.dart';

DateTime get earliestMonth => DateTime(minDate.year, minDate.month);

/// Mirrors `getMaxDate()`: December of this year, or of *next* year once the
/// clock has reached 1 December.
DateTime latestMonth(DateTime now) => DateTime(
  now.month == DateTime.december ? now.year + 1 : now.year,
  DateTime.december,
);

int monthIndex(DateTime d) => d.year * 12 + (d.month - 1);

bool canGoBackwards(DateTime current) =>
    monthIndex(current) > monthIndex(earliestMonth);

bool canGoForwards(DateTime current, DateTime now) =>
    monthIndex(current) < monthIndex(latestMonth(now));

/// Days before the 1 January 2026 wall or after today are locked, even once
/// the next year's view has opened.
bool isDayEditable(DateTime day, DateTime today) {
  final d = DateTime(day.year, day.month, day.day);
  final t = DateTime(today.year, today.month, today.day);
  return !d.isAfter(t) && !d.isBefore(minDate);
}

class ForwardLockMessenger {
  ForwardLockMessenger([Random? random]) : _random = random ?? Random();

  final Random _random;
  int? _lastIndex;

  String nextMessage() {
    final int index;
    if (_lastIndex == null) {
      index = _random.nextBool() ? 0 : 1;
    } else {
      index = _lastIndex == 0 ? 1 : 0;
    }
    _lastIndex = index;
    return Messages.futureWalls[index];
  }
}
