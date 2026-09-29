/// The month view: header, stats bar, weekday row and the clickable grid.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/date_rules.dart';
import '../core/theme.dart';
import '../models/app_data.dart';
import '../models/habit.dart';
import '../state/controllers.dart';
import 'smooth_color.dart';

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdayNames = [
  'SUN',
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
];

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key, required this.onTimeLock});

  final ValueChanged<String> onTimeLock;

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView>
    with SingleTickerProviderStateMixin {
  late DateTime _shown;

  DateTime? _previous;

  double _wheelAccumulator = 0;

  int _direction = 1;

  late final AnimationController _slide;

  final ForwardLockMessenger _forwardLock = ForwardLockMessenger();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _shown = DateTime(now.year, now.month);
    _slide =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
          value: 1,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && _previous != null) {
            setState(() => _previous = null);
          }
        });
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _goToPreviousMonth() {
    if (!canGoBackwards(_shown)) {
      widget.onTimeLock(Messages.pastWall);
      return;
    }
    _showMonth(DateTime(_shown.year, _shown.month - 1), -1);
  }

  void _goToNextMonth() {
    if (!canGoForwards(_shown, DateTime.now())) {
      widget.onTimeLock(_forwardLock.nextMessage());
      return;
    }
    _showMonth(DateTime(_shown.year, _shown.month + 1), 1);
  }

  void _showMonth(DateTime next, int direction) {
    setState(() {
      _previous = _shown;
      _direction = direction;
      _shown = next;
    });
    _slide.forward(from: 0);
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    _wheelAccumulator += event.scrollDelta.dy;
    if (_wheelAccumulator >= wheelScrollThreshold) {
      _wheelAccumulator = 0;
      _goToNextMonth();
    } else if (_wheelAccumulator <= -wheelScrollThreshold) {
      _wheelAccumulator = 0;
      _goToPreviousMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = Palette(isDark);
    final data = ref.watch(appDataProvider);
    final habit = ref.watch(activeHabitProvider);

    return Listener(
      // sidebar scroll must not change the month
      onPointerSignal: _onPointerSignal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(palette),
          const SizedBox(height: 8),
          _buildStats(data, habit, palette),
          const SizedBox(height: 8),
          _buildWeekdays(palette),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => _buildGridStack(
                constraints.maxWidth,
                constraints.maxHeight,
                data,
                habit,
                palette,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Palette palette) {
    final title = '${_monthNames[_shown.month - 1]} ${_shown.year}';
    final textStyle = Styles.mono(
      size: 24,
      weight: FontWeight.w700,
      color: palette.text,
      letterSpacing: 0.6,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ArrowButton(
            glyph: '<',
            palette: palette,
            onPressed: _goToPreviousMonth,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final t = animation.value;
                // `status` tells the incoming child from the outgoing one
                final sign = animation.status == AnimationStatus.reverse
                    ? -1.0
                    : 1.0;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(8 * _direction * sign * (1 - t), 0),
                    child: child,
                  ),
                );
              },
            ),
            child: Text(
              title,
              key: ValueKey<int>(monthIndex(_shown)),
              style: textStyle,
            ),
          ),
          _ArrowButton(glyph: '>', palette: palette, onPressed: _goToNextMonth),
        ],
      ),
    );
  }

  Widget _buildStats(AppData data, Habit habit, Palette palette) {
    final stats = data.statsFor(habit, _shown);
    final habitColor = colorFromHex(habit.color);
    final separatorColor = palette.isDark
        ? const Color(0xFF57534E)
        : const Color(0xFFD6D3D1);
    final emptyColor = palette.isDark
        ? const Color(0xFF78716C)
        : Palette.stone400;

    Widget count(int level, {double opacity = 1, Color? color}) => Opacity(
      opacity: opacity,
      child: Text(
        '${stats[level]}',
        style: Styles.ui(
          size: 14,
          weight: FontWeight.w600,
          color: color ?? habitColor,
        ),
      ),
    );

    Widget separator() => Text(
      '|',
      style: Styles.ui(
        size: 14,
        weight: FontWeight.w600,
        color: separatorColor,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        count(3),
        const SizedBox(width: 16),
        separator(),
        const SizedBox(width: 16),
        count(2, opacity: 0.8),
        const SizedBox(width: 16),
        separator(),
        const SizedBox(width: 16),
        count(1, opacity: 0.5),
        const SizedBox(width: 16),
        separator(),
        const SizedBox(width: 16),
        count(0, color: emptyColor),
      ],
    );
  }

  Widget _buildWeekdays(Palette palette) {
    final color = palette.isDark ? Palette.stone400 : Palette.stone500;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final name in _weekdayNames)
            Expanded(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: Styles.ui(
                  size: 12,
                  weight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridStack(
    double availableWidth,
    double availableHeight,
    AppData data,
    Habit habit,
    Palette palette,
  ) {
    final previous = _previous;
    if (previous == null) {
      return _buildGrid(_shown, availableHeight, data, habit, palette);
    }

    final travel = availableWidth * 0.06;
    final sign = _direction >= 0 ? 1.0 : -1.0;

    return AnimatedBuilder(
      animation: _slide,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_slide.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: Opacity(
                opacity: 1 - t,
                child: Transform.translate(
                  offset: Offset(-sign * travel * t, 0),
                  child: _buildGrid(
                    previous,
                    availableHeight,
                    data,
                    habit,
                    palette,
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(sign * travel * (1 - t), 0),
                child: _buildGrid(
                  _shown,
                  availableHeight,
                  data,
                  habit,
                  palette,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(
    DateTime shown,
    double availableHeight,
    AppData data,
    Habit habit,
    Palette palette,
  ) {
    final year = shown.year;
    final month = shown.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // Sun = 0
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    const gap = 8.0;
    final cellHeight = rows > 0
        ? (availableHeight - 8 - (rows - 1) * gap) / rows
        : 0.0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        children: [
          for (var row = 0; row < rows; row++)
            Padding(
              padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : gap),
              child: SizedBox(
                height: cellHeight,
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++) ...[
                      if (col > 0) const SizedBox(width: gap),
                      Expanded(
                        child: _buildCell(
                          row * 7 + col,
                          firstWeekday,
                          daysInMonth,
                          year,
                          month,
                          data,
                          habit,
                          today,
                          palette,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(
    int index,
    int firstWeekday,
    int daysInMonth,
    int year,
    int month,
    AppData data,
    Habit habit,
    DateTime today,
    Palette palette,
  ) {
    final dayNumber = index - firstWeekday + 1;
    if (index < firstWeekday || dayNumber > daysInMonth) {
      return const SizedBox.shrink();
    }

    final day = DateTime(year, month, dayNumber);
    final locked = !isDayEditable(day, today);

    return _DayTile(
      day: dayNumber,
      // locked cells ignore the stored level
      level: locked ? 0 : data.levelFor(habit.id, day),
      locked: locked,
      habitColor: colorFromHex(habit.color),
      palette: palette,
      onTap: () => ref.read(appDataProvider.notifier).cycle(habit.id, day),
    );
  }
}

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({
    required this.glyph,
    required this.palette,
    required this.onPressed,
  });

  final String glyph;
  final Palette palette;
  final VoidCallback onPressed;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SmoothColor(
            color: _hovered
                ? widget.palette.hoverShade(widget.palette.text)
                : widget.palette.text,
            builder: (context, color) => Text(
              widget.glyph,
              style: Styles.ui(size: 20, weight: FontWeight.w700, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayTile extends StatefulWidget {
  const _DayTile({
    required this.day,
    required this.level,
    required this.locked,
    required this.habitColor,
    required this.palette,
    required this.onTap,
  });

  final int day;
  final int level;
  final bool locked;
  final Color habitColor;
  final Palette palette;
  final VoidCallback onTap;

  @override
  State<_DayTile> createState() => _DayTileState();
}

class _DayTileState extends State<_DayTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  /// Ceiling at 1.11: the gap is 8 px on a ~136 px cell, so a bigger swell
  /// slides the tile under its neighbour instead of filling the gap.
  static const List<double> _tilePeaks = <double>[1.05, 1.07, 1.09, 1.11];

  static const List<double> _digitPeaks = <double>[1.35, 1.5, 1.65, 1.8];

  static Animatable<double> _popCurve(double peak) => TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.0,
        end: peak,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: peak,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 65,
    ),
  ]);

  static final Map<int, Animatable<double>> _tileCurves = {
    for (var level = 0; level <= maxLevel; level++)
      level: _popCurve(_tilePeaks[level]),
  };

  static final Map<int, Animatable<double>> _digitCurves = {
    for (var level = 0; level <= maxLevel; level++)
      level: _popCurve(_digitPeaks[level]),
  };

  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.locked) return;
    widget.onTap();
    _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final locked = widget.locked;
    final level = widget.level;

    Color background;
    Color foreground;
    if (level > 0) {
      background = widget.habitColor;
      foreground = Colors.white;
    } else {
      background = palette.isDark ? Palette.darkCard : const Color(0xFFF5F5F4);
      foreground = locked
          ? (palette.isDark ? const Color(0xFF78716C) : Palette.stone400)
          : (palette.isDark
                ? const Color(0xFFE7E5E4)
                : const Color(0xFF3A3935));
    }

    double opacity = 1;
    if (locked) {
      opacity = 0.3;
    } else if (level == 1) {
      opacity = 0.4;
    } else if (level == 2) {
      opacity = 0.75;
    }

    final borderColor = palette.isDark
        ? Palette.darkBorder
        : const Color(0xFFE7E5E4);

    final hoveredBackground = palette.isDark
        ? Palette.darkHover
        : const Color(0xFFE7E5E4);

    return MouseRegion(
      cursor: locked ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: locked ? null : (_) => setState(() => _hovering = true),
      onExit: locked ? null : (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: (_hovering && !locked) ? 1.04 : 1.0,
          duration: kHoverFade,
          curve: Curves.easeOut,
          // rebuilds on every tick of _pop; otherwise the pop never plays
          child: ListenableBuilder(
            listenable: _pop,
            builder: (context, _) {
              final tile = _tileCurves[level]!.transform(_pop.value);
              final digit = _digitCurves[level]!.transform(_pop.value);

              return Transform.scale(
                scale: tile,
                child: Opacity(
                  opacity: opacity,
                  child: AnimatedContainer(
                    duration: kHoverFade,
                    curve: Curves.easeOut,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (!locked && level == 0 && _hovering)
                          ? hoveredBackground
                          : background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: borderColor, width: 1.13),
                    ),
                    child: Transform.scale(
                      scale: digit,
                      child: Text(
                        '${widget.day}',
                        style: Styles.ui(
                          size: 14,
                          weight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
