import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../shared/widgets/branded_title.dart';
import 'department_management_screen.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  final bool showPendingOnly;
  const UserManagementScreen({super.key, this.showPendingOnly = false});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const BrandedTitle(),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.business_outlined, color: AppColors.primary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DepartmentManagementScreen())),
            tooltip: 'Manage Departments',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
            onPressed: () => ref.read(adminUserProvider.notifier).getUsers(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: const TextStyle(color: AppColors.foreground),
              decoration: const InputDecoration(
                hintText: 'Search by name or email…',
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.muted),
              ),
            ),
          ),
        ),
      ),
      body: MaxWidthWrapper(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: () => ref.read(adminUserProvider.notifier).getUsers(),
          child: usersAsync.when(
          data: (users) {
            final filtered = users
                .where((u) =>
                    (u.name.toLowerCase().contains(_searchQuery) || u.email.toLowerCase().contains(_searchQuery)) &&
                    (!widget.showPendingOnly || !u.isApproved))
                .toList();

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 64, color: AppColors.hint),
                    const SizedBox(height: 16),
                    Text(widget.showPendingOnly ? 'No pending approvals' : 'No users found',
                        style: AppTypography.headingSmall),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = filtered[index];
                final roleC = AppColors.roleColor(user.role);

                return GlassCard(
                  padding: EdgeInsets.zero,
                  onTap: () => _showEditDialog(context, user),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: roleC.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: roleC.withOpacity(0.3)),
                      ),
                      child: Icon(
                        user.role == 'student' ? Icons.school_rounded : Icons.person_rounded,
                        color: roleC, size: 20,
                      ),
                    ),
                    title: Text(user.name, style: AppTypography.headingSmall.copyWith(fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(user.email, style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _roleChip(user.role),
                            if (!['office', 'principal', 'admin'].contains(user.role.toLowerCase())) ...[
                              const SizedBox(width: 8),
                              if (user.dept != null)
                                Text(user.dept!, style: AppTypography.caption.copyWith(fontSize: 11)),
                              if (user.role == 'student' && user.year != null) ...[
                                const SizedBox(width: 6),
                                Text('Y${user.year}${user.division ?? ''}',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ],
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user.isApproved && !['admin', 'principal', 'student'].contains(user.role.toLowerCase()))
                          IconButton(
                            icon: const Icon(Icons.star_outline_rounded, color: AppColors.secondary, size: 20),
                            onPressed: () => _showPrincipalDialog(context, user),
                            tooltip: 'Set as Principal',
                          ),
                        !user.isApproved
                            ? StatusBadge(status: 'pending')
                            : const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: LoadingLogo(size: 80)),
          error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AppColors.rejected))),
        ),
      ),
      ),
    );
  }

  Widget _roleChip(String role) {
    final c = AppColors.roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(role.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: c)),
    );
  }

  void _showEditDialog(BuildContext ctx, UserModel user) {
    String  selectedRole = user.role.toLowerCase();
    String? selectedDeptId = user.departmentId;
    int?    selectedYear = user.year;
    String? selectedDivision = user.division;
    bool    isApproved = user.isApproved;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final depts = ref.watch(adminDepartmentProvider).valueOrNull ?? [];
          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
            title: Text('Edit ${user.name}', style: AppTypography.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                    items: (selectedRole == 'principal' || selectedRole == 'admin' 
                        ? ['student', 'tutor', 'hod', 'principal', 'office', 'admin'] 
                        : ['student', 'tutor', 'hod', 'office'])
                        .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                    onChanged: (v) => setS(() => selectedRole = v!),
                  ),
                  if (!['office', 'principal', 'admin'].contains(selectedRole)) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(labelText: 'Department'),
                      dropdownColor: AppColors.card,
                      hint: const Text('Select Department', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      items: depts.map((d) => DropdownMenuItem(value: d['_id'].toString(), child: Text(d['name'].toString()))).toList(),
                      onChanged: (v) => setS(() => selectedDeptId = v),
                    ),
                  ],
                  if (selectedRole == 'student') ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(labelText: 'Year'),
                      dropdownColor: AppColors.card,
                      items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                      onChanged: (v) => setS(() => selectedYear = v),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: Text('Has Division?', style: AppTypography.bodyMedium),
                      value: selectedDivision != null,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setS(() => selectedDivision = v ? 'A' : null),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (selectedDivision != null) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDivision,
                        decoration: const InputDecoration(labelText: 'Division'),
                        dropdownColor: AppColors.card,
                        items: ['A', 'B'].map((d) => DropdownMenuItem(value: d, child: Text('Div $d'))).toList(),
                        onChanged: (v) => setS(() => selectedDivision = v),
                      ),
                    ],
                  ],
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: Text('Account Approved', style: AppTypography.bodyMedium),
                    value: isApproved,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setS(() => isApproved = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: Text('Delete User?', style: AppTypography.headingSmall),
                      content: const Text('This action cannot be undone.', style: TextStyle(color: AppColors.muted)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        GradientButton(text: 'Delete', outline: true,
                            onPressed: () => Navigator.pop(c, true),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(adminUserProvider.notifier).deleteUser(user.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rejected, size: 18),
                label: const Text('Delete', style: TextStyle(color: AppColors.rejected)),
              ),
              if ((user.role != 'principal' || !user.isApproved) && user.role != 'student')
                TextButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: Text('Set as Principal?', style: AppTypography.headingSmall),
                        content: Text('This will set ${user.name} as the school principal and de-activate others.', style: const TextStyle(color: AppColors.muted)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          GradientButton(text: 'Establish',
                              onPressed: () => Navigator.pop(c, true),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(adminUserProvider.notifier).updateUser(user.id, {
                        'role': 'principal',
                        'isApproved': true,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  icon: const Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
                  label: const Text('Set Principal', style: TextStyle(color: AppColors.primary)),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  GradientButton(
                    text: 'Save',
                    icon: Icons.check_rounded,
                    onPressed: () async {
                      await ref.read(adminUserProvider.notifier).updateUser(user.id, {
                        'role': selectedRole, 'departmentId': selectedDeptId,
                        'year': selectedYear, 'division': selectedDivision, 'isApproved': isApproved,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPrincipalDialog(BuildContext ctx, UserModel user) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set as Principal?', style: AppTypography.headingSmall),
        content: Text('This will set ${user.name} as the school principal and de-activate others.', style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          GradientButton(
            text: 'Establish',
            onPressed: () async {
              Navigator.pop(c);
              await ref.read(adminUserProvider.notifier).updateUser(user.id, {
                'role': 'principal',
                'isApproved': true,
              });
            },
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ],
      ),
    );
  }
}
