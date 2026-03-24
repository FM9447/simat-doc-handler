import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/loading_logo.dart'; // Added import for LoadingLogo
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'signature_setup_screen.dart';
import 'profile_edit_screen.dart';
import '../../../admin/presentation/screens/user_management_screen.dart';
import '../../../admin/presentation/screens/document_flow_screen.dart';
import '../widgets/delegation_dialog.dart';
import 'feedback_screen.dart';
import '../../../../shared/widgets/branded_title.dart';
import '../../../../shared/widgets/responsive_layout.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return const Center(child: LoadingLogo(size: 80)); // Replaced CircularProgressIndicator with LoadingLogo

    final roleColor = AppColors.roleColor(user.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const BrandedTitle(),
      ),
      body: MaxWidthWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          children: [
            // --- Avatar + Name ---
            Column(
              children: [
                Container(
                  width: 92, height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [BoxShadow(color: AppColors.glow, blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user.name, style: AppTypography.headingMedium),
                const SizedBox(height: 6),
                Text(user.email, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: roleColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: roleColor, letterSpacing: 0.8),
                      ),
                    ),
                    if (user.departmentName != null) ...[
                      const SizedBox(width: 8),
                      Text('· ${user.departmentName}', style: AppTypography.caption),
                    ],
                  ],
                ),
                if (user.registerNo != null) ...[
                  const SizedBox(height: 6),
                  Text(user.registerNo!, style: AppTypography.labelSmall),
                ],
                const SizedBox(height: 16),
                GradientButton(
                  text: 'Edit Profile',
                  icon: Icons.edit_rounded,
                  outline: true,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileEditScreen(user: user))),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- Digital Signature ---
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.draw_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text('Digital Signature', style: AppTypography.headingSmall),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignatureSetupScreen())),
                        child: Text(user.signatureUrl != null ? 'Update' : 'Setup',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (user.signatureUrl != null)
                    Container(
                      height: 80, width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Image.network(
                        user.signatureUrl!,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        colorBlendMode: BlendMode.modulate,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.error_outline, color: AppColors.rejected)),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'No signature configured. Required for document approvals.',
                        style: AppTypography.caption,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Admin Panel ---
            if (user.role == 'admin') ...[
              _sectionLabel('ADMIN PANEL'),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _tile(Icons.people_alt_rounded, 'User Management', 'Roles & account approvals',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()))),
                    Divider(height: 1, color: AppColors.border),
                    _tile(Icons.account_tree_rounded, 'Document Flows', 'Workflow builder & templates',
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentFlowScreen()))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
 
            // --- Vacation Mode / Delegation ---
            if (user.role != 'student') ...[
              _sectionLabel('VACATION MODE'),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          user.delegatedToId != null ? Icons.flight_takeoff_rounded : Icons.work_outline_rounded,
                          size: 20,
                          color: user.delegatedToId != null ? AppColors.secondary : AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text('Role Delegation', style: AppTypography.headingSmall),
                        const Spacer(),
                        if (user.delegatedToId != null)
                          TextButton(
                            onPressed: () => _handleStopDelegation(context, ref),
                            child: const Text('Stop', style: TextStyle(color: AppColors.rejected, fontWeight: FontWeight.bold)),
                          )
                        else
                          TextButton(
                            onPressed: () => _showDelegationDialog(context),
                            child: const Text('Setup', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.delegatedToId != null 
                        ? 'All your current and future requests are being handled by ${user.delegatedToName ?? 'a colleague'}.'
                        : 'Delegate your role to a colleague when you are on leave.',
                      style: AppTypography.caption,
                    ),
                    if (user.delegatedToId != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Requests are auto-forwarded to ${user.delegatedToName}.',
                                style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- Account Settings ---
            _sectionLabel('ACCOUNT SETTINGS'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.secondary, size: 20),
                    title: Text('Notifications', style: AppTypography.bodyMedium),
                    value: ref.watch(notificationProvider).isEnabled,
                    onChanged: (v) => ref.read(notificationProvider.notifier).toggleNotifications(v),
                    activeThumbColor: AppColors.primary,
                  ),
                  Divider(height: 1, color: AppColors.border),
                  _tile(Icons.lock_reset_rounded, 'Change Password', 'Update your credentials',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
                  Divider(height: 1, color: AppColors.border),
                  _tile(Icons.feedback_outlined, 'Feedback & Report', 'Share your thoughts or report issues', 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Logout ---
            GradientButton(
              text: 'Logout',
              icon: Icons.logout_rounded,
              outline: true,
              onPressed: () => _handleLogout(context, ref),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
      child: Text(label, style: AppTypography.labelSmall),
    ),
  );

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.foreground)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.hint),
      onTap: onTap,
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.notifier).logout().then((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  void _showDelegationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DelegationDialog(),
    );
  }

  void _handleStopDelegation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Stop Delegation?', style: AppTypography.headingSmall),
        content: const Text('New requests will again be assigned to you directly.', style: TextStyle(color: AppColors.foreground)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).delegateRole(null);
            },
            child: const Text('Stop', style: TextStyle(color: AppColors.rejected, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
