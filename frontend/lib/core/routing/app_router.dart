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

abstract final class AppRoutes {
  static const String splash      = 'splash';
  static const String login       = 'login';
  static const String register    = 'register';
  static const String shell       = 'shell';
  static const String home        = 'home';
  static const String cart        = 'cart';
  static const String orders      = 'orders';
  static const String orderDetail = 'order-detail';
}

abstract final class AppPaths {
  static const String splash      = '/';
  static const String login       = '/login';
  static const String register    = '/register';
  static const String home        = '/home';
  static const String cart        = '/cart';
  static const String orders      = '/orders';
  static const String orderDetail = '/orders/:orderId';
}

abstract final class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppPaths.splash,
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
    ],

    errorBuilder: (context, state) => _RouterErrorPage(error: state.error),
  );

  static String? _redirect(BuildContext context, GoRouterState state) {
    final auth = context.read<AuthProvider>();

    // Still initialising — let splash handle it
    if (auth.isInitialising) return null;

    final isAuthenticated = auth.isAuthenticated;
    final loc = state.matchedLocation;

    final isPublic = loc == AppPaths.splash ||
        loc == AppPaths.login ||
        loc == AppPaths.register;

    if (!isAuthenticated && !isPublic) return AppPaths.login;
    if (isAuthenticated && (loc == AppPaths.login || loc == AppPaths.register)) {
      return AppPaths.home;
    }
    return null;
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
