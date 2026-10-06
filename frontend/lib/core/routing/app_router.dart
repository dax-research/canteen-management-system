import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/orders/order_details_screen.dart' show OrderDetailsScreen;
import '../../screens/admin/admin_screens.dart';
import '../../screens/staff/staff_screens.dart';

abstract final class AppRoutes {
  static const String splash      = 'splash';
  static const String login       = 'login';
  static const String register    = 'register';
  static const String shell       = 'shell';
  static const String home        = 'home';
  static const String cart        = 'cart';
  static const String orders      = 'orders';
  static const String orderDetail = 'order-detail';
  static const String staffHome = 'staff-home';
  static const String staffOrders = 'staff-orders';
  static const String staffOrderDetail = 'staff-order-detail';
  static const String staffInventory = 'staff-inventory';
  static const String adminHome = 'admin-home';
  static const String adminCategories = 'admin-categories';
  static const String adminFoodItems = 'admin-food-items';
  static const String adminInventory = 'admin-inventory';
}

abstract final class AppPaths {
  static const String splash      = '/';
  static const String login       = '/login';
  static const String register    = '/register';
  static const String home        = '/home';
  static const String cart        = '/cart';
  static const String orders      = '/orders';
  static const String orderDetail = '/orders/:orderId';
  static const String staff = '/staff';
  static const String staffOrders = '/staff/orders';
  static const String staffOrderDetail = '/staff/orders/:orderId';
  static const String staffInventory = '/staff/inventory';
  static const String admin = '/admin';
  static const String adminCategories = '/admin/categories';
  static const String adminFoodItems = '/admin/food-items';
  static const String adminInventory = '/admin/inventory';

  static String forRole(UserRole role) => switch (role) {
        UserRole.customer => home,
        UserRole.staff => staff,
        UserRole.admin => admin,
        UserRole.unknown => login,
      };

  static String? roleRedirect(UserRole role, String location) {
    if (role == UserRole.unknown) {
      return location == login ? null : login;
    }
    if (location == splash || location == login || location == register) {
      return forRole(role);
    }

    final isCustomerPath = location == home ||
        location == cart ||
        location == orders ||
        location.startsWith('$orders/');
    final isStaffPath = location.startsWith('/staff');
    final isAdminPath = location.startsWith('/admin');
    if (role != UserRole.customer && isCustomerPath) return forRole(role);
    if (!role.isStaff && isStaffPath) return forRole(role);
    if (!role.isAdmin && isAdminPath) return forRole(role);
    return null;
  }
}

abstract final class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppPaths.splash,
    refreshListenable: AuthProvider.navigationChanges,
    debugLogDiagnostics: false,
    redirect: _redirect,
    routes: [
      // ── Splash ──────────────────────────────────────────────
      GoRoute(
        path: AppPaths.splash,
        name: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ────────────────────────────────────────────────
      GoRoute(
        path: AppPaths.login,
        name: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppPaths.register,
        name: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Main Shell (bottom nav) ──────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppPaths.home,
            name: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppPaths.cart,
            name: AppRoutes.cart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: AppPaths.orders,
            name: AppRoutes.orders,
            builder: (context, state) => const OrdersScreen(),
          ),
        ],
      ),

      // ── Order Detail (full screen, no shell) ────────────────
      GoRoute(
        path: AppPaths.orderDetail,
        name: AppRoutes.orderDetail,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailsScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: AppPaths.staff,
        name: AppRoutes.staffHome,
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: AppPaths.staffOrders,
        name: AppRoutes.staffOrders,
        builder: (context, state) => const StaffOrdersScreen(),
      ),
      GoRoute(
        path: AppPaths.staffOrderDetail,
        name: AppRoutes.staffOrderDetail,
        builder: (context, state) => StaffOrderDetailsScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppPaths.staffInventory,
        name: AppRoutes.staffInventory,
        builder: (context, state) => const StaffInventoryScreen(),
      ),
      GoRoute(
        path: AppPaths.admin,
        name: AppRoutes.adminHome,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppPaths.adminCategories,
        name: AppRoutes.adminCategories,
        builder: (context, state) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        path: AppPaths.adminFoodItems,
        name: AppRoutes.adminFoodItems,
        builder: (context, state) => const AdminFoodItemsScreen(),
      ),
      GoRoute(
        path: AppPaths.adminInventory,
        name: AppRoutes.adminInventory,
        builder: (context, state) => const AdminInventoryScreen(),
      ),
    ],

    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final auth = context.read<AuthProvider>();
    final loc = state.matchedLocation;

    // Still initialising — let splash handle it
    if (auth.isInitialising) {
      return loc == AppPaths.splash ? null : AppPaths.splash;
    }
    final isAuthenticated = auth.isAuthenticated;

    final isPublic = loc == AppPaths.splash ||
        loc == AppPaths.login ||
        loc == AppPaths.register;

    if (!isAuthenticated && !isPublic) return AppPaths.login;
    if (!isAuthenticated) return null;
    return AppPaths.roleRedirect(auth.role, loc);
  }
}

class _RouterErrorPage extends StatelessWidget {
  const _RouterErrorPage({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppPaths.splash),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
