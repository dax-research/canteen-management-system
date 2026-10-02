import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle _h(double size, {
    FontWeight w = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
  }) => GoogleFonts.poppins(
    fontSize: size, fontWeight: w, color: color, letterSpacing: letterSpacing);

  static TextStyle _b(double size, {
    FontWeight w = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? height,
  }) => GoogleFonts.dmSans(
    fontSize: size, fontWeight: w, color: color, height: height);

  // Display
  static TextStyle get displayLg  => _h(36, letterSpacing: -0.5);
  static TextStyle get displayMd  => _h(28);

  // Headings
  static TextStyle get h1 => _h(24);
  static TextStyle get h2 => _h(20);
  static TextStyle get h3 => _h(18);
  static TextStyle get h4 => _h(16);

  // Body
  static TextStyle get bodyLg => _b(16, height: 1.5);
  static TextStyle get bodyMd => _b(14, height: 1.5);
  static TextStyle get bodySm => _b(12, height: 1.4);

  // Labels
  static TextStyle get labelLg => _b(16, w: FontWeight.w600);
  static TextStyle get labelMd => _b(14, w: FontWeight.w600);
  static TextStyle get labelSm => _b(12, w: FontWeight.w500);

  // Helpers
  static TextStyle get caption         => _b(11, color: AppColors.textSecondary);
  static TextStyle get bodyMdSecondary => _b(14, color: AppColors.textSecondary, height: 1.5);
  static TextStyle get error           => _b(13, w: FontWeight.w500, color: AppColors.error);

  // Price
  static TextStyle get price      => _h(16, color: AppColors.primary);
  static TextStyle get priceTotal => _h(20, color: AppColors.primary);

  // On-dark variants
  static TextStyle get h1OnDark     => _h(24, color: AppColors.textOnDark);
  static TextStyle get h2OnDark     => _h(20, color: AppColors.textOnDark);
  static TextStyle get bodyMdOnDark => _b(14, color: const Color(0xCCFFFFFF), height: 1.5);
}
