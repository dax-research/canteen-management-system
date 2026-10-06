import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/routing/app_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.primaryLight,
        child: Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
      ),
      onSelected: (action) async {
        if (action == 'profile') {
          final user = context.read<AuthProvider>().user;
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Profile'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name.isNotEmpty == true ? user!.name : 'Account'),
                  const SizedBox(height: 6),
                  Text(user?.email ?? ''),
                  const SizedBox(height: 6),
                  Text(context.read<AuthProvider>().role.displayName),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        } else if (action == 'logout') {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Sign out?'),
              content: const Text('You will need to sign in again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Sign out'),
                ),
              ],
            ),
          );
          if (shouldLogout == true && context.mounted) {
            await context.read<AuthProvider>().logout();
            if (context.mounted) context.go(AppPaths.login);
          }
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'profile', child: Text('Profile')),
        PopupMenuItem(value: 'logout', child: Text('Sign out')),
      ],
    );
  }
}
