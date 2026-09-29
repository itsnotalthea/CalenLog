/// Hand-rolled HSV colour picker: wheel, value bar, hex readout.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class ColorWheel extends StatefulWidget {
  const ColorWheel({super.key, required this.initial, required this.onChanged});

  final Color initial;

  final ValueChanged<Color> onChanged;

  @override
  State<ColorWheel> createState() => _ColorWheelState();
}

class _ColorWheelState extends State<ColorWheel> {
  /// Smaller than the modal so a 500 px-tall window still fits the picker.
  static const double wheelSize = 168;

  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  void _set(HSVColor next) {
    if (next == _hsv) return;
    setState(() => _hsv = next);
    widget.onChanged(next.toColor());
  }

  void _onWheel(Offset local) {
    final center = Offset(wheelSize / 2, wheelSize / 2);
    final radius = wheelSize / 2;
    final delta = local - center;

    final hue = (math.atan2(delta.dy, delta.dx) * 180 / math.pi + 360) % 360;
    final saturation = (delta.distance / radius).clamp(0.0, 1.0);
    _set(_hsv.withHue(hue).withSaturation(saturation));
  }

  void _onValueBar(Offset local, double width) {
    if (width <= 0) return;
    _set(_hsv.withValue((local.dx / width).clamp(0.0, 1.0)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette(Theme.of(context).brightness == Brightness.dark);
    final color = _hsv.toColor();
    final borderColor = palette.isDark
        ? Palette.darkBorder
        : const Color(0xFFA8A29E);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // onPan (not onTap) so a click moves the marker too
              onPanDown: (details) => _onWheel(details.localPosition),
              onPanUpdate: (details) => _onWheel(details.localPosition),
              child: SizedBox(
                width: wheelSize,
                height: wheelSize,
                child: CustomPaint(painter: _WheelPainter(_hsv)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (details) =>
                  _onValueBar(details.localPosition, constraints.maxWidth),
              onPanUpdate: (details) =>
                  _onValueBar(details.localPosition, constraints.maxWidth),
              child: SizedBox(
                width: constraints.maxWidth,
                height: 18,
                child: CustomPaint(painter: _ValueBarPainter(_hsv)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 34,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: borderColor, width: palette.hairline),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              hexFromColor(color),
              style: TextStyle(
                fontFamily: Fonts.title,
                fontSize: 14,
                color: palette.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Offset _markerFor(HSVColor hsv, Offset center, double radius) {
  final angle = hsv.hue * math.pi / 180;
  return center +
      Offset(math.cos(angle), math.sin(angle)) * (hsv.saturation * radius);
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.hsv);

  final HSVColor hsv;

  /// 36 steps around the ring: dense enough that the sweep shows no banding.
  static final List<Color> _hueRing = List<Color>.generate(37, (i) {
    final hue = (i * 10.0) % 360;
    return HSVColor.fromAHSV(1, hue, 1, 1).toColor();
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Offset.zero & size;
    final disc = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.clipPath(disc);

    // SweepGradient runs 0 → 2π from 3 o'clock, matching the atan2 below
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: _hueRing,
          startAngle: 0,
          endAngle: 2 * math.pi,
        ).createShader(rect),
    );

    // white at alpha (1 − s) over the hue gives HSV(h, s, 1); fading to
    // Colors.transparent instead would grey out the rim
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect),
    );

    // black at alpha (1 − v) scales every channel by v, previewing the result
    if (hsv.value < 1) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.black.withValues(alpha: 1 - hsv.value),
      );
    }
    canvas.restore();

    final marker = _markerFor(hsv, center, radius);
    canvas.drawCircle(
      marker,
      8.5,
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawCircle(marker, 7, Paint()..color = Colors.white);
    canvas.drawCircle(marker, 5, Paint()..color = hsv.toColor());
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.hsv.hue != hsv.hue ||
      old.hsv.saturation != hsv.saturation ||
      old.hsv.value != hsv.value;
}

class _ValueBarPainter extends CustomPainter {
  _ValueBarPainter(this.hsv);

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF000000),
            HSVColor.fromAHSV(1, hsv.hue, hsv.saturation, 1).toColor(),
          ],
        ).createShader(rect),
    );

    final knob = Offset(
      (size.width * hsv.value).clamp(9.0, size.width - 9.0),
      size.height / 2,
    );
    canvas.drawCircle(
      knob,
      8,
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawCircle(knob, 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(knob, 4.5, Paint()..color = hsv.toColor());
  }

  @override
  bool shouldRepaint(_ValueBarPainter old) => old.hsv != hsv;
}
