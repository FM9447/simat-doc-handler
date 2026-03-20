import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/workflow_model.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../core/constants/app_constants.dart';

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
      appBar: AppBar(
        title: const Text('Document Flow Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showFlowDialog(context),
          ),
        ],
      ),
      body: workflowsAsync.when(
        data: (flows) => ListView.builder(
          itemCount: flows.length,
          itemBuilder: (context, index) {
            final flow = flows[index];
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(flow.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Steps: ${flow.steps.join(' ➔ ')}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showFlowDialog(context, flow: flow),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteFlow(flow.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _deleteFlow(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flow?'),
        content: const Text('Are you sure you want to delete this document flow?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(adminWorkflowProvider.notifier).deleteWorkflow(id);
    }
  }

  void _showFlowDialog(BuildContext context, {WorkflowModel? flow}) {
    final nameController = TextEditingController(text: flow?.name);
    bool isFormBased = flow?.isFormBased ?? false;
    final fieldsController = TextEditingController(text: flow?.requiredFields.join(', '));
    List<String> steps = flow?.steps != null ? List.from(flow!.steps) : ['teacher'];
    final roles = ['teacher', 'hod', 'principal', 'office', 'admin'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(flow == null ? 'Add Document Flow' : 'Edit Document Flow'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Document Name', hintText: 'e.g. Bonafide Certificate'),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Form Based?'),
                  subtitle: const Text('Student fills details instead of uploading file'),
                  value: isFormBased,
                  onChanged: (val) => setDialogState(() => isFormBased = val),
                  contentPadding: EdgeInsets.zero,
                ),
                if (isFormBased) ...[
                  TextField(
                    controller: fieldsController,
                    decoration: const InputDecoration(
                      labelText: 'Required Fields (comma separated)',
                      hintText: 'e.g. Reason, Semester, Year',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Approval Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                ...steps.asMap().entries.map((entry) {
                  int idx = entry.key;
                  String role = entry.value;
                  return Row(
                    children: [
                      CircleAvatar(radius: 12, child: Text('${idx + 1}')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: role,
                          isExpanded: true,
                          items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => steps[idx] = val);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: steps.length > 1 ? () => setDialogState(() => steps.removeAt(idx)) : null,
                      ),
                    ],
                  );
                }),
                TextButton.icon(
                  onPressed: () => setDialogState(() => steps.add('teacher')),
                  icon: const Icon(Icons.add),
                  label: const Text('ADD STEP'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                
                final requiredFields = fieldsController.text.split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                if (flow == null) {
                  await ref.read(adminWorkflowProvider.notifier).addWorkflow(
                    nameController.text, 
                    steps,
                    isFormBased: isFormBased,
                    requiredFields: requiredFields,
                  );
                } else {
                  await ref.read(adminWorkflowProvider.notifier).updateWorkflow(
                    flow.id!, 
                    nameController.text, 
                    steps,
                    isFormBased: isFormBased,
                    requiredFields: requiredFields,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}
