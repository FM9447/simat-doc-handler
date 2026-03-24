import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../shared/widgets/branded_title.dart';

class DepartmentManagementScreen extends ConsumerStatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  ConsumerState<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends ConsumerState<DepartmentManagementScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _showAddDialog() {
    _nameCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        title: Text('Add Department', style: AppTypography.headingSmall),
        content: TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: AppColors.foreground),
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Department Name', hintText: 'e.g. Computer Science'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GradientButton(
            text: 'Add',
            icon: Icons.add_rounded,
            onPressed: () async {
              if (_nameCtrl.text.isNotEmpty) {
                await ref.read(adminDepartmentProvider.notifier).addDepartment(_nameCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
        ],
      ),
    );
  }

  void _showAssignHodDialog(String deptId, String? currentHodId) {
    showDialog(
      context: context,
      builder: (ctx) {
        final users = ref.watch(adminUserProvider).valueOrNull ?? [];
        final hods  = users.where((u) => u.role == 'hod').toList();
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
          title: Text('Assign HOD', style: AppTypography.headingSmall),
          content: hods.isEmpty
              ? Text('No users with HOD role found.', style: AppTypography.bodyMuted)
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: hods.length,
                    itemBuilder: (_, i) {
                      final hod = hods[i];
                      final selected = hod.id == currentHodId;
                      return ListTile(
                        title: Text(hod.name, style: TextStyle(color: selected ? AppColors.primary : AppColors.foreground)),
                        subtitle: Text(hod.email, style: AppTypography.caption),
                        trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.approved) : null,
                        onTap: () async {
                          await ref.read(adminDepartmentProvider.notifier).assignHod(deptId, hod.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(adminDepartmentProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const BrandedTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
            onPressed: () => ref.read(adminDepartmentProvider.notifier).getDepartments(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: MaxWidthWrapper(
        child: deptsAsync.when(
          data: (depts) {
          if (depts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business_outlined, size: 64, color: AppColors.hint),
                  const SizedBox(height: 16),
                  Text('No departments found', style: AppTypography.headingSmall),
                  const SizedBox(height: 24),
                  GradientButton(
                    text: 'Add First Department',
                    icon: Icons.add_rounded,
                    onPressed: _showAddDialog,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: depts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final dep  = depts[i];
              final hod  = dep['hodId'];
              return GlassCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
                  ),
                  title: Text(dep['name'], style: AppTypography.headingSmall.copyWith(fontSize: 15)),
                  subtitle: Text(
                    hod != null ? 'HOD: ${hod['name']}' : 'No HOD assigned',
                    style: TextStyle(
                      fontSize: 12,
                      color: hod != null ? AppColors.approved : AppColors.rejected,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.person_add_alt_1_outlined, size: 20, color: AppColors.primary),
                        onPressed: () => _showAssignHodDialog(dep['_id'], hod?['_id']),
                        tooltip: 'Assign HOD',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.rejected),
                        onPressed: () => _confirmDelete(dep['_id'], dep['name']),
                      ),
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
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        title: Text('Delete Department?', style: AppTypography.headingSmall),
        content: Text('Delete "$name"? This cannot be undone.', style: AppTypography.bodyMuted),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GradientButton(
            text: 'Delete',
            outline: true,
            onPressed: () async {
              await ref.read(adminDepartmentProvider.notifier).deleteDepartment(id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ],
      ),
    );
  }
}
