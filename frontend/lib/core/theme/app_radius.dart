import 'package:flutter/material.dart';

/// Border-radius constants for the application.
///
/// Usage:
///   ClipRRect(borderRadius: AppRadius.card, ...)
///   RoundedRectangleBorder(borderRadius: AppRadius.button)
///   Container(decoration: BoxDecoration(borderRadius: AppRadius.image))
abstract final class AppRadius {
  // ── Raw doubles ────────────────────────────────────────────
  static const double _xs  =  4.0;
  static const double _sm  =  8.0;
  static const double _md  = 12.0;
  static const double _lg  = 16.0;
  static const double _xl  = 20.0;
  static const double _xxl = 24.0;

  // ── BorderRadius ───────────────────────────────────────────
  /// Tiny rounding — tags, small chips.
  static const BorderRadius xs  = BorderRadius.all(Radius.circular(_xs));

  /// Small rounding — input fields, small buttons.
  static const BorderRadius sm  = BorderRadius.all(Radius.circular(_sm));

  /// Medium rounding — search bars, secondary cards.
  static const BorderRadius md  = BorderRadius.all(Radius.circular(_md));

  /// Card rounding — food item cards, category cards.
  static const BorderRadius card = BorderRadius.all(Radius.circular(_lg));

  /// Button rounding — primary CTA buttons.
  static const BorderRadius button = BorderRadius.all(Radius.circular(_lg));

  /// Large rounding — bottom sheets, image thumbnails.
  static const BorderRadius lg  = BorderRadius.all(Radius.circular(_xl));

  /// Extra-large rounding — hero image containers.
  static const BorderRadius xl  = BorderRadius.all(Radius.circular(_xxl));

  /// Full pill / stadium rounding — quantity chips, filter pills.
  static const BorderRadius full = BorderRadius.all(Radius.circular(100));

  // ── Radius values (for ClipRRect etc.) ────────────────────
  static const Radius radiusCard   = Radius.circular(_lg);
  static const Radius radiusButton = Radius.circular(_lg);
  static const Radius radiusFull   = Radius.circular(100);

  // ── Mixed — top-only for bottom sheets ────────────────────
  static const BorderRadius topLg = BorderRadius.only(
    topLeft:  Radius.circular(_xl),
    topRight: Radius.circular(_xl),
  );
}
