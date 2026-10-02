import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_radius.dart';
export 'app_text_styles.dart';

abstract final class AppTheme {
  // Backward-compat
  static const Color primaryPurple = AppColors.primary;
  static const Color textDark      = AppColors.textPrimary;
  static const Color textLight     = AppColors.textSecondary;
  static const Color background    = AppColors.background;

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary:   AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.primaryDark,
        surface:   AppColors.surface,
        onSurface: AppColors.textPrimary,
        error:     AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      // ── Typography (Poppins headings + DM Sans body) ──────
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 36, fontWeight: FontWeight.w800,
          color: AppColors.textPrimary, letterSpacing: -0.5),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary, height: 1.5),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary, height: 1.5),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary, height: 1.4),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: AppColors.textOnPrimary, letterSpacing: 0.3),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
      ),

      // ── AppBar ─────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // ── Elevated Button ────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.shimmerBase,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),

      // ── Outlined Button ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Text Button ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Input ──────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.button,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        hintStyle: GoogleFonts.dmSans(
          fontSize: 14, color: AppColors.textHint),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 14, color: AppColors.textSecondary),
      ),

      // ── Card ───────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.divider, width: 0.8)),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Chip ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary),
        secondaryLabelStyle: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: Colors.white),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),

      // ── SnackBar ───────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.espresso,
        contentTextStyle: GoogleFonts.dmSans(
          fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Divider ────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider, thickness: 0.8, space: 0),

      // ── Bottom Navigation ──────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Progress Indicator ─────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryLight,
      ),
    );
  }
}
