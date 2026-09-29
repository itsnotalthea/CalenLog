/// Splash screen: wordmark held two seconds before the title morph.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.authTitleKey,
    required this.onMorph,
  });

  final GlobalKey authTitleKey;

  /// Called once with `splashRect.topLeft - authRect.topLeft`.
  final ValueChanged<Offset> onMorph;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GlobalKey _titleKey = GlobalKey();

  Timer? _timer;
  bool _fired = false;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _finish);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish() {
    if (_fired || !mounted) return;

    final splashBox =
        _titleKey.currentContext?.findRenderObject() as RenderBox?;
    final authBox =
        widget.authTitleKey.currentContext?.findRenderObject() as RenderBox?;

    // Both wordmarks must be laid out before the delta can be measured; retry
    // next frame and give up after a few attempts.
    final ready =
        splashBox != null &&
        authBox != null &&
        splashBox.hasSize &&
        authBox.hasSize;
    if (!ready) {
      if (++_attempts > 5) {
        _fired = true;
        widget.onMorph(Offset.zero); // no morph, but still leave the splash
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return;
    }

    _fired = true;
    final splashTopLeft = splashBox.localToGlobal(Offset.zero);
    final authTopLeft = authBox.localToGlobal(Offset.zero);
    widget.onMorph(splashTopLeft - authTopLeft);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette(Theme.of(context).brightness == Brightness.dark);
    final subtitleColor = palette.isDark
        ? Palette.stone400
        : const Color(0xFF57534E); // stone-600

    return ColoredBox(
      color: palette.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CalenLog',
              key: _titleKey,
              textDirection: TextDirection.ltr,
              style: Styles.brand(size: 48, color: palette.text),
            ),
            const SizedBox(height: 12),
            Text(
              Messages.splashSubtitle,
              style: Styles.ui(size: 14, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}
