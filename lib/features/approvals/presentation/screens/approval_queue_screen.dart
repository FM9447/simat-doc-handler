import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/document_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../documents/presentation/screens/document_detail_screen.dart';

class ApprovalQueueScreen extends ConsumerStatefulWidget {
  const ApprovalQueueScreen({super.key});

  @override
  ConsumerState<ApprovalQueueScreen> createState() => _ApprovalQueueScreenState();
}

class _ApprovalQueueScreenState extends ConsumerState<ApprovalQueueScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Queue'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: ['All', 'High', 'Urgent', 'Pending>24h'].map((filter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppConstants.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: docsAsync.when(
              data: (docs) {
                // In an actual app, filter based on _selectedFilter
                // For MVP, just showcase the UI.
                final filteredDocs = docs.where((doc) => doc.status.name.contains('pending') || doc.status.name.contains('approved')).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('Queue is clear! 🎉', style: TextStyle(fontSize: 18)));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return Dismissible(
                      key: Key(doc.id),
                      background: Container(
                        color: AppConstants.successColor,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: AppConstants.errorColor,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        // Quick Approve/Reject logic
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: doc.priority.name == 'urgent' ? Colors.red.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(doc.priority.name.toUpperCase(), 
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                        color: doc.priority.name == 'urgent' ? Colors.red : Colors.orange)),
                                  ),
                                  Text(doc.createdAt?.toString().substring(0, 10) ?? 'Today', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                doc.studentId is Map 
                                  ? 'Student: ${doc.studentId['name']}\nReg No: ${doc.studentId['registerNo'] ?? 'N/A'} • Dept: ${doc.studentId['dept'] ?? 'N/A'}' 
                                  : 'Student ID: ${doc.studentId}', 
                                style: const TextStyle(color: Colors.black87, fontSize: 13)
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)));
                                    },
                                    icon: const Icon(Icons.visibility),
                                    label: const Text('DETAILS'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.successColor),
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentDetailScreen(document: doc)));
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const Text('APPROVE'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
