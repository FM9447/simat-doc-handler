import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => ref.read(notificationProvider.notifier).clearNotifications(),
          ),
        ],
      ),
      body: notificationState.messages.isEmpty
          ? const Center(child: Text('No new notifications'))
          : ListView.separated(
              itemCount: notificationState.messages.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final note = notificationState.messages[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.notifications, color: Colors.blue),
                  ),
                  title: Text(note['title'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note['body'] ?? ''),
                      const SizedBox(height: 4),
                      Text(note['time'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
