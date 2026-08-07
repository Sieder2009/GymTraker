import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radii.dart';

/// Sora for headings/big numbers, Inter for body text — same pairing as the
/// original's two Google Fonts (`app.css` / `index.html`).
class AppTheme {
  static ThemeData light({Color? accentOverride, Color? secondaryOverride}) => _build(
        _applyOverrides(AppColors.light, accentOverride, secondaryOverride),
        Brightness.light,
      );

  static ThemeData dark({Color? accentOverride, Color? secondaryOverride}) => _build(
        _applyOverrides(AppColors.dark, accentOverride, secondaryOverride),
        Brightness.dark,
      );

  static AppColors _applyOverrides(AppColors base, Color? accent, Color? secondary) {
    if (accent == null && secondary == null) return base;
    return base.copyWith(accent: accent, secondary: secondary);
  }

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      cardColor: colors.card,
      dividerColor: colors.line,
      splashFactory: NoSplash.splashFactory,
      textTheme: _textTheme(base.textTheme, colors),
      colorScheme: base.colorScheme.copyWith(
        brightness: brightness,
        surface: colors.card,
        onSurface: colors.txt,
        primary: colors.accent,
        onPrimary: Colors.white,
        secondary: colors.secondary,
        error: colors.yellow,
      ),
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bg,
        foregroundColor: colors.txt,
        elevation: 0,
        titleTextStyle: GoogleFonts.sora(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: colors.txt,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: colors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.card2,
        hintStyle: GoogleFonts.inter(color: colors.mut),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.card2,
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 14.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.card2,
          foregroundColor: colors.secondary,
          side: BorderSide(color: colors.secondary),
          textStyle: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 14.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.card,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.mut,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, AppColors colors) {
    return GoogleFonts.interTextTheme(base)
        .copyWith(
          headlineLarge: GoogleFonts.sora(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: colors.txt,
          ),
          headlineMedium: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: colors.txt,
          ),
          labelSmall: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: colors.mut,
          ),
        )
        .apply(bodyColor: colors.txt, displayColor: colors.txt);
  }
}
