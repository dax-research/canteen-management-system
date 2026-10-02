import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../models/food_item.dart';
import '../services/cart_service.dart';
import 'app_network_image.dart';

class FoodItemCard extends StatefulWidget {
  const FoodItemCard({super.key, required this.foodItem});
  final FoodItem foodItem;
  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  bool _adding = false;

  Future<void> _add() async {
    if (_adding || !widget.foodItem.isAvailable) return;
    setState(() => _adding = true);
    try {
      await CartService.addItem(widget.foodItem.id, 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('${widget.foodItem.name} added to cart',
                      overflow: TextOverflow.ellipsis)),
            ]),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.foodItem;
    final unavail = !item.isAvailable;

    return Opacity(
      opacity: unavail ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A2C1810),
                blurRadius: 12,
                offset: Offset(0, 4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Image ─────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: AppNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 108,
                    height: 108,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.zero,
                    fallbackIcon: Icons.fastfood_rounded,
                    fallbackIconSize: 32,
                  ),
                ),
                if (unavail)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('SOLD OUT',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Info ──────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(item.categoryName,
                          style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),

                    // Name
                    Text(item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.2)),

                    // Description
                    if (item.description != null &&
                        item.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(item.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],

                    const SizedBox(height: 4),
                    // Stars (decorative — 4.5 static for aesthetics)
                    Row(
                      children: [
                        ...List.generate(
                            4,
                            (_) => const Icon(Icons.star_rounded,
                                color: AppColors.starGold, size: 12)),
                        const Icon(Icons.star_half_rounded,
                            color: AppColors.starGold, size: 12),
                        const SizedBox(width: 3),
                        const Text('4.5',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary),
                        ),
                        if (!unavail) _AddBtn(adding: _adding, onTap: _add),
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

class _AddBtn extends StatelessWidget {
  const _AddBtn({required this.adding, required this.onTap});
  final bool adding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: adding ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: adding ? AppColors.primaryLight : AppColors.primary,
          borderRadius: AppRadius.sm,
          boxShadow: adding
              ? null
              : [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
        ),
        child: adding
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary))
            : const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
