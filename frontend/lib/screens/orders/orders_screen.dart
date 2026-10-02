import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/app_shimmer.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final o = await OrderService.getOrders();
      if (mounted) setState(() { _orders = o; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetch,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: 5,
        itemBuilder: (context, index) => const OrderTileSkeleton(),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_rounded,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('Could not load orders',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ]),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded,
                size: 46, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          const Text('No orders yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Your order history will appear here',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppPaths.home),
            icon: const Icon(Icons.restaurant_menu_rounded),
            label: const Text('Browse Menu'),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: _orders.length,
        itemBuilder: (_, i) => _OrderCard(
          order: _orders[i],
          onTap: () =>
              context.push('${AppPaths.orders}/${_orders[i].id}'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});
  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = _Status.of(order.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A2C1810),
                blurRadius: 10,
                offset: Offset(0, 3))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Icon circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: s.light, shape: BoxShape.circle),
              child: Icon(s.icon, color: s.color, size: 24),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.items.length} item${order.items.length != 1 ? 's' : ''}  ·  ${_fmt(order.createdAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    _Badge(status: s),
                  ]),
            ),
            const SizedBox(width: 10),
            // Amount + chevron
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 2),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 18),
            ]),
          ]),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]}';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.status});
  final _Status status;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: status.light,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status.label,
          style: TextStyle(
              color: status.color,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _Status {
  const _Status(
      {required this.label,
      required this.color,
      required this.light,
      required this.icon});
  final String label;
  final Color color;
  final Color light;
  final IconData icon;

  factory _Status.of(String raw) {
    switch (raw.toUpperCase()) {
      case 'PLACED':
        return const _Status(
            label: 'Placed',
            color: AppColors.primary,
            light: AppColors.primaryLight,
            icon: Icons.pending_rounded);
      case 'ACCEPTED':
        return const _Status(
            label: 'Accepted',
            color: Color(0xFF7C3AED),
            light: Color(0xFFEDE9FE),
            icon: Icons.thumb_up_alt_rounded);
      case 'PREPARING':
        return const _Status(
            label: 'Preparing',
            color: AppColors.warning,
            light: AppColors.warningLight,
            icon: Icons.restaurant_rounded);
      case 'READY':
        return const _Status(
            label: 'Ready',
            color: AppColors.success,
            light: AppColors.successLight,
            icon: Icons.check_circle_rounded);
      case 'COMPLETED':
        return const _Status(
            label: 'Completed',
            color: Color(0xFF0D9488),
            light: Color(0xFFCCFBF1),
            icon: Icons.done_all_rounded);
      case 'CANCELLED':
        return const _Status(
            label: 'Cancelled',
            color: AppColors.error,
            light: AppColors.errorLight,
            icon: Icons.cancel_rounded);
      default:
        return const _Status(
            label: 'Unknown',
            color: AppColors.textSecondary,
            light: AppColors.surfaceVariant,
            icon: Icons.help_rounded);
    }
  }
}
