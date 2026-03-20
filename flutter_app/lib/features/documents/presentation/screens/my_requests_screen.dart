import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/document_provider.dart';
import '../../../../core/constants/app_constants.dart';
import 'new_request_screen.dart';
import '../../presentation/screens/document_detail_screen.dart';
import '../../../notifications/presentation/screens/notification_screen.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(documentListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(
              child: Text('No requests found.\nTap + to create one.', textAlign: TextAlign.center),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              Color statusColor = Colors.grey;
              if (doc.status.name.contains('approved')) statusColor = AppConstants.successColor;
              if (doc.status.name.contains('pending')) statusColor = AppConstants.warningColor;
              if (doc.status.name.contains('rejected')) statusColor = AppConstants.errorColor;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: ${doc.category}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.circle, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(doc.status.name.toUpperCase(), 
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DocumentDetailScreen(document: doc),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading requests: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NewRequestScreen()));
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
