import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/document_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../shared/widgets/branded_title.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import 'new_request_screen.dart';
import 'document_detail_screen.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const BrandedTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted, size: 22),
            onPressed: () => ref.read(documentListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
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
      ),
      body: MaxWidthWrapper(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: () async => ref.read(documentListProvider.notifier).refresh(),
          child: docsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingLogo(size: 80),
              ),
            ),
            error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.rejected))),
            data: (docs) {
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_edu_rounded, size: 64, color: AppColors.hint),
                        const SizedBox(height: 16),
                        Text('No requests yet', style: AppTypography.headingSmall),
                        const SizedBox(height: 6),
                        Text('Submit your first document request below.', style: AppTypography.bodyMuted, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        GradientButton(
                          text: 'Create Request',
                          icon: Icons.add_rounded,
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestScreen())),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc))),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
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
                              Text(doc.title, style: AppTypography.headingSmall.copyWith(fontSize: 14),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Text(
                                '${doc.flow ?? doc.category} · ${_fmt(doc.createdAt)}',
                                style: AppTypography.caption,
                              ),
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
        ),
      ),
    );
  }

  String _fmt(DateTime? d) => d == null ? '' : '${d.day}/${d.month}/${d.year}';
}
