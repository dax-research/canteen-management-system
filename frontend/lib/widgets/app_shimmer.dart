import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';

/// Low-level shimmer wrapper.
///
/// Wraps any widget in a shimmer animation using the app's
/// shimmer colour palette. Prefer the higher-level skeleton
/// widgets below ([FoodCardSkeleton], [CategoryChipSkeleton], etc.)
/// unless you need a custom shape.
///
/// Usage:
/// ```dart
/// AppShimmer(
///   child: Container(
///     width: 120,
///     height: 20,
///     decoration: BoxDecoration(
///       color: AppColors.shimmerBase,
///       borderRadius: AppRadius.sm,
///     ),
///   ),
/// )
/// ```
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton building block
// ─────────────────────────────────────────────────────────────────────────────

/// A single shimmer rectangle — the basic building block for skeletons.
class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.sm,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: borderRadius,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Food card skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton placeholder that matches the shape of [FoodItemCard].
///
/// Use inside a [ListView] while the menu is loading:
/// ```dart
/// if (isLoading)
///   ListView.builder(
///     itemCount: 6,
///     itemBuilder: (_, __) => const FoodCardSkeleton(),
///   )
/// ```
class FoodCardSkeleton extends StatelessWidget {
  const FoodCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            _SkeletonBox(
              width: 100,
              height: 100,
              borderRadius: BorderRadius.only(
                topLeft: AppRadius.radiusCard,
                bottomLeft: AppRadius.radiusCard,
              ),
            ),
            // Text placeholders
            Expanded(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SkeletonBox(width: double.infinity, height: 16),
                    AppSpacing.gapSm,
                    const _SkeletonBox(width: 160, height: 12),
                    AppSpacing.gapSm,
                    const _SkeletonBox(width: 100, height: 12),
                    AppSpacing.gapMd,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _SkeletonBox(width: 60, height: 12),
                        _SkeletonBox(
                          width: 60,
                          height: 28,
                          borderRadius: AppRadius.full,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chip skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton for a single category chip in the horizontal filter bar.
class CategoryChipSkeleton extends StatelessWidget {
  const CategoryChipSkeleton({super.key, this.width = 72});

  final double width;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: _SkeletonBox(
          width: width,
          height: 32,
          borderRadius: AppRadius.full,
        ),
      ),
    );
  }
}

/// A full row of [CategoryChipSkeleton]s for the category filter bar.
class CategoryBarSkeleton extends StatelessWidget {
  const CategoryBarSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        itemCount: count,
        itemBuilder: (_, index) => CategoryChipSkeleton(
          // Vary widths slightly for a natural look.
          width: 60.0 + (index % 3) * 16.0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order list skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton for a single order list tile.
class OrderTileSkeleton extends StatelessWidget {
  const OrderTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const _SkeletonBox(
              width: 48,
              height: 48,
              borderRadius: AppRadius.sm,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonBox(width: double.infinity, height: 14),
                  AppSpacing.gapSm,
                  const _SkeletonBox(width: 120, height: 12),
                ],
              ),
            ),
            AppSpacing.hGapMd,
            const _SkeletonBox(width: 56, height: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile data skeleton
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton for a profile header (avatar + name + email).
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.shimmerBase,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SkeletonBox(width: 140, height: 16),
                  AppSpacing.gapSm,
                  const _SkeletonBox(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
