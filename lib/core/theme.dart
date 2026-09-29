/// Palette, typography and [ThemeData] for both light and dark mode.
library;

import 'package:flutter/material.dart';

class Palette {
  const Palette(this.isDark);

  final bool isDark;

  // Raw palette colours.
  static const Color notebook = Color(0xFFFDFBF7); // light background
  static const Color paperBorder = Color(0xFFE6E2D6); // light border
  static const Color inkDark = Color(0xFF3A3935); // light text
  static const Color darkBg = Color(0xFF16202B);
  static const Color darkBorder = Color(0xFF2A3A4D);
  static const Color darkCard = Color(0xFF1D2A3A);
  static const Color darkHover = Color(0xFF243447);
  static const Color creamText = Color(0xFFF5F2EB);

  static const Color stone800 = Color(0xFF292524);
  static const Color stone700 = Color(0xFF44403C);
  static const Color stone500 = Color(0xFF78716C);
  static const Color stone400 = Color(0xFFA8A29E);
  static const Color stone100 = Color(0xFFF5F5F4);

  Color get background => isDark ? darkBg : notebook;
  Color get text => isDark ? creamText : inkDark;
  Color get border => isDark ? darkBorder : paperBorder;
  Color get card => isDark ? darkCard : notebook;
  Color get hover => isDark ? darkHover : const Color(0xFFEFECE4);
  Color get mutedText => isDark ? stone400 : stone500;
  Color get subtleBorder => isDark ? darkBorder : const Color(0xFFD6D3D1);
  Color get inputBorder => isDark ? darkBorder : const Color(0xFFA8A29E);

  Color get buttonBg => isDark ? stone700 : stone800;
  Color get buttonHoverBg => isDark ? const Color(0xFF57534E) : stone700;
  Color get buttonFg => stone100;

  /// Lightness-only step of [base]; hover must not shift hue or saturation.
  Color hoverShade(Color base) {
    final hsl = HSLColor.fromColor(base);
    final shift = isDark ? 0.08 : -0.08;
    return hsl.withLightness((hsl.lightness + shift).clamp(0.0, 1.0)).toColor();
  }

  Color get panel => isDark
      ? Colors.white.withValues(alpha: 0.04)
      : Colors.black.withValues(alpha: 0.03);

  /// Translucent scrim behind modals ("stone-900/20" / "black/40").
  Color get scrim => isDark
      ? Colors.black.withValues(alpha: 0.40)
      : const Color(0xFF1C1917).withValues(alpha: 0.20);

  BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
    offset: const Offset(4, 4),
    blurRadius: 4,
  );

  double get hairline => 1.05;

  double get tileBorder => 1.13;
}

abstract final class Fonts {
  static const String title = 'SpaceMono';

  static const String ui = 'Inter';
}

abstract final class Styles {
  static TextStyle brand({required double size, required Color color}) =>
      TextStyle(
        fontFamily: Fonts.title,
        fontWeight: FontWeight.w700,
        fontSize: size,
        color: color,
        letterSpacing: -0.5,
        height: 1.1,
      );

  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: Fonts.title,
    fontWeight: weight,
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
  );

  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    FontStyle? style,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: Fonts.ui,
    fontWeight: weight,
    fontSize: size,
    color: color,
    fontStyle: style,
    letterSpacing: letterSpacing,
  );
}

ThemeData buildTheme(Palette palette) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.isDark ? Palette.darkBg : Palette.stone800,
        brightness: palette.isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        surface: palette.card,
        onSurface: palette.text,
        outline: palette.border,
        primary: palette.buttonBg,
        onPrimary: palette.buttonFg,
      );

  return ThemeData(
    useMaterial3: true,
    fontFamily: Fonts.ui,
    scaffoldBackgroundColor: palette.background,
    colorScheme: scheme,
    splashFactory: NoSplash.splashFactory,
    highlightColor: palette.hover,
    hoverColor: palette.hover,
    dividerColor: palette.border,
    focusColor: Colors.transparent,
    textTheme: TextTheme(
      bodyMedium: Styles.ui(color: palette.text),
      bodySmall: Styles.ui(size: 12, color: palette.mutedText),
      labelMedium: Styles.ui(size: 12, color: palette.mutedText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: Styles.ui(color: palette.mutedText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: palette.inputBorder,
          width: palette.hairline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(
          color: palette.inputBorder,
          width: palette.hairline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: palette.text, width: palette.hairline),
      ),
    ),
  );
}

Color colorFromHex(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 3) {
    value = value.split('').map((c) => '$c$c').join();
  }
  if (value.length != 6) return const Color(0xFF000000);
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return const Color(0xFF000000);
  return Color(0xFF000000 | parsed);
}

String hexFromColor(Color color) =>
    '#${color.toARGB32().toRadixString(16).substring(2)}';
