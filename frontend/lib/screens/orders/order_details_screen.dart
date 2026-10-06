import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/order.dart';
import '../../services/invoice_service.dart';
import '../../services/order_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? _order;
  bool _loading = true;
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
      final o = await OrderService.getOrder(widget.orderId);
      if (mounted) {
        setState(() {
          _order = o;
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

  Future<void> _printInvoice() async {
    final order = _order;
    if (order == null) return;
    try {
      await InvoiceService.printInvoice(order);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not generate invoice: ${error.toString().replaceAll('Exception: ', '')}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Generate invoice',
            onPressed: _order == null ? null : _printInvoice,
            icon: const Icon(Icons.receipt_long_rounded),
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
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load order',
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
    if (_order == null) {
      return const Center(child: Text('Order not found.'));
    }

    final s = _Status.of(_order!.status);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _StatusBanner(order: _order!, s: s),
                const SizedBox(height: 16),
                _Receipt(order: _order!),
              ],
            ),
          ),
        ),
        _TotalBar(order: _order!),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.order, required this.s});
  final Order order;
  final _Status s;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.color.withValues(alpha: 0.2), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A2C1810),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: s.light, shape: BoxShape.circle),
            child: Icon(s.icon, color: s.color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            s.label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: s.color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Order #${order.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
              Text(
                _fmtDt(order.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  size: 14,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  'Pickup • ${order.pickupText}${order.etaMinutes != null ? ' • ${order.etaText}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDt(DateTime dt) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}  ·  $h:$min';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _Receipt extends StatelessWidget {
  const _Receipt({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Items
          ...order.items.asMap().entries.map((e) {
            final item = e.value;
            final last = e.key == order.items.length - 1;
            return Column(
              children: [
                _Row(item: item),
                if (!last)
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.divider,
                  ),
              ],
            );
          }),

          // Subtotals
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SumRow('Subtotal', '₹${order.totalAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 6),
                _SumRow(
                  'Pickup',
                  'Ready on site',
                  valueColor: AppColors.success,
                ),
                const SizedBox(height: 6),
                _SumRow(
                  'ETA',
                  order.etaMinutes == null ? 'Soon' : '${order.etaMinutes} min',
                  valueColor: AppColors.primaryDark,
                ),
                const Divider(height: 20),
                _SumRow('Payment method', order.paymentMethodText),
                const SizedBox(height: 6),
                _SumRow(
                  'Payment status',
                  order.paymentStatus == 'PAID' ? 'Paid' : 'Due at pickup',
                  valueColor: order.paymentStatus == 'PAID'
                      ? AppColors.success
                      : AppColors.warning,
                ),
                if (order.paymentReference != null) ...[
                  const SizedBox(height: 6),
                  _SumRow('Reference', order.paymentReference!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});
  final OrderItem item;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.quantity}×',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${item.unitPrice.toStringAsFixed(2)} each',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow(this.label, this.value, {this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.order});
  final Order order;
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                order.paymentStatus == 'PAID' ? 'Total Paid' : 'Order Total',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tax included',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          Text(
            '₹${order.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _Status {
  const _Status({
    required this.label,
    required this.color,
    required this.light,
    required this.icon,
  });
  final String label;
  final Color color;
  final Color light;
  final IconData icon;

  factory _Status.of(String raw) {
    switch (raw.toUpperCase()) {
      case 'PLACED':
        return const _Status(
          label: 'Order Placed',
          color: AppColors.primary,
          light: AppColors.primaryLight,
          icon: Icons.pending_rounded,
        );
      case 'ACCEPTED':
        return const _Status(
          label: 'Accepted',
          color: Color(0xFF7C3AED),
          light: Color(0xFFEDE9FE),
          icon: Icons.thumb_up_alt_rounded,
        );
      case 'PREPARING':
        return const _Status(
          label: 'Preparing Your Order',
          color: AppColors.warning,
          light: AppColors.warningLight,
          icon: Icons.restaurant_rounded,
        );
      case 'READY':
        return const _Status(
          label: 'Ready to Pick Up',
          color: AppColors.success,
          light: AppColors.successLight,
          icon: Icons.check_circle_rounded,
        );
      case 'COMPLETED':
        return const _Status(
          label: 'Completed',
          color: Color(0xFF0D9488),
          light: Color(0xFFCCFBF1),
          icon: Icons.done_all_rounded,
        );
      case 'CANCELLED':
        return const _Status(
          label: 'Cancelled',
          color: AppColors.error,
          light: AppColors.errorLight,
          icon: Icons.cancel_rounded,
        );
      default:
        return const _Status(
          label: 'Unknown',
          color: AppColors.textSecondary,
          light: AppColors.surfaceVariant,
          icon: Icons.help_rounded,
        );
    }
  }
}
