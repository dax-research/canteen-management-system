import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/category.dart';
import '../../models/food_item.dart';
import '../../services/admin_service.dart';
import '../../widgets/profile_menu_button.dart';
import '../staff/staff_screens.dart' show InventoryManagementScreen;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<DashboardStats> _stats;

  @override
  void initState() {
    super.initState();
    _stats = AdminService.getDashboardStats();
  }

  void _refresh() => setState(() => _stats = AdminService.getDashboardStats());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: const [ProfileMenuButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: AppColors.espresso,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Canteen administration',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage the menu, categories and stock.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<DashboardStats>(
              future: _stats,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorCard(
                    message: _errorMessage(snapshot.error),
                    onRetry: _refresh,
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final stats = snapshot.data!;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Metric(label: 'Food items', value: stats.totalFoodItems),
                    _Metric(label: 'Users', value: stats.totalUsers),
                    _Metric(
                      label: 'Pending orders',
                      value: stats.pendingOrders,
                    ),
                    _Metric(
                      label: 'Out of stock',
                      value: stats.outOfStockItems,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _AdminLink(
              title: 'Categories',
              subtitle: 'Create, edit and remove menu categories.',
              icon: Icons.category_outlined,
              onTap: () => context.go(AppPaths.adminCategories),
            ),
            _AdminLink(
              title: 'Food Items',
              subtitle: 'Manage descriptions, prices, stock and availability.',
              icon: Icons.restaurant_menu_rounded,
              onTap: () => context.go(AppPaths.adminFoodItems),
            ),
            _AdminLink(
              title: 'Inventory',
              subtitle: 'Review availability and update stock.',
              icon: Icons.inventory_2_outlined,
              onTap: () => context.go(AppPaths.adminInventory),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<Category> _categories = [];
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
      final categories = await AdminService.getCategories();
      if (mounted) setState(() => _categories = categories);
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Category? category]) async {
    final values = await showDialog<_CategoryValues>(
      context: context,
      builder: (_) => _CategoryForm(category: category),
    );
    if (values == null) return;
    try {
      if (category == null) {
        await AdminService.createCategory(
          name: values.name,
          description: values.description,
        );
      } else {
        await AdminService.updateCategory(
          category.id,
          name: values.name,
          description: values.description,
        );
      }
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "${category.name}"? Categories containing food '
          'items cannot be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminService.deleteCategory(category.id);
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Create category',
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
          ),
          const ProfileMenuButton(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorCard(message: _error!, onRetry: _load)
          : _categories.isEmpty
          ? _Empty(
              message: 'No categories yet. Add the first category.',
              action: FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Create category'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Card(
                    child: ListTile(
                      title: Text(category.name),
                      subtitle: Text(
                        category.description?.isNotEmpty == true
                            ? category.description!
                            : 'No description',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Edit category',
                            onPressed: () => _edit(category),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete category',
                            onPressed: () => _delete(category),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: _categories.isNotEmpty && !_loading
          ? FloatingActionButton(
              onPressed: () => _edit(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class AdminFoodItemsScreen extends StatefulWidget {
  const AdminFoodItemsScreen({super.key});

  @override
  State<AdminFoodItemsScreen> createState() => _AdminFoodItemsScreenState();
}

class _AdminFoodItemsScreenState extends State<AdminFoodItemsScreen> {
  List<FoodItem> _items = [];
  List<Category> _categories = [];
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
      final itemsFuture = AdminService.getFoodItems();
      final categoriesFuture = AdminService.getCategories();
      final items = await itemsFuture;
      final categories = await categoriesFuture;
      if (mounted) {
        setState(() {
          _items = items;
          _categories = categories;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([FoodItem? item]) async {
    if (_categories.isEmpty) {
      _showError(Exception('Create a category before adding food items.'));
      return;
    }
    final values = await showDialog<_FoodValues>(
      context: context,
      builder: (_) => _FoodForm(item: item, categories: _categories),
    );
    if (values == null) return;
    try {
      if (item == null) {
        await AdminService.createFoodItem(
          categoryId: values.categoryId,
          name: values.name,
          description: values.description,
          price: values.price,
          stock: values.stock,
          imageUrl: values.imageUrl,
          isAvailable: values.isAvailable,
        );
      } else {
        await AdminService.updateFoodItem(
          item.id,
          categoryId: values.categoryId,
          name: values.name,
          description: values.description,
          price: values.price,
          stock: values.stock,
          imageUrl: values.imageUrl,
          isAvailable: values.isAvailable,
        );
      }
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _delete(FoodItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete food item?'),
        content: Text('Delete "${item.name}" from the menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AdminService.deleteFoodItem(item.id);
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Items'),
        actions: [
          IconButton(
            tooltip: 'Create food item',
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
          ),
          const ProfileMenuButton(),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorCard(message: _error!, onRetry: _load)
          : _items.isEmpty
          ? _Empty(
              message: 'No food items yet. Add the first item.',
              action: FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Create food item'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.categoryName}  •  ${formatCurrency(item.price)}  •  Stock ${item.stock}\n${item.isAvailable ? 'Available' : 'Unavailable'}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) =>
                            action == 'edit' ? _edit(item) : _delete(item),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: _items.isNotEmpty && !_loading
          ? FloatingActionButton(
              onPressed: () => _edit(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class AdminInventoryScreen extends StatelessWidget {
  const AdminInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const InventoryManagementScreen(isAdmin: true);
}

class _CategoryValues {
  const _CategoryValues(this.name, this.description);
  final String name;
  final String description;
}

class _CategoryForm extends StatefulWidget {
  const _CategoryForm({this.category});
  final Category? category;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.name ?? '');
    _description = TextEditingController(
      text: widget.category?.description ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.category == null ? 'Create category' : 'Edit category'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Name is required.'
                : null,
          ),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(
              context,
              _CategoryValues(_name.text.trim(), _description.text.trim()),
            );
          }
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _FoodValues {
  const _FoodValues({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.isAvailable,
  });
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final bool isAvailable;
}

class _FoodForm extends StatefulWidget {
  const _FoodForm({this.item, required this.categories});
  final FoodItem? item;
  final List<Category> categories;

  @override
  State<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<_FoodForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _imageUrl;
  late String _categoryId;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _price = TextEditingController(text: item?.price.toString() ?? '');
    _stock = TextEditingController(text: item?.stock.toString() ?? '0');
    _imageUrl = TextEditingController(text: item?.imageUrl ?? '');
    _categoryId =
        widget.categories.any((category) => category.id == item?.categoryId)
        ? item!.categoryId
        : widget.categories.first.id;
    _isAvailable = item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Create food item' : 'Edit food item'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _categoryId = value);
                },
              ),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _required,
              ),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  return amount == null || amount < 0
                      ? 'Enter a valid non-negative price.'
                      : null;
                },
              ),
              TextFormField(
                controller: _stock,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final stock = int.tryParse(value ?? '');
                  return stock == null || stock < 0
                      ? 'Enter a stock quantity of 0 or more.'
                      : null;
                },
              ),
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
                keyboardType: TextInputType.url,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            _FoodValues(
              categoryId: _categoryId,
              name: _name.text.trim(),
              description: _description.text.trim(),
              price: double.parse(_price.text.trim()),
              stock: int.parse(_stock.text.trim()),
              imageUrl: _imageUrl.text.trim(),
              isAvailable: _isAvailable,
            ),
          );
        },
        child: const Text('Save'),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _AdminLink extends StatelessWidget {
  const _AdminLink({
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

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, required this.action});
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textHint),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          action,
        ],
      ),
    ),
  );
}

String _errorMessage(Object? error) =>
    error.toString().replaceFirst('Exception: ', '');
