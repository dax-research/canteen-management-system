import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';

/// A reusable network image widget backed by [CachedNetworkImage].
///
/// Features:
///  - Shimmer placeholder while loading
///  - Graceful error fallback (icon on grey background)
///  - Rounded clipping via [borderRadius]
///  - Configurable [fit], [width], [height]
///
/// Usage:
/// ```dart
/// AppNetworkImage(
///   imageUrl: foodItem.imageUrl,
///   width: 100,
///   height: 100,
///   borderRadius: AppRadius.card,
/// )
/// ```
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.card,
    this.fallbackIcon = Icons.fastfood_outlined,
    this.fallbackIconSize = 40.0,
  });

  /// Remote URL. If null or empty the fallback is shown immediately.
  final String? imageUrl;

  final double? width;
  final double? height;
  final BoxFit fit;

  /// Corner rounding applied via [ClipRRect].
  final BorderRadius borderRadius;

  /// Icon shown when the URL is absent or the image fails to load.
  final IconData fallbackIcon;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return ClipRRect(
      borderRadius: borderRadius,
      child: (url == null || url.isEmpty)
          ? _buildFallback()
          : CachedNetworkImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: fit,
              placeholder: (context, url) => _buildShimmer(),
              errorWidget: (context, url, error) => _buildFallback(),
            ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        color: AppColors.shimmerBase,
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceVariant,
      child: Icon(
        fallbackIcon,
        size: fallbackIconSize,
        color: AppColors.textHint,
      ),
    );
  }
}
