import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/food_item.dart';
import '../../models/order.dart';
import '../../services/admin_service.dart';
import '../../services/staff_service.dart';
import '../../widgets/profile_menu_button.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  late Future<List<Order>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = StaffService.getOrders();
  }

  void _refresh() => setState(() => _orders = StaffService.getOrders());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        actions: const [ProfileMenuButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _IntroCard(
              title: 'Service operations',
              subtitle: 'Manage incoming orders and live inventory.',
              icon: Icons.point_of_sale_rounded,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Order>>(
              future: _orders,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _LoadError(
                    message: _message(snapshot.error),
                    retry: _refresh,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                final active = snapshot.data!
                    .where((order) => _allowedNext(order.status).isNotEmpty)
                    .length;
                return _StatCard(
                  label: 'Orders needing attention',
                  value: '$active',
                  icon: Icons.receipt_long_rounded,
                );
              },
            ),
            const SizedBox(height: 18),
            _NavigationCard(
              title: 'Orders',
              subtitle: 'Review incoming orders and update their progress.',
              icon: Icons.receipt_long_rounded,
              onTap: () => context.go(AppPaths.staffOrders),
            ),
            _NavigationCard(
              title: 'Inventory',
              subtitle: 'Check availability and update stock levels.',
              icon: Icons.inventory_2_rounded,
              onTap: () => context.go(AppPaths.staffInventory),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  late Future<List<Order>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = StaffService.getOrders();
  }

  Future<void> _refresh() async {
    final future = StaffService.getOrders();
    setState(() => _orders = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        actions: const [ProfileMenuButton()],
      ),
      body: FutureBuilder<List<Order>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LoadError(
              message: _message(snapshot.error),
              retry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const _EmptyState(
              title: 'No incoming orders',
              message: 'New orders will appear here.',
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: const Icon(
                        Icons.receipt_long,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    title: Text('Order ${_shortId(order.id)}'),
                    subtitle: Text(
                      'Customer ${_shortId(order.userId)}  •  ${order.items.length} items  •  ${_money(order.totalAmount)}  •  Pickup ${order.pickupText}',
                    ),
                    trailing: _StatusChip(status: order.status),
                    onTap: () => context.push(
                      AppPaths.staffOrderDetail.replaceFirst(
                        ':orderId',
                        order.id,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class StaffOrderDetailsScreen extends StatefulWidget {
  const StaffOrderDetailsScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<StaffOrderDetailsScreen> createState() =>
      _StaffOrderDetailsScreenState();
}

class _StaffOrderDetailsScreenState extends State<StaffOrderDetailsScreen> {
  Order? _order;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await StaffService.getOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _updating = true);
    try {
      final updated = await StaffService.updateOrderStatus(
        widget.orderId,
        status,
      );
      if (mounted) setState(() => _order = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _confirmCashPayment() async {
    setState(() => _updating = true);
    try {
      final updated = await StaffService.confirmCashPayment(widget.orderId);
      if (mounted) setState(() => _order = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final next = order == null ? const <String>[] : _allowedNext(order.status);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: const [ProfileMenuButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _LoadError(message: _error!, retry: _load)
          : order == null
          ? const _EmptyState(
              title: 'Order unavailable',
              message: 'This order could not be found.',
              icon: Icons.search_off_rounded,
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _StatusChip(status: order.status),
                const SizedBox(height: 12),
                Text(
                  'Order ${_shortId(order.id)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('Customer ${_shortId(order.userId)}'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Pickup: ${order.pickupText}${order.etaMinutes != null ? ' • ETA ${order.etaMinutes} min' : ''}',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...order.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.itemName),
                    subtitle: Text(
                      '${item.quantity} × ${_money(item.unitPrice)}',
                    ),
                    trailing: Text(_money(item.subtotal)),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Total'),
                  trailing: Text(_money(order.totalAmount)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Payment'),
                  subtitle: Text(order.paymentMethodText),
                  trailing: Text(
                    order.paymentStatus == 'PAID' ? 'PAID' : 'DUE',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: order.paymentStatus == 'PAID'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
                if (order.paymentReference != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Payment reference'),
                    subtitle: Text(order.paymentReference!),
                  ),
                if (order.paymentMethod == 'CASH' &&
                    order.paymentStatus != 'PAID') ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _updating ? null : _confirmCashPayment,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Confirm cash received'),
                  ),
                ],
                const SizedBox(height: 20),
                if (next.isEmpty)
                  const Text('This order is in a final status.')
                else ...[
                  const Text('Update order status'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: next
                        .map(
                          (status) => FilledButton.tonal(
                            onPressed: _updating
                                ? null
                                : () => _setStatus(status),
                            child: Text(_statusLabel(status)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
    );
  }
}

class StaffInventoryScreen extends StatelessWidget {
  const StaffInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const InventoryManagementScreen(isAdmin: false);
}

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key, required this.isAdmin});
  final bool isAdmin;

  @override
  State<InventoryManagementScreen> createState() =>
      _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  List<FoodItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = widget.isAdmin
          ? await AdminService.getInventory()
          : await StaffService.getInventory();
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editStock(FoodItem item) async {
    final controller = TextEditingController(text: item.stock.toString());
    final formKey = GlobalKey<FormState>();
    final stock = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update ${item.name} stock'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Stock quantity'),
            validator: (value) {
              final parsed = int.tryParse(value ?? '');
              return parsed == null || parsed < 0
                  ? 'Enter a stock quantity of 0 or more.'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, int.parse(controller.text));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (stock == null) return;
    try {
      if (widget.isAdmin) {
        await AdminService.updateStock(item.id, stock);
      } else {
        await StaffService.updateStock(item.id, stock);
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: const [ProfileMenuButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _LoadError(message: _error!, retry: _load)
          : _items.isEmpty
          ? const _EmptyState(
              title: 'No inventory items',
              message: 'Inventory data will appear here.',
              icon: Icons.inventory_2_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final status = item.stock == 0
                      ? 'Out of stock'
                      : item.isAvailable
                      ? 'Available'
                      : 'Unavailable';
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text('$status  •  Stock: ${item.stock}'),
                      leading: Icon(
                        item.stock == 0
                            ? Icons.remove_shopping_cart_outlined
                            : item.isAvailable
                            ? Icons.check_circle_outline
                            : Icons.block_outlined,
                        color: item.stock == 0 || !item.isAvailable
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      trailing: IconButton(
                        tooltip: 'Update stock',
                        onPressed: () => _editStock(item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.espresso,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primaryDark),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon, color: AppColors.primaryDark),
      title: Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(label),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(_statusLabel(status)),
    backgroundColor: AppColors.primaryLight,
    side: BorderSide.none,
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.error),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.icon,
  });
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

List<String> _allowedNext(String status) => switch (status.toUpperCase()) {
  'PLACED' => ['ACCEPTED', 'CANCELLED'],
  'ACCEPTED' => ['PREPARING', 'CANCELLED'],
  'PREPARING' => ['READY', 'CANCELLED'],
  'READY' => ['COMPLETED'],
  _ => const [],
};

String _statusLabel(String status) =>
    status[0] + status.substring(1).toLowerCase().replaceAll('_', ' ');

String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

String _money(double amount) => formatCurrency(amount);

String _message(Object? error) =>
    error.toString().replaceFirst('Exception: ', '');
