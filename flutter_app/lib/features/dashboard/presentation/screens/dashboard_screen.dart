import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/document_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../documents/presentation/screens/new_request_screen.dart';
import '../../../documents/presentation/screens/document_detail_screen.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../shared/widgets/branded_title.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(authProvider).value;
    final docsAsync = ref.watch(documentListProvider);
    final isStudent = user?.role == 'student';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const BrandedTitle(),
        actions: [
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: isStudent
          ? GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: AppColors.glow, blurRadius: 20, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('New Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            )
          : null,
      body: MaxWidthWrapper(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: () async {
            ref.read(documentListProvider.notifier).refresh();
            ref.read(notificationProvider.notifier).fetchNotifications();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, ${user?.name.split(' ').first ?? 'User'} 👋',
                            style: AppTypography.headingLarge,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.roleColor(user?.role ?? '').withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.roleColor(user?.role ?? '').withOpacity(0.3)),
                                ),
                                child: Text(
                                  (user?.role ?? '').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppColors.roleColor(user?.role ?? ''),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              if (user?.departmentName != null) ...[
                                const SizedBox(width: 8),
                                Text('· ${user!.departmentName}', style: AppTypography.caption),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Stats Row
                docsAsync.when(
                  loading: () => const SizedBox.shrink(), // Wait for list loader below
                  error: (_, __) => const SizedBox.shrink(),
                  data: (docs) {
                    final pending  = docs.where((d) => d.status == 'pending' || d.status == 'partially_approved').length;
                    final approved = docs.where((d) => d.status == 'final_approved').length;
                    final rejected = docs.where((d) => d.status == 'rejected').length;
                    return Row(
                      children: [
                        Expanded(child: _StatCard(label: 'Total', value: docs.length, color: AppColors.primary)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(label: 'Pending', value: pending, color: AppColors.pending)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(label: 'Approved', value: approved, color: AppColors.approved)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCard(label: 'Rejected', value: rejected, color: AppColors.rejected)),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Quick actions (student only)
                if (isStudent) ...[
                  Text('QUICK ACTIONS', style: AppTypography.labelSmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(
                          text: 'New Request',
                          icon: Icons.note_add_outlined,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestScreen())),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],

                // Recent Docs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT DOCUMENTS', style: AppTypography.labelSmall),
                    docsAsync.maybeWhen(
                      data: (docs) => Text('${docs.length} total', style: AppTypography.caption),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                docsAsync.when(
                  loading: () => const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: LoadingLogo(size: 80),
                  )),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text('Error: $e', style: const TextStyle(color: AppColors.rejected)),
                    ),
                  ),
                  data: (docs) {
                    if (docs.isEmpty) {
                      return GlassCard(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.description_outlined, size: 48, color: AppColors.hint),
                            const SizedBox(height: 12),
                            Text('Welcome to DocTransit', style: AppTypography.headingMedium),
                            const SizedBox(height: 4),
                            Text('Submit your first document request to get started.', style: AppTypography.bodyMuted, textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length.clamp(0, 7),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        return GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.article_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(doc.title, style: AppTypography.headingSmall.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text(doc.flow ?? doc.category, style: AppTypography.caption),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              StatusBadge(status: doc.status.name),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}
