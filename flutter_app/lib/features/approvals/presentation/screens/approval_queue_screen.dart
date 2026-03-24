import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/document_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../models/document_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../documents/presentation/screens/document_detail_screen.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../shared/widgets/branded_title.dart';

class ApprovalQueueScreen extends ConsumerStatefulWidget {
  const ApprovalQueueScreen({super.key});

  @override
  ConsumerState<ApprovalQueueScreen> createState() => _ApprovalQueueScreenState();
}

class _ApprovalQueueScreenState extends ConsumerState<ApprovalQueueScreen> {
  String _filter = 'Queue';
  final _filters = ['Queue', 'All', 'Pending', 'In Progress', 'Approved', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentListProvider);
    final user      = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const BrandedTitle(),
        actions: [
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
      body: MaxWidthWrapper(
        child: Column(
          children: [
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: _filters.map((f) {
                final sel = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.primaryGradient : null,
                        color: sel ? null : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? Colors.transparent : AppColors.border,
                        ),
                        boxShadow: sel
                            ? [BoxShadow(color: AppColors.glow, blurRadius: 10)]
                            : [],
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? Colors.white : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              onRefresh: () => ref.read(documentListProvider.notifier).refresh(),
              child: docsAsync.when(
                loading: () => _buildSkeleton(),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.rejected))),
                data: (docs) {
                  final filtered = _applyFilter(docs, user);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.done_all_rounded, size: 64, color: AppColors.hint),
                          const SizedBox(height: 16),
                          Text(
                            _filter == 'Queue' ? 'Queue is clear! 🎉' : 'No documents found.',
                            style: AppTypography.headingSmall,
                          ),
                          const SizedBox(height: 4),
                          Text('All caught up.', style: AppTypography.bodyMuted),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final doc = filtered[i];
                      return GlassCard(
                        padding: const EdgeInsets.all(16),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DocumentDetailScreen(document: doc),
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _priorityBadge(doc.priority),
                                const SizedBox(width: 8),
                                StatusBadge(status: doc.status.name),
                                const Spacer(),
                                Text(_fmt(doc.createdAt), style: AppTypography.caption),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(doc.title, style: AppTypography.headingSmall),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: AppColors.muted),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    doc.studentId is Map
                                        ? '${doc.studentId['name'] ?? 'Unknown'} · ${doc.studentId['dept'] ?? ''}'
                                        : 'Student: ${doc.studentId}',
                                    style: AppTypography.bodyMuted.copyWith(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  doc.flow ?? doc.category,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.muted),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  List<DocumentModel> _applyFilter(List<DocumentModel> docs, dynamic user) {
    if (_filter == 'Queue') {
      return docs.where((doc) {
        if (['finalApproved', 'rejected'].contains(doc.status.name)) return false;
        final nextIdx = doc.approvals.length;
        if (nextIdx >= doc.workflow.length) return false;
        final nextRole   = doc.workflow[nextIdx];
        final assignedId = doc.assigned[nextRole];
        return assignedId == user?.id || nextRole == user?.role;
      }).toList();
    }
    final map = {
      'Pending': DocumentStatus.pending,
      'In Progress': DocumentStatus.partiallyApproved,
      'Approved': DocumentStatus.finalApproved,
      'Rejected': DocumentStatus.rejected,
    };
    if (map.containsKey(_filter)) return docs.where((d) => d.status == map[_filter]).toList();
    return docs;
  }

  Widget _priorityBadge(PriorityLevel p) {
    final color = switch (p) {
      PriorityLevel.urgent => AppColors.rejected,
      PriorityLevel.high   => AppColors.pending,
      PriorityLevel.medium => AppColors.secondary,
      PriorityLevel.low    => AppColors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(p.name.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  String _fmt(DateTime? d) => d == null ? '' : '${d.day}/${d.month}';

  Widget _buildSkeleton() => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: LoadingLogo(size: 80),
    ),
  );
}
