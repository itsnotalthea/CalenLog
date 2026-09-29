/// The red banner shown at the top of the window for recoverable errors.
library;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Transient error message. Sits above every screen and modal, fades in from
/// the top, and is dismissed by the controller after five seconds.
class ErrorBannerView extends StatelessWidget {
  const ErrorBannerView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, -24 * (1 - value)),
              child: child,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626), // red-600
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Styles.ui(size: 14, weight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
