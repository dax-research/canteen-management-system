import 'package:flutter/material.dart';

/// Warm coffee-shop colour palette inspired by the JavaGem reference design.
abstract final class AppColors {
  // ── Brand browns ────────────────────────────────────────────
  /// Primary warm brown — buttons, active states, highlights.
  static const Color primary = Color(0xFFC8956C);

  /// Darker brown for pressed states and headings.
  static const Color primaryDark = Color(0xFF8B5E3C);

  /// Richest espresso brown — used for dark sections.
  static const Color espresso = Color(0xFF3E2723);

  /// Light tint of primary for selected chips / backgrounds.
  static const Color primaryLight = Color(0xFFF5E6D8);

  // ── Backgrounds ─────────────────────────────────────────────
  /// Main scaffold background — warm off-white cream.
  static const Color background = Color(0xFFFAF6F1);

  /// Card / sheet surface — pure cream white.
  static const Color surface = Color(0xFFFFFFFF);

  /// Slightly elevated surface variant.
  static const Color surfaceVariant = Color(0xFFF5EDE4);

  /// Dark hero section background.
  static const Color heroDark = Color(0xFF1C1209);

  // ── Text ────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFF2C1810);
  static const Color textSecondary  = Color(0xFF7D5A4F);
  static const Color textHint       = Color(0xFFBCA99F);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);
  static const Color textOnDark     = Color(0xFFFFFFFF);

  // ── Semantic ────────────────────────────────────────────────
  static const Color success      = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning      = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error        = Color(0xFFE53935);
  static const Color errorLight   = Color(0xFFFFEBEE);

  // ── UI chrome ───────────────────────────────────────────────
  static const Color divider          = Color(0xFFEDE0D4);
  static const Color shimmerBase      = Color(0xFFEDE0D4);
  static const Color shimmerHighlight = Color(0xFFFAF6F1);
  static const Color overlay          = Color(0x99000000);
  static const Color starGold         = Color(0xFFFFB300);

  // ── Backward-compat aliases ─────────────────────────────────
  static const Color primaryPurple = primary;
  static const Color textDark      = textPrimary;
  static const Color textLight     = textSecondary;
}
