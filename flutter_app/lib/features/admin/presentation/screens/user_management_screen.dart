import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../models/user_model.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';

  void _showEditDialog(BuildContext context, UserModel user) {
    final roleController = TextEditingController(text: user.role);
    final deptController = TextEditingController(text: user.dept ?? '');
    bool isApproved = user.isApproved;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roleController,
                decoration: const InputDecoration(
                    labelText:
                        'Role (student/teacher/hod/principal/office/admin)'),
              ),
              TextField(
                controller: deptController,
                decoration:
                    const InputDecoration(labelText: 'Department (optional)'),
              ),
              Row(
                children: [
                  const Text('Account Approved'),
                  const Spacer(),
                  StatefulBuilder(builder: (context, setState) {
                    return Switch(
                        value: isApproved,
                        onChanged: (v) => setState(() => isApproved = v));
                  }),
                ],
              )
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final role = roleController.text.trim().toLowerCase();
                final dept = deptController.text.trim();

                try {
                  await ref.read(adminUserProvider.notifier).updateUser(
                    user.id,
                    {
                      'role': role,
                      'dept': dept.isEmpty ? null : dept,
                      'isApproved': isApproved,
                    },
                  );
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminUserProvider.notifier).getUsers(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: usersAsync.when(
        data: (users) {
          final filteredUsers = users
              .where((u) =>
                  u.name.toLowerCase().contains(_searchQuery) ||
                  u.email.toLowerCase().contains(_searchQuery))
              .toList();

          if (filteredUsers.isEmpty)
            return const Center(child: Text('No users found.'));

          return ListView.separated(
            itemCount: filteredUsers.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isApproved
                      ? Colors.green.shade50
                      : Colors.grey.shade200,
                  child: Icon(
                    user.role == 'student' ? Icons.school : Icons.person,
                    color: user.isApproved ? Colors.green : Colors.grey,
                  ),
                ),
                title: Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${user.email}\nRole: ${user.role.toUpperCase()} • Dept: ${user.dept ?? 'N/A'}'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showEditDialog(context, user);
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete user?'),
                          content: Text('Delete ${user.name}?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await ref
                              .read(adminUserProvider.notifier)
                              .deleteUser(user.id);
                        } catch (e) {
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
