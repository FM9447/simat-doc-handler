import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/duty_category_provider.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../models/duty_category_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/branded_title.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/loading_logo.dart';

class DutyCategoryManagementScreen extends ConsumerStatefulWidget {
  const DutyCategoryManagementScreen({super.key});

  @override
  ConsumerState<DutyCategoryManagementScreen> createState() => _DutyCategoryManagementScreenState();
}

class _DutyCategoryManagementScreenState extends ConsumerState<DutyCategoryManagementScreen> {

  void _showAddEditDialog([DutyCategoryModel? category]) {
    final isEditing = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final codeCtrl = TextEditingController(text: category?.code ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    String? selectedFacultyId = category?.facultyInCharge?['_id'] ?? category?.facultyInCharge?['id'];
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final usersAsync = ref.watch(adminUserProvider);
          final staffList = usersAsync.maybeWhen(
            data: (users) => users.where((u) => u.role != 'student' && u.isApproved).toList(),
            orElse: () => [],
          );

          return AlertDialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
            title: Text(isEditing ? 'Edit Category' : 'Create Duty Category', style: AppTypography.headingSmall),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.foreground),
                    decoration: const InputDecoration(labelText: 'Category Name *', hintText: 'e.g. IEDC, NSS, MuLearn'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codeCtrl,
                    style: const TextStyle(color: AppColors.foreground),
                    decoration: const InputDecoration(labelText: 'Category Code *', hintText: 'e.g. iedc, nss, mulearn'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    style: const TextStyle(color: AppColors.foreground),
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', hintText: 'e.g. Nodal Officer managed activities'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedFacultyId,
                    decoration: const InputDecoration(labelText: 'Assign Faculty In-Charge / Nodal Officer'),
                    dropdownColor: AppColors.card,
                    style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                    hint: const Text('Choose Staff Member', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None (Unassigned)')),
                      ...staffList.map((u) => DropdownMenuItem(
                        value: u.id,
                        child: Text('${u.name} (${u.role.toUpperCase()})'),
                      )),
                    ],
                    onChanged: (v) => setS(() => selectedFacultyId = v),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: Text('Active Category', style: AppTypography.bodyMedium),
                    value: isActive,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setS(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              GradientButton(
                text: isEditing ? 'Save Changes' : 'Create',
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  if (isEditing) {
                    await ref.read(dutyCategoryNotifierProvider.notifier).updateCategory(
                      id: category.id,
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      facultyInChargeId: selectedFacultyId,
                      isActive: isActive,
                    );
                  } else {
                    await ref.read(dutyCategoryNotifierProvider.notifier).createCategory(
                      name: nameCtrl.text.trim(),
                      code: codeCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      facultyInChargeId: selectedFacultyId,
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(dutyCategoryNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const BrandedTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
            onPressed: () => ref.read(dutyCategoryNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: MaxWidthWrapper(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(dutyCategoryNotifierProvider.notifier).refresh(),
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_ind_outlined, size: 64, color: AppColors.hint),
                      const SizedBox(height: 16),
                      Text('No Duty Leave Categories', style: AppTypography.headingSmall),
                      const SizedBox(height: 8),
                      Text('Tap "+ Add Category" to assign Faculty In-Charge for IEDC, NSS, MuLearn, etc.',
                          style: AppTypography.bodyMuted, textAlign: TextAlign.center),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final facultyName = cat.facultyInCharge != null
                      ? cat.facultyInCharge!['name'] ?? 'Assigned'
                      : 'Unassigned';

                  return GlassCard(
                    padding: EdgeInsets.zero,
                    onTap: () => _showAddEditDialog(cat),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.stars_rounded, color: AppColors.primary, size: 22),
                      ),
                      title: Text(cat.name, style: AppTypography.headingSmall.copyWith(fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_pin_rounded, size: 14, color: AppColors.muted),
                              const SizedBox(width: 4),
                              Text('In-Charge: $facultyName', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (cat.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(cat.description, style: AppTypography.caption),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rejected, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  backgroundColor: AppColors.card,
                                  title: const Text('Delete Category?'),
                                  content: Text('Are you sure you want to delete ${cat.name}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: AppColors.rejected))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(dutyCategoryNotifierProvider.notifier).deleteCategory(cat.id);
                              }
                            },
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: LoadingLogo(size: 80)),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.rejected))),
          ),
        ),
      ),
    );
  }
}
