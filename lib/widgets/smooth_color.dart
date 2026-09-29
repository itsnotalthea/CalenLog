/// A colour that eases to its new value instead of snapping.
library;

import 'package:flutter/material.dart';

const Duration kHoverFade = Duration(milliseconds: 150);

/// Rebuilds its child with [color] eased towards whatever it was last frame.
class SmoothColor extends StatefulWidget {
  const SmoothColor({
    super.key,
    required this.color,
    required this.builder,
    this.duration = kHoverFade,
    this.curve = Curves.easeOut,
  });

  final Color color;

  final Widget Function(BuildContext context, Color color) builder;

  final Duration duration;

  final Curve curve;

  @override
  State<SmoothColor> createState() => _SmoothColorState();
}

class _SmoothColorState extends State<SmoothColor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Both ends are non-null, so [ColorTween.transform] never returns null.
  late ColorTween _tween;

  Color get _current =>
      _tween.transform(widget.curve.transform(_controller.value)) ??
      widget.color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _tween = ColorTween(begin: widget.color, end: widget.color);
  }

  @override
  void didUpdateWidget(covariant SmoothColor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.color != widget.color) {
      // Start from wherever the previous transition got to, so repeated
      // hovers interrupt cleanly instead of jumping back to the base colour.
      _tween = ColorTween(begin: _current, end: widget.color);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(context, _current),
  );
}
