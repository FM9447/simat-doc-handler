import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/responsive_layout.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState    = ref.watch(notificationProvider);
    final notifications = notifState.notifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: AppTypography.headingSmall),
        actions: [
          if (notifications.any((n) => !n.read))
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllRead(),
              child: const Text('Mark all read', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
      body: MaxWidthWrapper(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
        onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
        child: notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.hint),
                    const SizedBox(height: 16),
                    Text('No notifications yet', style: AppTypography.headingSmall),
                    const SizedBox(height: 4),
                    Text('You\'re all caught up!', style: AppTypography.bodyMuted),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n     = notifications[index];
                  final color = _typeColor(n.type);

                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withOpacity(0.25)),
                          ),
                          child: Icon(_typeIcon(n.type), size: 18, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: n.read ? FontWeight.normal : FontWeight.w600,
                                  color: n.read ? AppColors.muted : AppColors.foreground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_formatTime(n.createdAt), style: AppTypography.caption),
                            ],
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(top: 4, left: 8),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: color,
                                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      ),
    );
  }

  Color _typeColor(String type) {
    if (type.contains('err')) return AppColors.rejected;
    if (type.contains('ok')) return AppColors.approved;
    return AppColors.secondary;
  }

  IconData _typeIcon(String type) {
    if (type.contains('err')) return Icons.error_outline_rounded;
    if (type.contains('ok')) return Icons.check_circle_outline_rounded;
    return Icons.notifications_none_rounded;
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
