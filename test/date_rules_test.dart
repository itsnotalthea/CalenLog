import 'dart:math';

import 'package:calenlog/core/constants.dart';
import 'package:calenlog/core/date_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('month boundaries', () {
    test('earliest month is January 2026', () {
      expect(earliestMonth, DateTime(2026, 1));
    });

    test('latest month is December of the current year', () {
      expect(latestMonth(DateTime(2026, 9, 28)), DateTime(2026, 12));
      expect(latestMonth(DateTime(2026, 1, 1)), DateTime(2026, 12));
      expect(latestMonth(DateTime(2026, 11, 30)), DateTime(2026, 12));
    });

    test('reaching 1 December unlocks the whole next year', () {
      expect(latestMonth(DateTime(2026, 12, 1)), DateTime(2027, 12));
      expect(latestMonth(DateTime(2026, 12, 31)), DateTime(2027, 12));
    });

    test('monthIndex orders months monotonically', () {
      expect(monthIndex(DateTime(2026, 1)), 2026 * 12);
      expect(monthIndex(DateTime(2026, 2)), monthIndex(DateTime(2026, 1)) + 1);
      expect(monthIndex(DateTime(2027, 1)), monthIndex(DateTime(2026, 12)) + 1);
    });
  });

  group('navigation guards', () {
    test('cannot go before January 2026', () {
      expect(canGoBackwards(DateTime(2026, 2)), isTrue);
      expect(canGoBackwards(DateTime(2026, 1)), isFalse);
      expect(canGoBackwards(DateTime(2025, 12)), isFalse);
    });

    test('cannot go past December of this year', () {
      expect(canGoForwards(DateTime(2026, 11), DateTime(2026, 9, 28)), isTrue);
      expect(canGoForwards(DateTime(2026, 12), DateTime(2026, 9, 28)), isFalse);
    });

    test('in December the next year becomes reachable', () {
      expect(canGoForwards(DateTime(2026, 12), DateTime(2026, 12, 5)), isTrue);
      expect(canGoForwards(DateTime(2027, 12), DateTime(2026, 12, 5)), isFalse);
    });
  });

  group('day editability', () {
    final today = DateTime(2026, 9, 28);

    test('past and present days are editable', () {
      expect(isDayEditable(DateTime(2026, 1, 1), today), isTrue);
      expect(isDayEditable(DateTime(2026, 9, 27), today), isTrue);
      expect(isDayEditable(DateTime(2026, 9, 28), today), isTrue);
    });

    test('future days are locked', () {
      expect(isDayEditable(DateTime(2026, 9, 29), today), isFalse);
      expect(isDayEditable(DateTime(2026, 12, 31), today), isFalse);
    });

    test('days before 1 January 2026 are locked', () {
      expect(isDayEditable(DateTime(2025, 12, 31), today), isFalse);
    });

    test('compare on calendar days, ignoring the time of day', () {
      expect(
        isDayEditable(
          DateTime(2026, 9, 28, 23, 59),
          DateTime(2026, 9, 28, 0, 1),
        ),
        isTrue,
      );
    });
  });

  group('forward-lock messages', () {
    test('first pick is 50/50, then strictly alternating', () {
      // A seeded Random with nextBool() returning true always picks index 0.
      final messenger = ForwardLockMessenger(_FixedRandom(true));
      final first = messenger.nextMessage();
      final second = messenger.nextMessage();
      final third = messenger.nextMessage();

      expect(first, Messages.futureWalls[0]);
      expect(second, Messages.futureWalls[1]);
      expect(third, Messages.futureWalls[0]);
      expect({first, second, third}, Messages.futureWalls.toSet());
    });

    test('a random first pick still alternates afterwards', () {
      final messenger = ForwardLockMessenger(_FixedRandom(false));
      final first = messenger.nextMessage();
      expect(first, Messages.futureWalls[1]);
      expect(messenger.nextMessage(), Messages.futureWalls[0]);
      expect(messenger.nextMessage(), Messages.futureWalls[1]);
    });
  });
}

/// Deterministic `Random` whose `nextBool` always returns [value].
class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final bool value;

  @override
  bool nextBool() => value;

  @override
  double nextDouble() => value ? 1 : 0;

  @override
  int nextInt(int max) => 0;
}
