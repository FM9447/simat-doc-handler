import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/document_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../models/document_model.dart';
import '../../../../models/user_model.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';
import '../../../documents/presentation/screens/new_request_screen.dart';
import '../../../documents/presentation/screens/document_detail_screen.dart';
import '../../../../providers/navigation_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentListProvider);
    final userAsync = ref.watch(authProvider);

    final user = userAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AntiGravity'),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(documentListProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, ${user?.name.split(" ").first ?? "User"} 👋',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 24),
              // Stats Cards
              _buildStats(docsAsync, user),
              const SizedBox(height: 32),
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.add, color: Colors.white),
                      label: const Text('New Request'),
                      labelStyle: const TextStyle(color: Colors.white),
                      backgroundColor: AppConstants.primaryColor,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestScreen()));
                      },
                    ),
                    const SizedBox(width: 12),
                    ActionChip(
                      avatar: const Icon(Icons.history),
                      label: const Text('History'),
                      onPressed: () {
                        ref.read(navigationProvider.notifier).setIndex(1);
                      },
                    ),
                    const SizedBox(width: 12),
                    if (user?.role != 'student')
                      ActionChip(
                        avatar: const Icon(Icons.flash_on, color: AppConstants.secondaryColor),
                        label: const Text('High Priority'),
                        onPressed: () {},
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              docsAsync.when(
                data: (docs) {
                  if (docs.isEmpty) return const Center(child: Text('No recent activity'));
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length > 5 ? 5 : docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final doc = docs[docs.length - 1 - index]; // Reverse chronological
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: const Icon(Icons.description, color: Colors.blue),
                        ),
                        title: Text(doc.title),
                        subtitle: Text('${doc.category} • ${doc.status.name.toUpperCase()}'),
                        trailing: Text(doc.priority.name, style: TextStyle(color: doc.priority.name == 'urgent' ? Colors.red : Colors.grey)),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DocumentDetailScreen(document: doc),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => _buildShimmerList(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: user?.role == 'student' ? SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 12,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            elevation: 2,
            child: const Icon(Icons.description),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'New Request',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestScreen()));
            },
          ),
          SpeedDialChild(
            elevation: 2,
            child: const Icon(Icons.document_scanner),
            backgroundColor: AppConstants.secondaryColor,
            foregroundColor: Colors.white,
            label: 'Scan Document',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestScreen()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanning simulation: Capture document now.')));
            },
          ),
        ],
      ) : null,
    );
  }

  Widget _buildStats(AsyncValue<List<DocumentModel>> docs, UserModel? user) {
    if (docs.isLoading) {
      return _buildShimmerLoading();
    }

    final data = docs.value ?? [];
    final awaiting = data.where((d) => d.status == DocumentStatus.pending || d.status == DocumentStatus.officePending || d.status == DocumentStatus.partiallyApproved).length;
    final approved = data.where((d) => d.status == DocumentStatus.finalApproved).length;
    final rejected = data.where((d) => d.status == DocumentStatus.rejected).length;

    final isTeacher = user?.role == 'teacher';

    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Awaiting', count: awaiting, color: Colors.orange, icon: Icons.assignment_late_outlined)),
        if (!isTeacher) ...[
          const SizedBox(width: 12),
          Expanded(child: _StatCard(title: 'Approved', count: approved, color: Colors.green, icon: Icons.check_circle_outline)),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(title: 'Rejected', count: rejected, color: Colors.red, icon: Icons.cancel_outlined)),
        ],
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Row(
        children: List.generate(3, (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 100,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          ),
        )),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.white),
          title: Container(height: 16, color: Colors.white),
          subtitle: Container(height: 12, width: 50, color: Colors.white, margin: const EdgeInsets.only(top: 8, right: 100)),
        ),
      ),
    );
  }
}

class _StatCard extends ConsumerWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({required this.title, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          ref.read(navigationProvider.notifier).setIndex(1);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
