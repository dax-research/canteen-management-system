// Admin-facing API calls.
//
// Every method here hits an endpoint the backend gates behind
// `get_admin_user`, so a non-admin token receives 403 regardless of what the
// UI shows. Hiding screens is navigation polish; the server is the boundary.

import '../core/constants/api_constants.dart';
import '../models/category.dart';
import '../models/food_item.dart';
import '../models/order.dart';
import 'api_service.dart';

/// Aggregate counters for the admin dashboard.
class DashboardStats {
  final int totalFoodItems;
  final int totalUsers;
  final int totalCustomers;
  final int pendingOrders;
  final int activeOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int lowStockItems;
  final int outOfStockItems;

  const DashboardStats({
    this.totalFoodItems = 0,
    this.totalUsers = 0,
    this.totalCustomers = 0,
    this.pendingOrders = 0,
    this.activeOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.lowStockItems = 0,
    this.outOfStockItems = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;
    return DashboardStats(
      totalFoodItems: read('total_food_items'),
      totalUsers: read('total_users'),
      totalCustomers: read('total_customers'),
      pendingOrders: read('pending_orders'),
      activeOrders: read('active_orders'),
      completedOrders: read('completed_orders'),
      cancelledOrders: read('cancelled_orders'),
      lowStockItems: read('low_stock_items'),
      outOfStockItems: read('out_of_stock_items'),
    );
  }
}

/// A registered account, as an admin sees it.
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final int orderCount;
  final double totalSpent;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.orderCount = 0,
    this.totalSpent = 0,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'CUSTOMER',
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// An order plus the customer snapshot attached by the admin endpoint.
class AdminOrder {
  final String id;
  final String status;
  final double totalAmount;
  final DateTime createdAt;
  final String customerName;
  final String customerEmail;
  final List<OrderItem> items;

  const AdminOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.items,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final customer = (json['customer'] as Map?)?.cast<String, dynamic>() ?? {};
    final rawItems = (json['items'] as List?) ?? const [];
    return AdminOrder(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PLACED',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      customerName: customer['name']?.toString() ?? 'Unknown',
      customerEmail: customer['email']?.toString() ?? '',
      items: rawItems
          .map((e) => OrderItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class AdminService {
  // ── Dashboard ───────────────────────────────────────────────
  static Future<DashboardStats> getDashboardStats() async {
    final response = await ApiService.get(ApiConstants.adminDashboard);
    return DashboardStats.fromJson((response as Map).cast<String, dynamic>());
  }

  // ── Orders ──────────────────────────────────────────────────
  static Future<List<AdminOrder>> getOrders({String? status}) async {
    final response = await ApiService.get(
      ApiConstants.adminOrders,
      queryParams:
          (status != null && status.isNotEmpty) ? {'status': status} : null,
    );
    if (response is List) {
      return response
          .map((e) => AdminOrder.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  static Future<AdminOrder> updateOrderStatus(String orderId, String status) async {
    final response = await ApiService.patch(
      '${ApiConstants.adminOrders}/$orderId/status',
      {'status': status},
    );
    return AdminOrder.fromJson((response as Map).cast<String, dynamic>());
  }

  // ── Food items ──────────────────────────────────────────────
  /// All food items including unavailable ones.
  static Future<List<FoodItem>> getFoodItems() async {
    final response = await ApiService.get(ApiConstants.adminFoodItems);
    if (response is List) {
      return response
          .map((e) => FoodItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  static Future<FoodItem> createFoodItem({
    required String categoryId,
    required String name,
    String? description,
    required double price,
    required int stock,
    String? imageUrl,
    bool isAvailable = true,
  }) async {
    final response = await ApiService.post(ApiConstants.adminFoodItems, {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'image_url': imageUrl,
      'is_available': isAvailable,
    });
    return FoodItem.fromJson((response as Map).cast<String, dynamic>());
  }

  static Future<FoodItem> updateFoodItem(
    String id, {
    String? categoryId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    // Only send the keys the admin actually changed — the backend PATCH is a
    // partial update and would blank any field omitted from the schema.
    final body = <String, dynamic>{};
    if (categoryId != null) body['category_id'] = categoryId;
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (stock != null) body['stock'] = stock;
    if (imageUrl != null) body['image_url'] = imageUrl;
    if (isAvailable != null) body['is_available'] = isAvailable;

    final response =
        await ApiService.patch('${ApiConstants.adminFoodItems}/$id', body);
    return FoodItem.fromJson((response as Map).cast<String, dynamic>());
  }

  static Future<void> deleteFoodItem(String id) async {
    await ApiService.delete('${ApiConstants.adminFoodItems}/$id');
  }

  // ── Categories ──────────────────────────────────────────────
  /// All categories including inactive ones.
  static Future<List<Category>> getCategories() async {
    final response = await ApiService.get(ApiConstants.adminCategories);
    if (response is List) {
      return response
          .map((e) => Category.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  static Future<Category> createCategory({
    required String name,
    String? description,
    bool isActive = true,
  }) async {
    final response = await ApiService.post(ApiConstants.adminCategories, {
      'name': name,
      'description': description,
      'is_active': isActive,
    });
    return Category.fromJson((response as Map).cast<String, dynamic>());
  }

  static Future<Category> updateCategory(
    String id, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (isActive != null) body['is_active'] = isActive;

    final response =
        await ApiService.patch('${ApiConstants.adminCategories}/$id', body);
    return Category.fromJson((response as Map).cast<String, dynamic>());
  }

  static Future<void> deleteCategory(String id) async {
    await ApiService.delete('${ApiConstants.adminCategories}/$id');
  }

  // ── Users ───────────────────────────────────────────────────
  static Future<List<AdminUser>> getUsers({String? search}) async {
    final response = await ApiService.get(
      ApiConstants.adminUsers,
      queryParams:
          (search != null && search.trim().isNotEmpty)
              ? {'search': search.trim()}
              : null,
    );
    final list = (response as Map)['users'] as List? ?? const [];
    return list
        .map((e) => AdminUser.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  static Future<AdminUser> getUser(String id) async {
    final response = await ApiService.get('${ApiConstants.adminUsers}/$id');
    return AdminUser.fromJson((response as Map).cast<String, dynamic>());
  }

  // ── Inventory ───────────────────────────────────────────────
  static Future<List<FoodItem>> getInventory() async {
    final response = await ApiService.get(ApiConstants.adminInventory);
    if (response is List) {
      return response
          .map((e) => FoodItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  static Future<FoodItem> updateStock(String foodItemId, int stock) async {
    final response = await ApiService.patch(
      '${ApiConstants.adminInventory}/$foodItemId',
      {'stock': stock},
    );
    return FoodItem.fromJson((response as Map).cast<String, dynamic>());
  }
}
