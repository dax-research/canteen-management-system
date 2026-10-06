import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/models/user.dart';

void main() {
  group('Role-based route redirects', () {
    test('CUSTOMER is sent home from staff and admin routes', () {
      expect(
        AppPaths.roleRedirect(UserRole.customer, '/staff/orders'),
        AppPaths.home,
      );
      expect(
        AppPaths.roleRedirect(UserRole.customer, '/admin/categories'),
        AppPaths.home,
      );
      expect(AppPaths.roleRedirect(UserRole.customer, AppPaths.cart), isNull);
    });

    test('STAFF is sent home from customer and admin routes', () {
      expect(
        AppPaths.roleRedirect(UserRole.staff, AppPaths.orders),
        AppPaths.staff,
      );
      expect(
        AppPaths.roleRedirect(UserRole.staff, '/admin/food-items'),
        AppPaths.staff,
      );
      expect(
        AppPaths.roleRedirect(UserRole.staff, AppPaths.staffInventory),
        isNull,
      );
    });

    test('ADMIN is sent home from customer and staff routes', () {
      expect(
        AppPaths.roleRedirect(UserRole.admin, AppPaths.home),
        AppPaths.admin,
      );
      expect(
        AppPaths.roleRedirect(UserRole.admin, AppPaths.staffOrders),
        AppPaths.admin,
      );
      expect(
        AppPaths.roleRedirect(UserRole.admin, AppPaths.adminFoodItems),
        isNull,
      );
    });
  });
}
