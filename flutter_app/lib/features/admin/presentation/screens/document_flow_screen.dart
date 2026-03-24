import '../../../../shared/widgets/notification_bell.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../widgets/workflow_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/workflow_model.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../shared/widgets/branded_title.dart';

class DocumentFlowScreen extends ConsumerStatefulWidget {
  const DocumentFlowScreen({super.key});

  @override
  ConsumerState<DocumentFlowScreen> createState() => _DocumentFlowScreenState();
}

class _DocumentFlowScreenState extends ConsumerState<DocumentFlowScreen> {
  @override
  Widget build(BuildContext context) {
    final workflowsAsync = ref.watch(adminWorkflowProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const BrandedTitle(),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showFlowDialog(context),
            tooltip: 'New Flow',
          ),
        ],
      ),
      body: MaxWidthWrapper(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: () => ref.read(adminWorkflowProvider.notifier).getWorkflows(),
          child: workflowsAsync.when(
          data: (flows) {
            if (flows.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_tree_outlined, size: 64, color: AppColors.hint),
                    const SizedBox(height: 16),
                    Text('No document flows yet', style: AppTypography.headingSmall),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Create First Flow',
                      icon: Icons.add_rounded,
                      onPressed: () => _showFlowDialog(context),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: flows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final flow = flows[index];
                final hasTemplate   = flow.letterTemplate.isNotEmpty;
                final fieldElements = flow.elements.where((e) => e.kind == 'field').toList();

                return GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.account_tree_rounded, color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(flow.name, style: AppTypography.headingSmall.copyWith(fontSize: 17)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                            onPressed: () => _showFlowDialog(context, flow: flow),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.rejected),
                            onPressed: () => _deleteFlow(flow.id!),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Approval steps
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < flow.steps.length; i++) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  flow.steps[i].toUpperCase(),
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              if (i < flow.steps.length - 1)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.hint),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Bottom row: fields + feature flags
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('FIELDS (${fieldElements.length})',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                                        color: AppColors.hint, letterSpacing: 1.1)),
                                const SizedBox(height: 6),
                                if (fieldElements.isEmpty)
                                  Text('File-based (no form fields)', style: AppTypography.caption)
                                else
                                  Wrap(
                                    spacing: 6, runSpacing: 4,
                                    children: fieldElements.map((e) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(e.label ?? 'unnamed',
                                          style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                                    )).toList(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _featurePill('Template', hasTemplate, AppColors.approved),
                              const SizedBox(height: 4),
                              _featurePill('Letterhead', flow.includeLetterhead, AppColors.pending),
                            ],
                          ),
                        ],
                      ),
                    ],
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

  Widget _featurePill(String label, bool active, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: active ? color : AppColors.hint)),
        const SizedBox(width: 4),
        Icon(active ? Icons.check_circle : Icons.circle_outlined, size: 13,
            color: active ? color : AppColors.hint),
      ],
    );
  }

  void _deleteFlow(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        title: Text('Delete Flow?', style: AppTypography.headingSmall),
        content: Text('This will permanently remove this document workflow.', style: AppTypography.bodyMuted),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          GradientButton(
            text: 'Delete',
            outline: true,
            onPressed: () => Navigator.pop(ctx, true),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(adminWorkflowProvider.notifier).deleteWorkflow(id);
    }
  }

  void _showFlowDialog(BuildContext context, {WorkflowModel? flow}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WorkflowEditorDialog(flow: flow),
    );
  }
}
