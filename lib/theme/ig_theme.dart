import 'package:flutter/material.dart';

/// Dark surfaces, fine dividers and restrained Instagram-blue accents from the
/// supplied UI kit.
class IgColors {
  IgColors._();

  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceHigh = Color(0xFF1C1C1C);
  static const Color divider = Color(0xFF262626);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA8A8A8);
  static const Color textTertiary = Color(0xFF8E8E8E);
  static const Color blue = Color(0xFF0095F6);
  static const Color red = Color(0xFFED4956);
  static const Color online = Color(0xFF1CD14F);
  static const Color bubbleIn = Color(0xFF262626);
  static const Color mediaPlaceholder = Color(0xFF121212);

  static const LinearGradient storyRing = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: <Color>[
      Color(0xFFFBAA47),
      Color(0xFFD91A46),
      Color(0xFFA60F93),
    ],
  );

  static const LinearGradient sentBubble = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[Color(0xFF833AB4), Color(0xFF405DE6)],
  );

  static const LinearGradient reelScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0x66000000),
      Color(0x00000000),
      Color(0xCC000000),
    ],
    stops: <double>[0.0, 0.42, 1.0],
  );

  static const LinearGradient bottomFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0x00000000), Color(0x99000000)],
  );
}

class IgText {
  IgText._();

  static TextStyle wordmark({double size = 34}) => TextStyle(
    fontFamily: 'Billabong',
    fontSize: size,
    color: IgColors.textPrimary,
    height: 1.06,
  );

  static TextStyle body({
    double size = 14,
    Color color = IgColors.textPrimary,
    FontWeight weight = FontWeight.w400,
    double height = 1.34,
  }) =>
      TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  static TextStyle medium(
      {double size = 14, Color color = IgColors.textPrimary}) =>
      body(size: size, color: color, weight: FontWeight.w500);

  static TextStyle semibold(
      {double size = 13.5, Color color = IgColors.textPrimary}) =>
      body(size: size, color: color, weight: FontWeight.w600);

  static TextStyle bold(
      {double size = 14, Color color = IgColors.textPrimary}) =>
      body(size: size, color: color, weight: FontWeight.w700);
}

class IgTheme {
  IgTheme._();

  static ThemeData dark() {
    final ThemeData base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: false,
      fontFamily: null,
    );

    return base.copyWith(
      scaffoldBackgroundColor: IgColors.bg,
      canvasColor: IgColors.bg,
      dividerColor: IgColors.divider,
      colorScheme: const ColorScheme.dark(
        primary: IgColors.textPrimary,
        onPrimary: IgColors.bg,
        secondary: IgColors.blue,
        onSecondary: Colors.white,
        surface: IgColors.surface,
        onSurface: IgColors.textPrimary,
        error: IgColors.red,
      ),
      iconTheme: const IconThemeData(color: IgColors.textPrimary, size: 24),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: IgColors.surface,
        modalBackgroundColor: IgColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        isDense: true,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: IgColors.bg,
        foregroundColor: IgColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: IgColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
