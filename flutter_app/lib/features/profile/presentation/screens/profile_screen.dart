import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../auth/presentation/screens/change_password_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'signature_setup_screen.dart';
import 'package:antigravity/features/admin/presentation/screens/user_management_screen.dart';
import 'package:antigravity/features/admin/presentation/screens/document_flow_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);
    final user = userAsync.valueOrNull;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout().then((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(user.name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('${user.role.toUpperCase()} • ${user.dept ?? 'N/A'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            if (user.registerNo != null) ...[
              const SizedBox(height: 4),
              Text('Reg No: ${user.registerNo}',
                  style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 32),

            // Signature Setup Card
            if (user.role != 'student') ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.draw, color: Colors.blue),
                  title: const Text('Digital Signature'),
                  subtitle: Text(user.signatureUrl != null
                      ? 'Signature is configured'
                      : 'Not configured. Tap to setup.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SignatureSetupScreen()));
                  },
                ),
              ),
              if (user.signatureUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Image.network(
                      user.signatureUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                              child:
                                  Icon(Icons.error_outline, color: Colors.red)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],

            if (user.role == 'admin') ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Text('Admin Panel',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.people_alt, color: Colors.blue),
                      title: const Text('User Management'),
                      subtitle: const Text('Manage user roles and accounts'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UserManagementScreen()));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.account_tree_outlined,
                          color: Colors.orange),
                      title: const Text('Document Flow'),
                      subtitle:
                          const Text('Manage document flow and approval steps'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DocumentFlowScreen()));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notification Settings'),
                    trailing: Switch(
                      value: ref.watch(notificationProvider).isEnabled,
                      onChanged: (val) => ref
                          .read(notificationProvider.notifier)
                          .toggleNotifications(val),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                ref.read(authProvider.notifier).logout().then((_) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
