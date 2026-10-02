import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [AppPaths.home, AppPaths.cart, AppPaths.orders];

  int _index(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith(AppPaths.cart)) return 1;
    if (loc.startsWith(AppPaths.orders)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _index(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(color: AppColors.divider, width: 0.8)),
          boxShadow: [
            BoxShadow(
                color: Color(0x18000000),
                blurRadius: 20,
                offset: Offset(0, -4))
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _Tab(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Menu',
                  active: idx == 0,
                  onTap: () => context.go(_tabs[0]),
                ),
                _Tab(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: 'Cart',
                  active: idx == 1,
                  onTap: () => context.go(_tabs[1]),
                ),
                _Tab(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  active: idx == 2,
                  onTap: () => context.go(_tabs[2]),
                ),
                _Tab(
                  icon: Icons.logout_rounded,
                  activeIcon: Icons.logout_rounded,
                  label: 'Logout',
                  active: false,
                  destructive: true,
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        backgroundColor: AppColors.surface,
                        title: const Text('Sign out?',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        content: Text(
                            'You\'ll need to sign in again to place orders.',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go(AppPaths.login);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? AppColors.error
        : active
            ? AppColors.primary
            : AppColors.textHint;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: active
              ? BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
