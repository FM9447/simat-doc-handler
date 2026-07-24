import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../providers/duty_category_provider.dart';
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
import '../../../../services/api_service.dart';
import 'department_management_screen.dart';
import 'duty_category_management_screen.dart';

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
            icon: const Icon(Icons.assignment_ind_outlined, color: AppColors.secondary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DutyCategoryManagementScreen())),
            tooltip: 'Clubs & Duty Categories (IEEE, IEDC, NSS, etc.)',
          ),
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: roleC.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: roleC.withOpacity(0.3)),
                        ),
                        child: Icon(
                          user.role == 'student' ? Icons.school_rounded : Icons.person_rounded,
                          color: roleC,
                          size: 20,
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
                                  Text(
                                    'Y${user.year}${user.division ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (user.isApproved && ['tutor', 'hod', 'office'].contains(user.role.toLowerCase()))
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => _showPrincipalDialog(context, user),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.stars_rounded, color: AppColors.primary, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Make Principal',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
            loading: () => const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(child: LoadingLogo(size: 80)),
              ),
            ),
            error: (e, _) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.rejected))),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import_excel',
            onPressed: () => _importExcel(context),
            backgroundColor: const Color(0xFF1e1e2e),
            foregroundColor: AppColors.secondary,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: const Text('Import Excel', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_user',
            onPressed: () => _showAddUserDialog(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: const Text('Add User', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String role) {
    final c = AppColors.roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(role.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: c)),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADD USER DIALOG
  // ──────────────────────────────────────────────────────────────────────────
  void _showAddUserDialog(BuildContext ctx) {
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwCtrl    = TextEditingController();
    final regCtrl   = TextEditingController();
    final deptCtrl  = TextEditingController();
    String selectedRole = 'student';
    int? selectedYear;
    String? selectedDivision;
    String? selectedDeptId;
    String? selectedTutorId;
    bool isLoading = false;
    final formKey  = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setS) {
          final depts   = ref.watch(adminDepartmentProvider).valueOrNull ?? [];
          final allUsers = ref.watch(adminUserProvider).valueOrNull ?? [];
          final tutors   = allUsers.where((u) => u.role == 'tutor').toList();

          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
            title: Row(
              children: [
                const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Add New User', style: AppTypography.headingSmall),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        style: const TextStyle(color: AppColors.foreground),
                        decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline, size: 18)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.foreground),
                        decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined, size: 18)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: pwCtrl,
                        obscureText: true,
                        style: const TextStyle(color: AppColors.foreground),
                        decoration: const InputDecoration(labelText: 'Password *', prefixIcon: Icon(Icons.lock_outline, size: 18)),
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role *'),
                        dropdownColor: AppColors.card,
                        style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                        items: ['student', 'tutor', 'hod', 'office', 'principal', 'admin']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                            .toList(),
                        onChanged: (v) => setS(() => selectedRole = v!),
                      ),
                      if (!['office', 'principal', 'admin'].contains(selectedRole)) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedDeptId,
                          decoration: const InputDecoration(labelText: 'Department'),
                          dropdownColor: AppColors.card,
                          hint: const Text('Select Department', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          items: depts.map((d) => DropdownMenuItem(value: d['_id'].toString(), child: Text(d['name'].toString()))).toList(),
                          onChanged: (v) => setS(() => selectedDeptId = v),
                        ),
                      ],
                      if (selectedRole == 'student') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: regCtrl,
                          style: const TextStyle(color: AppColors.foreground),
                          decoration: const InputDecoration(labelText: 'Register No.', prefixIcon: Icon(Icons.badge_outlined, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: deptCtrl,
                          style: const TextStyle(color: AppColors.foreground),
                          decoration: const InputDecoration(labelText: 'Dept (short, e.g. CSE)', prefixIcon: Icon(Icons.school_outlined, size: 18)),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: const InputDecoration(labelText: 'Year'),
                          dropdownColor: AppColors.card,
                          hint: const Text('Select Year', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          items: [1, 2, 3, 4].map((y) => DropdownMenuItem(value: y, child: Text('Year $y'))).toList(),
                          onChanged: (v) => setS(() => selectedYear = v),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedDivision,
                          decoration: const InputDecoration(labelText: 'Division (optional)'),
                          dropdownColor: AppColors.card,
                          hint: const Text('None', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          items: ['A', 'B'].map((d) => DropdownMenuItem(value: d, child: Text('Div $d'))).toList(),
                          onChanged: (v) => setS(() => selectedDivision = v),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedTutorId,
                          decoration: const InputDecoration(labelText: 'Assign Tutor (optional)'),
                          dropdownColor: AppColors.card,
                          hint: const Text('Select Tutor', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          items: tutors.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                          onChanged: (v) => setS(() => selectedTutorId = v),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancel')),
              GradientButton(
                text: isLoading ? 'Creating…' : 'Create User',
                icon: Icons.check_rounded,
                onPressed: isLoading ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setS(() => isLoading = true);
                  try {
                    await apiService.post('/auth/admin/create-user', {
                      'name': nameCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'password': pwCtrl.text.trim(),
                      'role': selectedRole,
                      if (regCtrl.text.trim().isNotEmpty) 'registerNo': regCtrl.text.trim(),
                      if (deptCtrl.text.trim().isNotEmpty) 'dept': deptCtrl.text.trim(),
                      if (selectedDeptId != null) 'departmentId': selectedDeptId,
                      if (selectedTutorId != null) 'tutorId': selectedTutorId,
                      if (selectedYear != null) 'year': selectedYear,
                      if (selectedDivision != null) 'division': selectedDivision,
                    });
                    if (ctx2.mounted) {
                      Navigator.pop(ctx2);
                      ref.read(adminUserProvider.notifier).getUsers();
                      ScaffoldMessenger.of(ctx2).showSnackBar(
                        const SnackBar(content: Text('✅ User created successfully'), backgroundColor: AppColors.approved),
                      );
                    }
                  } catch (e) {
                    setS(() => isLoading = false);
                    if (ctx2.mounted) {
                      ScaffoldMessenger.of(ctx2).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rejected),
                      );
                    }
                  }
                },
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // IMPORT EXCEL
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _importExcel(BuildContext ctx) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    if (!ctx.mounted) return;

    // Show loading
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: AppColors.card,
        content: Padding(
          padding: EdgeInsets.all(24),
          child: Row(children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 20),
            Text('Importing users…', style: TextStyle(color: AppColors.foreground)),
          ]),
        ),
      ),
    );

    try {
      final response = await apiService.multipartPost(
        '/auth/admin/bulk-import',
        {},
        fileField: 'file',
        bytes: file.bytes,
        fileName: file.name,
      ) as Map<String, dynamic>;

      if (ctx.mounted) {
        Navigator.pop(ctx); // close loading
        ref.read(adminUserProvider.notifier).getUsers();

        final created  = response['created'] ?? 0;
        final skipped  = response['skipped'] ?? 0;
        final errors   = (response['errors'] as List?)?.cast<String>() ?? [];

        showDialog(
          context: ctx,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.summarize_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Import Results', style: AppTypography.headingSmall),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _importResultRow('✅ Created', '$created users', AppColors.approved),
                _importResultRow('⏭ Skipped', '$skipped (already exist)', AppColors.secondary),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('⚠️ ${errors.length} error(s):', style: const TextStyle(color: AppColors.rejected, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: errors.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $e', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              GradientButton(text: 'Done', onPressed: () => Navigator.pop(ctx), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            ],
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        Navigator.pop(ctx); // close loading
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: AppColors.rejected),
        );
      }
    }
  }

  Widget _importResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }



  void _showEditDialog(BuildContext ctx, UserModel user) {
    String selectedRole = user.role.toLowerCase();
    String? selectedDeptId = user.departmentId;
    int? selectedYear = user.year;
    String? selectedDivision = user.division;
    bool isApproved = user.isApproved;


    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final depts = ref.watch(adminDepartmentProvider).valueOrNull ?? [];
          final categories = ref.watch(dutyCategoryNotifierProvider).valueOrNull ?? [];
          final assignedCategories = categories.where((c) {
            final fId = c.facultyInCharge?['_id'] ?? c.facultyInCharge?['id'];
            return fId == user.id;
          }).toList();

          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            title: Row(
              children: [
                Expanded(child: Text('Edit ${user.name}', style: AppTypography.headingSmall)),
                if (user.role.toLowerCase() != 'principal')
                  IconButton(
                    icon: const Icon(Icons.stars_rounded, color: AppColors.primary),
                    tooltip: 'Promote to Principal',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showPrincipalDialog(context, user);
                    },
                  ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                    items: ['student', 'tutor', 'hod', 'principal', 'office', 'admin']
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r == 'principal' ? 'PRINCIPAL (HEAD OF INST.)' : r.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (v) => setS(() => selectedRole = v!),
                  ),
                  if (!['office', 'principal', 'admin'].contains(selectedRole)) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedDeptId,
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
                      value: selectedYear,
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
                        value: selectedDivision,
                        decoration: const InputDecoration(labelText: 'Division'),
                        dropdownColor: AppColors.card,
                        items: ['A', 'B'].map((d) => DropdownMenuItem(value: d, child: Text('Div $d'))).toList(),
                        onChanged: (v) => setS(() => selectedDivision = v),
                      ),
                    ],
                  ],

                  // Staff Club / Organization Assignment section
                  if (selectedRole != 'student') ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 8),
                    Text('Club / Organization In-Charge', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      assignedCategories.isNotEmpty
                          ? 'Currently In-Charge of: ${assignedCategories.map((c) => c.name).join(', ')}'
                          : 'Not assigned to any Club or Organization',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DutyCategoryManagementScreen()),
                        );
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Manage & Assign Clubs', style: TextStyle(fontSize: 12)),
                    ),
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
                  final bool isStaff = !['student', 'admin'].contains(user.role.toLowerCase());
                  String? reassignedToId;

                  if (isStaff) {
                    final allUsers = ref.read(adminUserProvider).value ?? [];
                    final candidates = allUsers.where((u) => u.id != user.id && u.role == user.role && u.isApproved).toList();

                    if (candidates.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Cannot delete this ${user.role.toUpperCase()} yet. Please ensure there is another approved ${user.role.toUpperCase()} to take over their duties first.')),
                      );
                      return;
                    }

                    reassignedToId = await showDialog<String>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: Text('Reassign Duties', style: AppTypography.headingSmall),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deleting ${user.name} (${user.role.toUpperCase()}) requires reassigning their pending requests and students.',
                                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                            const SizedBox(height: 16),
                            const Text('Select Replacement staff:', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.maxFinite,
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Assign to'),
                                dropdownColor: AppColors.card,
                                items: candidates.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                                onChanged: (v) => reassignedToId = v,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                          GradientButton(
                              text: 'Reassign & Delete',
                              onPressed: () => Navigator.pop(c, reassignedToId),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                        ],
                      ),
                    );

                    if (reassignedToId == null) return;
                  } else {
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (c) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: Text('Delete User?', style: AppTypography.headingSmall),
                        content: const Text('This action cannot be undone.', style: TextStyle(color: AppColors.muted)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          GradientButton(
                              text: 'Delete',
                              outline: true,
                              onPressed: () => Navigator.pop(c, true),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                  }

                  await ref.read(adminUserProvider.notifier).deleteUser(user.id, reassignToId: reassignedToId);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rejected, size: 18),
                label: const Text('Delete', style: TextStyle(color: AppColors.rejected)),
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
                        'role': selectedRole,
                        'departmentId': selectedDeptId,
                        'year': selectedYear,
                        'division': selectedDivision,
                        'isApproved': isApproved,
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
        content: Text('This will set ${user.name} as the school principal and de-activate others.',
            style: const TextStyle(color: AppColors.muted)),
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
