/// Every modal the app can show, plus the shared shell they all use.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import 'color_wheel.dart';
import 'smooth_color.dart';

/// Blurred scrim and centred card with a 300 ms scale/fade entry. The scrim
/// absorbs taps instead of dismissing; only Cancel/Close close the modal.
class ModalShell extends StatelessWidget {
  const ModalShell({
    super.key,
    required this.width,
    required this.isDark,
    required this.child,
  });

  final double width;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(isDark);

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: ColoredBox(color: palette.scrim),
          ),
        ),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.95 + 0.05 * value, child: child),
            ),
            child: Container(
              width: width,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: palette.border, width: 1.05),
                boxShadow: [palette.cardShadow],
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class ModalTitle extends StatelessWidget {
  const ModalTitle(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(Theme.of(context).brightness == Brightness.dark);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Styles.ui(
        size: 20,
        weight: FontWeight.w700,
        color: color ?? palette.text,
      ),
    );
  }
}

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background,
    this.hoverBackground,
  });

  final String label;
  final VoidCallback onPressed;
  final Color? background;
  final Color? hoverBackground;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(Theme.of(context).brightness == Brightness.dark);
    final base = widget.background ?? palette.buttonBg;
    final hover = widget.hoverBackground ?? palette.buttonHoverBg;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: kHoverFade,
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? hover : base,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            style: Styles.ui(size: 14, color: palette.buttonFg),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatefulWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(Theme.of(context).brightness == Brightness.dark);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: kHoverFade,
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? palette.hover : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: palette.isDark
                  ? Palette.darkBorder
                  : const Color(0xFFA8A29E),
              width: 1.05,
            ),
          ),
          child: Text(
            widget.label,
            style: Styles.ui(size: 14, color: palette.text),
          ),
        ),
      ),
    );
  }
}

class OptionsModal extends StatelessWidget {
  const OptionsModal({
    super.key,
    required this.isDark,
    required this.onChangePassword,
    required this.onToggleDarkMode,
    required this.onReset,
    required this.onClose,
  });

  final bool isDark;
  final VoidCallback onChangePassword;
  final VoidCallback onToggleDarkMode;
  final VoidCallback onReset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(isDark);

    return ModalShell(
      width: 380,
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalTitle(Messages.optionsTitle),
          const SizedBox(height: 24),
          _OptionRow(
            label: 'Change Password',
            icon: Icons.key,
            palette: palette,
            onTap: onChangePassword,
          ),
          const SizedBox(height: 12),
          _OptionRow(
            label: 'Dark Mode: ${isDark ? 'On' : 'Off'}',
            icon: Icons.dark_mode,
            palette: palette,
            onTap: onToggleDarkMode,
          ),
          const SizedBox(height: 12),
          _OptionRow(
            label: Messages.resetTitle,
            icon: Icons.restart_alt,
            palette: palette,
            destructive: true,
            onTap: onReset,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: Messages.closeButton,
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatefulWidget {
  const _OptionRow({
    required this.label,
    required this.icon,
    required this.palette,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final Palette palette;
  final VoidCallback onTap;
  final bool destructive;

  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final red = palette.isDark
        ? const Color(0xFFF87171)
        : const Color(0xFFDC2626);

    final border = widget.destructive
        ? (palette.isDark ? const Color(0x80B91C1C) : const Color(0xFFFCA5A5))
        : (palette.isDark ? Palette.darkBorder : const Color(0xFFD6D3D1));

    // hover stays a shade of the card; the red lives in the border and label
    final background = _hovered
        ? palette.hoverShade(palette.card)
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: kHoverFade,
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: 1.05),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: Styles.ui(
                  size: 14,
                  color: widget.destructive
                      ? red
                      : (palette.isDark
                            ? const Color(0xFFE7E5E4)
                            : palette.text),
                ),
              ),
              Icon(
                widget.icon,
                size: 16,
                color: widget.destructive
                    ? const Color(0xFFF87171)
                    : palette.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryModal extends StatefulWidget {
  const CategoryModal({
    super.key,
    required this.isDark,
    required this.title,
    required this.initialName,
    required this.initialColor,
    required this.onCancel,
    required this.onSave,
  });

  final bool isDark;
  final String title;
  final String initialName;
  final String initialColor;
  final VoidCallback onCancel;
  final void Function(String name, String color) onSave;

  @override
  State<CategoryModal> createState() => _CategoryModalState();
}

class _CategoryModalState extends State<CategoryModal> {
  late final TextEditingController _name;

  late String _color;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _color = widget.initialColor;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette(widget.isDark);

    return ModalShell(
      width: 400,
      isDark: widget.isDark,
      // The wheel needs vertical room; at the 500 px window minimum the modal
      // scrolls instead of clipping.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height - 128,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ModalTitle(widget.title),
              const SizedBox(height: 20),
              TextField(
                controller: _name,
                maxLength: 40,
                textAlign: TextAlign.center,
                style: Styles.ui(size: 14, color: const Color(0xFFE7E5E4)),
                onSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  hintText: Messages.categoryNameHint,
                  hintStyle: Styles.ui(size: 14, color: palette.mutedText),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  Messages.categoryColorLabel,
                  style: Styles.ui(size: 12, color: palette.mutedText),
                ),
              ),
              const SizedBox(height: 8),
              ColorWheel(
                initial: colorFromHex(_color),
                onChanged: (color) =>
                    setState(() => _color = hexFromColor(color)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: Messages.cancelButton,
                      onPressed: widget.onCancel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      label: Messages.saveButton,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    widget.onSave(_name.text.trim(), _color);
  }
}

class DeleteHabitModal extends StatelessWidget {
  const DeleteHabitModal({
    super.key,
    required this.isDark,
    required this.text,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool isDark;
  final String text;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(isDark);

    return ModalShell(
      width: 380,
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalTitle(Messages.deleteHabitTitle),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Styles.ui(size: 14, color: palette.mutedText),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: Messages.cancelButton,
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: Messages.deleteButton,
                  background: const Color(0xFFDC2626),
                  hoverBackground: const Color(0xFFDE4242),
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ResetModal extends StatelessWidget {
  const ResetModal({
    super.key,
    required this.isDark,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(isDark);

    return ModalShell(
      width: 380,
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalTitle(Messages.resetTitle, color: Color(0xFFDC2626)),
          const SizedBox(height: 12),
          Text(
            Messages.resetBody,
            textAlign: TextAlign.center,
            style: Styles.ui(size: 14, color: palette.mutedText),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: Messages.cancelButton,
                  onPressed: onCancel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: Messages.resetButton,
                  background: const Color(0xFFDC2626),
                  hoverBackground: const Color(0xFFDE4242),
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimeLockModal extends StatelessWidget {
  const TimeLockModal({
    super.key,
    required this.isDark,
    required this.message,
    required this.onDismiss,
  });

  final bool isDark;
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = Palette(isDark);

    return ModalShell(
      width: 380,
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Styles.ui(size: 14, color: palette.mutedText),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: Messages.gotItButton,
              onPressed: onDismiss,
            ),
          ),
        ],
      ),
    );
  }
}

class ChangePasswordModal extends StatefulWidget {
  const ChangePasswordModal({
    super.key,
    required this.isDark,
    required this.onCancel,
    required this.onUpdate,
  });

  final bool isDark;
  final VoidCallback onCancel;
  final Future<bool> Function(String current, String next) onUpdate;

  @override
  State<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<ChangePasswordModal> {
  final TextEditingController _current = TextEditingController();
  final TextEditingController _next = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await widget.onUpdate(_current.text, _next.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) widget.onCancel(); // matches closePasswordModal() on success
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette(widget.isDark);

    return ModalShell(
      width: 400,
      isDark: widget.isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalTitle(Messages.changePasswordTitle),
          const SizedBox(height: 24),
          TextField(
            controller: _current,
            obscureText: true,
            maxLength: 64,
            textAlign: TextAlign.center,
            style: Styles.ui(size: 14, color: palette.text),
            decoration: InputDecoration(
              hintText: Messages.oldPasswordHint,
              hintStyle: Styles.ui(size: 14, color: palette.mutedText),
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _next,
            obscureText: true,
            maxLength: 64,
            textAlign: TextAlign.center,
            style: Styles.ui(size: 14, color: palette.text),
            onSubmitted: (_) => _update(),
            decoration: InputDecoration(
              hintText: Messages.newPasswordHint,
              hintStyle: Styles.ui(size: 14, color: palette.mutedText),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: Messages.cancelButton,
                  onPressed: widget.onCancel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: Messages.updateButton,
                  onPressed: _update,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
