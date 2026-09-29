/// The left-hand habit list and its footer actions.
library;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/habit.dart';
import 'smooth_color.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.habits,
    required this.activeHabitId,
    required this.isDark,
    required this.onSelect,
    required this.onEdit,
    required this.onAdd,
    required this.onDelete,
    required this.onOptions,
    required this.onExit,
  });

  final List<Habit> habits;
  final String activeHabitId;
  final bool isDark;
  final ValueChanged<Habit> onSelect;
  final ValueChanged<Habit> onEdit;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onOptions;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(isDark);

    return Container(
      width: 192, // w-48
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: palette.border, width: palette.hairline),
        boxShadow: [palette.cardShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 20, 12),
              child: Column(
                children: [
                  for (var i = 0; i < habits.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _HabitRow(
                      habit: habits[i],
                      selected: habits[i].id == activeHabitId,
                      palette: palette,
                      onTap: () => onSelect(habits[i]),
                      onEdit: () => onEdit(habits[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Footer, bled to the box edges.
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _IconActionButton(
                      icon: Icons.delete_outline,
                      size: 16,
                      tooltip: 'Delete selected habit',
                      color: palette.mutedText,
                      palette: palette,
                      onTap: onDelete,
                    ),
                    _IconActionButton(
                      icon: Icons.add,
                      size: 20,
                      tooltip: 'Add habit (max 15)',
                      color: palette.mutedText,
                      palette: palette,
                      onTap: onAdd,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _FooterAction(
                  icon: Icons.settings,
                  label: 'Options',
                  color: palette.mutedText,
                  palette: palette,
                  onTap: onOptions,
                ),
                const SizedBox(height: 2),
                _FooterAction(
                  icon: Icons.logout,
                  label: 'Exit Program',
                  color: const Color(0xFFEF4444),
                  palette: palette,
                  onTap: onExit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatefulWidget {
  const _HabitRow({
    required this.habit,
    required this.selected,
    required this.palette,
    required this.onTap,
    required this.onEdit,
  });

  final Habit habit;
  final bool selected;
  final Palette palette;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  State<_HabitRow> createState() => _HabitRowState();
}

class _HabitRowState extends State<_HabitRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final habit = widget.habit;
    final selected = widget.selected;

    Color? background;
    if (selected) {
      background = palette.isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04);
    } else if (_hovered) {
      background = palette.isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03);
    }

    final textColor = selected
        ? colorFromHex(habit.color)
        : (palette.isDark ? Palette.stone400 : const Color(0xFF57534E));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onEdit,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: kHoverFade,
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // Habit names use the primary face.
                  style: Styles.mono(
                    size: 14,
                    weight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _hovered ? 1 : 0,
                duration: kHoverFade,
                curve: Curves.easeOut,
                child: IconButton(
                  onPressed: widget.onEdit,
                  tooltip: 'Edit habit',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
                  icon: Icon(
                    Icons.edit,
                    size: 14,
                    color: palette.isDark
                        ? Palette.stone400
                        : const Color(0xFFA8A29E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconActionButton extends StatefulWidget {
  const _IconActionButton({
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.color,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final String tooltip;
  final Color color;
  final Palette palette;
  final VoidCallback onTap;

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (value) => setState(() => _hovered = value),
        borderRadius: BorderRadius.circular(4),
        // Material's default 50 ms highlight has to match kHoverFade, or the
        // hover reads as two separate changes.
        hoverDuration: kHoverFade,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: SmoothColor(
            color: _hovered
                ? widget.palette.hoverShade(widget.color)
                : widget.color,
            builder: (context, color) =>
                Icon(widget.icon, size: widget.size, color: color),
          ),
        ),
      ),
    );
  }
}

class _FooterAction extends StatefulWidget {
  const _FooterAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Palette palette;
  final VoidCallback onTap;

  @override
  State<_FooterAction> createState() => _FooterActionState();
}

class _FooterActionState extends State<_FooterAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return InkWell(
      onTap: widget.onTap,
      onHover: (value) => setState(() => _hovered = value),
      borderRadius: BorderRadius.circular(4),
      hoverDuration: kHoverFade,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            SmoothColor(
              color: _hovered ? palette.hoverShade(widget.color) : widget.color,
              builder: (context, color) =>
                  Icon(widget.icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            SmoothColor(
              color: _hovered ? palette.hoverShade(widget.color) : widget.color,
              builder: (context, color) =>
                  Text(widget.label, style: Styles.ui(size: 12, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
