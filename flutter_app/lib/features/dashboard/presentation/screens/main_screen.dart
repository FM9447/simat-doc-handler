import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_screen.dart';
import '../../../documents/presentation/screens/my_requests_screen.dart';
import '../../../approvals/presentation/screens/approval_queue_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../admin/presentation/screens/user_management_screen.dart';
import '../../../admin/presentation/screens/document_flow_screen.dart';
import '../../../../providers/navigation_provider.dart';
import '../../../../providers/auth_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final user = ref.watch(authProvider).valueOrNull;
    final isAdmin = user?.role == 'admin';
    final isStudent = user?.role == 'student';

    final List<({IconData icon, IconData selectedIcon, String label, Widget screen})> navigationItems;

    if (isAdmin) {
      navigationItems = [
        (icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Users', screen: const UserManagementScreen()),
        (icon: Icons.account_tree_outlined, selectedIcon: Icons.account_tree, label: 'Flows', screen: const DocumentFlowScreen()),
        (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', screen: const ProfileScreen()),
      ];
    } else {
      navigationItems = [
        (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', screen: const DashboardScreen()),
        if (isStudent) (icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt, label: 'Requests', screen: const MyRequestsScreen())
        else (icon: Icons.check_circle_outline, selectedIcon: Icons.check_circle, label: 'Approvals', screen: const ApprovalQueueScreen()),
        (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', screen: const ProfileScreen()),
      ];
    }

    final safeIndex = currentIndex >= navigationItems.length ? 0 : currentIndex;

    return Scaffold(
      body: navigationItems[safeIndex].screen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) {
          ref.read(navigationProvider.notifier).setIndex(index);
        },
        destinations: navigationItems.map((item) => NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: item.label,
        )).toList(),
      ),
    );
  }
}
