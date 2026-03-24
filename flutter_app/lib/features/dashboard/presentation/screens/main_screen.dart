import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/navigation_provider.dart';
import '../../../../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import '../../../documents/presentation/screens/my_requests_screen.dart';
import '../../../approvals/presentation/screens/approval_queue_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../admin/presentation/screens/user_management_screen.dart';
import '../../../admin/presentation/screens/document_flow_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final user      = ref.watch(authProvider).valueOrNull;
    final isAdmin   = user?.role == 'admin';
    final isStudent = user?.role == 'student';

    final List<({IconData icon, IconData selectedIcon, String label, Widget screen})> navItems;

    if (isAdmin) {
      navItems = [
        (icon: Icons.people_outline, selectedIcon: Icons.people_rounded, label: 'Users', screen: const UserManagementScreen()),
        (icon: Icons.pending_actions_outlined, selectedIcon: Icons.pending_actions_rounded, label: 'Pending', screen: const UserManagementScreen(showPendingOnly: true)),
        (icon: Icons.account_tree_outlined, selectedIcon: Icons.account_tree_rounded, label: 'Flows', screen: const DocumentFlowScreen()),
        (icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: 'Profile', screen: const ProfileScreen()),
      ];
    } else if (isStudent) {
      navItems = [
        (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home', screen: const DashboardScreen()),
        (icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt_rounded, label: 'Requests', screen: const MyRequestsScreen()),
        (icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: 'Profile', screen: const ProfileScreen()),
      ];
    } else {
      navItems = [
        (icon: Icons.check_circle_outline, selectedIcon: Icons.check_circle_rounded, label: 'Approvals', screen: const ApprovalQueueScreen()),
        (icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: 'Profile', screen: const ProfileScreen()),
      ];
    }

    final safeIndex = currentIndex >= navItems.length ? 0 : currentIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey(safeIndex),
          child: navItems[safeIndex].screen,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: navItems.asMap().entries.map((entry) {
                final i    = entry.key;
                final item = entry.value;
                final selected = i == safeIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => ref.read(navigationProvider.notifier).setIndex(i),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.selectedIcon : item.icon,
                            color: selected ? AppColors.primary : AppColors.muted,
                            size: 22,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              color: selected ? AppColors.primary : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
