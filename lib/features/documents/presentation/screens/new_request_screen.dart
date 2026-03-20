import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../../providers/document_provider.dart';
import '../../../../providers/workflow_provider.dart';
import '../../../../models/workflow_model.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _category;
  String _priority = 'Low';
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  late ConfettiController _confettiController;
  
  // Dynamic form fields
  final Map<String, TextEditingController> _formControllers = {};

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    for (var controller in _formControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFileBytes = result.files.single.bytes;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  void _submit(WorkflowModel selectedWorkflow) {
    bool isFormBased = selectedWorkflow.isFormBased;
    Map<String, String>? formData;
    
    if (isFormBased) {
      formData = _formControllers.map((key, controller) => MapEntry(key, controller.text));
    }

    if (_formKey.currentState!.validate() && (isFormBased || _selectedFileBytes != null)) {
      ref
          .read(documentListProvider.notifier)
          .submitDocument(
            title: _titleController.text,
            description: _descController.text,
            category: _category ?? '',
            priority: _priority.toLowerCase(),
            fileBytes: _selectedFileBytes,
            fileName: _selectedFileName,
            formData: formData,
            workflow: selectedWorkflow.steps,
          )
          .then((_) {
        _confettiController.play();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request Submitted Successfully!')));
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }).catchError((e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      });
    } else if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please attach a document')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Title * (e.g., Bonafide for Internship)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Consumer(builder: (context, ref, _) {
                final flows = ref
                    .watch(workflowProvider)
                    .maybeWhen(data: (flows) => flows, orElse: () => []);
                final categoryOptions = flows.map((f) => f.name).toList();
                if (categoryOptions.isNotEmpty &&
                    !categoryOptions.contains(_category)) {
                  _category = categoryOptions.first;
                }

                return DropdownButtonFormField<String>(
                  value: _category ??
                      (categoryOptions.isNotEmpty
                          ? categoryOptions.first
                          : null),
                  decoration: const InputDecoration(labelText: 'Category *'),
                  hint: const Text('Select Document Type'),
                  items: categoryOptions
                      .map<DropdownMenuItem<String>>(
                          (c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? 'Required' : null,
                );
              }),
              const SizedBox(height: 16),
              const Text('Priority *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Low', label: Text('Low')),
                  ButtonSegment(value: 'Medium', label: Text('Medium')),
                  ButtonSegment(value: 'High', label: Text('High')),
                  ButtonSegment(value: 'Urgent', label: Text('Urgent')),
                ],
                selected: {_priority},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _priority = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Description *', alignLabelWithHint: true),
                maxLength: 500,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Consumer(builder: (context, ref, _) {
                final flows = ref.watch(workflowProvider).maybeWhen(data: (flows) => flows, orElse: () => <WorkflowModel>[]);
                final currentFlow = flows.firstWhere((f) => f.name == _category, orElse: () => flows.isNotEmpty ? flows.first : WorkflowModel(name: '', steps: []));
                
                if (currentFlow.name.isNotEmpty && currentFlow.isFormBased) {
                  // Ensure controllers exist for all required fields
                  for (var field in currentFlow.requiredFields) {
                    _formControllers.putIfAbsent(field, () => TextEditingController());
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Additional Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...currentFlow.requiredFields.map((field) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: TextFormField(
                          controller: _formControllers[field],
                          decoration: InputDecoration(
                            labelText: '$field *',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      )).toList(),
                    ],
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.upload_file, size: 48, color: Colors.blue),
                      const SizedBox(height: 8),
                      Text(_selectedFileName ?? 'No file selected'),
                      TextButton(
                        onPressed: _pickFile,
                        child: const Text('Choose Document (PDF/Image)'),
                      )
                    ],
                  ),
                );
              }),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  final flows = ref
                      .read(workflowProvider)
                      .maybeWhen(data: (flows) => flows, orElse: () => []);
                  if (_category == null && flows.isNotEmpty) {
                    _category = flows.first.name;
                  }

                  final selectedFlow = flows.firstWhere(
                    (flow) => flow.name == _category,
                    orElse: () => WorkflowModel(
                        id: '',
                        name: _category ?? 'Unknown',
                        steps: ['teacher', 'hod', 'principal'],
                        isActive: true),
                  );
                  _submit(selectedFlow);
                },
                child: const Text('SUBMIT REQUEST',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple
          ],
        ),
      ),
    );
  }
}
