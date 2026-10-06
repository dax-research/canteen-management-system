  import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/cart.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../widgets/app_network_image.dart';

class _CheckoutChoice {
  const _CheckoutChoice({
    required this.pickupTime,
    required this.etaMinutes,
    required this.paymentMethod,
  });

  final String pickupTime;
  final int etaMinutes;
  final String paymentMethod;
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Cart? _cart;
  bool _loading = true;
  bool _mutating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await CartService.getCart();
      if (mounted) {
        setState(() {
          _cart = c;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _mutate(Future<Cart> Function() fn) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      final c = await fn();
      if (mounted) {
        setState(() {
          _cart = c;
          _mutating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _mutating = false);
        _snack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _clearCart() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: const Text(
          'Clear cart?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'All items will be removed.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) await _mutate(CartService.clearCart);
  }

  Future<void> _checkout() async {
    if (_cart == null || _cart!.items.isEmpty || _mutating) return;

    final choice = await showDialog<_CheckoutChoice>(
      context: context,
      builder: (ctx) => const _CheckoutDialog(),
    );

    if (choice == null) return;

    setState(() => _mutating = true);
    try {
      final order = await OrderService.placeOrder(
        orderType: 'PICKUP',
        pickupTime: choice.pickupTime,
        etaMinutes: choice.etaMinutes,
        paymentMethod: choice.paymentMethod,
      );
      if (mounted) {
        setState(() {
          _cart = Cart(id: _cart!.id, items: [], total: 0.0);
          _mutating = false;
        });
        context.push('${AppPaths.orders}/${order.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _mutating = false);
        _snack(e.toString().replaceAll('Exception: ', ''), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        actions: [
          if (_cart != null && _cart!.items.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.error,
              ),
              onPressed: _mutating ? null : _clearCart,
            ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load cart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_cart == null || _cart!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 46,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add some items from the menu',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(AppPaths.home),
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: const Text('Browse Menu'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            if (_mutating)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                itemCount: _cart!.items.length,
                itemBuilder: (_, i) => _CartTile(
                  item: _cart!.items[i],
                  disabled: _mutating,
                  onMinus: (id, qty) => qty <= 1
                      ? _mutate(() => CartService.removeItem(id))
                      : _mutate(() => CartService.updateItem(id, qty - 1)),
                  onPlus: (id, qty) =>
                      _mutate(() => CartService.updateItem(id, qty + 1)),
                  onRemove: (id) => _mutate(() => CartService.removeItem(id)),
                ),
              ),
            ),
            _CheckoutBar(
              total: _cart!.total,
              count: _cart!.items.fold(0, (s, i) => s + i.quantity),
              loading: _mutating,
              onCheckout: _checkout,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog();

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  static const _slots = [
    _CheckoutChoice(pickupTime: 'ASAP', etaMinutes: 15, paymentMethod: 'CASH'),
    _CheckoutChoice(
      pickupTime: '12:30 PM',
      etaMinutes: 20,
      paymentMethod: 'CASH',
    ),
    _CheckoutChoice(
      pickupTime: '1:00 PM',
      etaMinutes: 25,
      paymentMethod: 'CASH',
    ),
    _CheckoutChoice(
      pickupTime: '1:30 PM',
      etaMinutes: 30,
      paymentMethod: 'CASH',
    ),
    _CheckoutChoice(
      pickupTime: '2:00 PM',
      etaMinutes: 35,
      paymentMethod: 'CASH',
    ),
  ];

  String _pickupTime = 'ASAP';
  int _etaMinutes = 15;
  String _paymentMethod = 'CASH';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      title: const Text(
        'Choose payment & pickup',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment method',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              _PaymentChoiceTile(
                title: 'Cash on pickup',
                subtitle: 'Pay at the counter when collecting.',
                selected: _paymentMethod == 'CASH',
                onTap: () => setState(() => _paymentMethod = 'CASH'),
              ),
              _PaymentChoiceTile(
                title: 'Online payment (demo)',
                subtitle: 'Simulated payment only; no real charge is made.',
                selected: _paymentMethod == 'MOCK_ONLINE',
                onTap: () => setState(() => _paymentMethod = 'MOCK_ONLINE'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pickup time',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _pickupTime,
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: _slots
                    .map(
                      (slot) => DropdownMenuItem(
                        value: slot.pickupTime,
                        child: Text(
                          '${slot.pickupTime}  ·  ${slot.etaMinutes} min',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final slot = _slots.firstWhere(
                    (item) => item.pickupTime == value,
                  );
                  setState(() {
                    _pickupTime = slot.pickupTime;
                    _etaMinutes = slot.etaMinutes;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _CheckoutChoice(
              pickupTime: _pickupTime,
              etaMinutes: _etaMinutes,
              paymentMethod: _paymentMethod,
            ),
          ),
          child: const Text('Place order'),
        ),
      ],
    );
  }
}

class _PaymentChoiceTile extends StatelessWidget {
  const _PaymentChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({
    required this.item,
    required this.disabled,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  final CartItem item;
  final bool disabled;
  final void Function(String, int) onMinus;
  final void Function(String, int) onPlus;
  final void Function(String) onRemove;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isAvailable ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A2C1810),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: AppNetworkImage(
                imageUrl: item.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
                fallbackIcon: Icons.fastfood_rounded,
                fallbackIconSize: 26,
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: disabled ? null : () => onRemove(item.id),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹${item.unitPrice.toStringAsFixed(2)} each',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!item.isAvailable)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Currently unavailable',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Stepper(
                            qty: item.quantity,
                            onMinus: disabled
                                ? null
                                : () => onMinus(item.id, item.quantity),
                            onPlus: disabled
                                ? null
                                : () => onPlus(item.id, item.quantity),
                          ),
                          Text(
                            '₹${item.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
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
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });
  final int qty;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(icon: Icons.remove_rounded, onTap: onMinus),
          SizedBox(
            width: 30,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _Btn(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.count,
    required this.loading,
    required this.onCheckout,
  });
  final double total;
  final int count;
  final bool loading;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count item${count != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: loading ? null : onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Place Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
