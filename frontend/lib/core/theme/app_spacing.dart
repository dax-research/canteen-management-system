import 'package:flutter/material.dart';

/// Spacing scale for the application.
///
/// All padding, margin, gap, and SizedBox values should reference
/// constants from this class rather than hardcoded doubles.
///
/// Scale follows a base-4 system:
///   xs  =  4
///   sm  =  8
///   md  = 16
///   lg  = 24
///   xl  = 32
///   xxl = 48
///   xxxl= 64
abstract final class AppSpacing {
  // ── Raw values ─────────────────────────────────────────────
  static const double xs   =  4.0;
  static const double sm   =  8.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;

  // ── Pre-built EdgeInsets ───────────────────────────────────
  /// Uniform padding at each scale level.
  static const EdgeInsets paddingXs   = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm   = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd   = EdgeInsets.all(md);
  static const EdgeInsets paddingLg   = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl   = EdgeInsets.all(xl);

  /// Horizontal-only padding — useful for list tiles and cards.
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  /// Vertical-only padding.
  static const EdgeInsets verticalSm  = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd  = EdgeInsets.symmetric(vertical: md);

  /// Card inner padding — horizontal lg, vertical md.
  static const EdgeInsets card = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Screen / page horizontal padding (16 left + right).
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: md);

  // ── Pre-built SizedBox gaps ────────────────────────────────
  static const SizedBox gapXs  = SizedBox(height: xs);
  static const SizedBox gapSm  = SizedBox(height: sm);
  static const SizedBox gapMd  = SizedBox(height: md);
  static const SizedBox gapLg  = SizedBox(height: lg);
  static const SizedBox gapXl  = SizedBox(height: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl);

  static const SizedBox hGapXs  = SizedBox(width: xs);
  static const SizedBox hGapSm  = SizedBox(width: sm);
  static const SizedBox hGapMd  = SizedBox(width: md);
  static const SizedBox hGapLg  = SizedBox(width: lg);
}
