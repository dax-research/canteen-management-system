import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api';
    } else {
      return 'http://127.0.0.1:8000/api';
    }
  }

  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get logout => '$baseUrl/auth/logout';

  static String get categories => '$baseUrl/categories';
  static String get foodItems => '$baseUrl/food-items';

  static String get cart => '$baseUrl/cart';
  static String get cartItems => '$baseUrl/cart/items';

  static String get orders => '$baseUrl/orders';
  static String get staffOrders => '$baseUrl/orders/staff';
  static String get inventory => '$baseUrl/inventory';

  // ── Admin-only endpoints (backend returns 403 for non-admin tokens) ──────
  static String get adminDashboard => '$baseUrl/admin/dashboard';
  static String get adminUsers => '$baseUrl/admin/users';
  static String get adminOrders => '$baseUrl/admin/orders';
  static String get adminFoodItems => '$baseUrl/admin/food-items';
  static String get adminCategories => '$baseUrl/admin/categories';
  static String get adminInventory => inventory;
}
