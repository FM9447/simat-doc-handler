import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../../providers/document_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/workflow_provider.dart';
import '../../../../models/workflow_model.dart';
import '../../../../models/workflow_element.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../shared/widgets/branded_title.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _headingCtrl  = TextEditingController();
  final _descCtrl     = TextEditingController();

  String?   _category;
  String    _priority = 'Medium';
  Uint8List? _fileBytes;
  String?   _fileName;
  bool      _isSubmitting = false;

  late ConfettiController _confettiCtrl;
  final Map<String, TextEditingController> _fieldCtrls  = {};
  final Map<String, dynamic>               _fieldValues = {};

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _titleCtrl.dispose(); _headingCtrl.dispose(); _descCtrl.dispose();
    for (final c in _fieldCtrls.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (result != null) {
      setState(() { _fileBytes = result.files.single.bytes; _fileName = result.files.single.name; });
    }
  }

  void _submit(WorkflowModel flow) {
    if (_isSubmitting) return;
    
    final hasForms    = flow.isFormBased || flow.visibleFields.isNotEmpty;
    final Map<String, String> formData = {};
    if (hasForms) {
      for (final e in _fieldCtrls.entries) {
        formData[e.key] = e.value.text;
      }
      for (final e in _fieldValues.entries) {
        formData[e.key] = e.value.toString();
      }
    }
    if (_formKey.currentState!.validate() && (hasForms || _fileBytes != null)) {
      setState(() => _isSubmitting = true);
      
      final user = ref.read(authProvider).value;
      String recipientName = flow.steps.isNotEmpty ? flow.steps[0].toUpperCase() : 'Admin';
      
      if (flow.steps.isNotEmpty) {
        final firstRole = flow.steps[0].toLowerCase();
        if (firstRole == 'tutor' && user?.tutorName != null) {
          recipientName = user!.tutorName!;
        } else if (firstRole == 'hod' && user?.departmentName != null) {
          recipientName = '${user!.departmentName!} HOD';
        }
      }
      
      _showSendingOverlay(recipientName);

      ref.read(documentListProvider.notifier).submitDocument(
        title: _titleCtrl.text,
        customHeading: flow.allowCustomHeading && _headingCtrl.text.isNotEmpty ? _headingCtrl.text : null,
        description: _descCtrl.text.isNotEmpty ? _descCtrl.text : _titleCtrl.text,
        category: _category ?? '',
        priority: _priority.toLowerCase(),
        fileBytes: _fileBytes,
        fileName: _fileName,
        formData: formData.isNotEmpty ? formData : null,
        workflow: flow.steps,
      ).then((_) {
        if (mounted) Navigator.pop(context); // Close overlay
        _confettiCtrl.play();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted! 🎉')));
          Future.delayed(const Duration(seconds: 2), () { if (mounted) Navigator.pop(context); });
        }
      }).catchError((e) {
        if (mounted) Navigator.pop(context); // Close overlay
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rejected));
        }
      });
    } else if (!hasForms && _fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please attach a document')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final flows = ref.watch(workflowProvider).maybeWhen(data: (f) => f, orElse: () => <WorkflowModel>[]);
    if (_category == null && flows.isNotEmpty) _category = flows.first.name;
    final currentFlow = flows.firstWhere((f) => f.name == _category,
        orElse: () => flows.isNotEmpty ? flows.first : WorkflowModel(name: '', steps: []));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const BrandedTitle()),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _label('BASIC INFORMATION'),
                  GlassCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleCtrl,
                          style: const TextStyle(color: AppColors.foreground),
                          decoration: const InputDecoration(labelText: 'Subject *', hintText: 'e.g. Leave Application'),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        if (currentFlow.allowCustomHeading) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _headingCtrl,
                            style: const TextStyle(color: AppColors.foreground),
                            decoration: const InputDecoration(labelText: 'Document Heading (Optional)', hintText: 'e.g. BONAFIDE CERTIFICATE'),
                          ),
                        ],
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: const InputDecoration(labelText: 'Document Type *'),
                          dropdownColor: AppColors.card,
                          style: const TextStyle(color: AppColors.foreground, fontSize: 14),
                          items: flows.map((f) => DropdownMenuItem(value: f.name, child: Text(f.name))).toList(),
                          onChanged: (v) => setState(() { _category = v; _fieldCtrls.clear(); _fieldValues.clear(); }),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _label('PRIORITY'),
                  Row(
                    children: ['Low', 'Medium', 'High', 'Urgent'].map((p) {
                      final sel = _priority == p;
                      final c   = switch (p) {
                        'Urgent' => AppColors.rejected,
                        'High'   => AppColors.pending,
                        'Medium' => AppColors.secondary,
                        _        => AppColors.muted,
                      };
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _priority = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? c.withOpacity(0.15) : AppColors.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: sel ? c : AppColors.border),
                              ),
                              child: Text(p,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: sel ? c : AppColors.muted),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  if (currentFlow.steps.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _label('APPROVAL FLOW'),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.account_tree_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentFlow.steps.map((s) => s.toUpperCase()).join(' → '),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  if (currentFlow.visibleFields.isNotEmpty) ...[
                    _label('REQUEST DETAILS'),
                    GlassCard(
                      child: Column(
                        children: currentFlow.visibleFields.map((el) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildField(el),
                        )).toList(),
                      ),
                    ),
                  ] else ...[
                    _label('ATTACHMENT'),
                    GlassCard(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _descCtrl,
                            style: const TextStyle(color: AppColors.foreground),
                            maxLines: 2,
                            decoration: const InputDecoration(labelText: 'Short Description', hintText: 'Optional notes…'),
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: _pickFile,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _fileBytes != null ? AppColors.approved : AppColors.glassBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _fileBytes != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                                    size: 40,
                                    color: _fileBytes != null ? AppColors.approved : AppColors.primary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _fileName ?? 'Tap to upload PDF or Image',
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: _fileName != null ? AppColors.foreground : AppColors.muted,
                                    ),
                                  ),
                                  if (_fileName == null)
                                    const Text('Supports PDF, JPG, PNG', style: TextStyle(color: AppColors.hint, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  GradientButton(
                    text: _isSubmitting ? 'Sending...' : 'Submit Request',
                    icon: _isSubmitting ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    onPressed: _isSubmitting ? null : () => _submit(currentFlow),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              colors: [AppColors.primary, AppColors.accent, AppColors.secondary, AppColors.approved],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(text, style: AppTypography.labelSmall),
  );

  Widget _buildField(WorkflowElement el) {
    final label = el.label ?? 'Field';
    switch (el.type) {
      case 'text':
      case 'number':
      case 'textarea':
        _fieldCtrls.putIfAbsent(label, () => TextEditingController());
        return TextFormField(
          controller: _fieldCtrls[label],
          keyboardType: el.type == 'number' ? TextInputType.number : TextInputType.text,
          maxLines: el.type == 'textarea' ? 4 : 1,
          style: const TextStyle(color: AppColors.foreground),
          decoration: InputDecoration(
            labelText: '$label${el.required ? ' *' : ''}',
            hintText: el.placeholder.isNotEmpty ? el.placeholder : null,
            helperText: el.hint.isNotEmpty ? el.hint : null,
            helperStyle: const TextStyle(fontSize: 10, color: AppColors.hint),
          ),
          validator: (v) {
            if (el.required && (v == null || v.isEmpty)) return 'Required';
            if (v != null && v.isNotEmpty && el.pattern != null && el.pattern!.isNotEmpty) {
              if (!RegExp(el.pattern!).hasMatch(v)) return 'Invalid format';
            }
            return null;
          },
        );
      case 'date':
        _fieldCtrls.putIfAbsent(label, () => TextEditingController());
        return TextFormField(
          controller: _fieldCtrls[label],
          readOnly: true,
          style: const TextStyle(color: AppColors.foreground),
          decoration: InputDecoration(
            labelText: '$label${el.required ? ' *' : ''}',
            hintText: el.placeholder.isNotEmpty ? el.placeholder : 'Select date',
            helperText: el.hint.isNotEmpty ? el.hint : null,
            helperStyle: const TextStyle(fontSize: 10, color: AppColors.hint),
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.muted),
          ),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: DateTime.now(),
                firstDate: DateTime(2020), lastDate: DateTime(2030));
            if (d != null) setState(() => _fieldCtrls[label]?.text = '${d.day}/${d.month}/${d.year}');
          },
          validator: el.required ? (v) => v!.isEmpty ? 'Required' : null : null,
        );
      case 'select':
        return DropdownButtonFormField<String>(
          initialValue: _fieldValues[label] as String?,
          decoration: InputDecoration(
            labelText: '$label${el.required ? ' *' : ''}',
            hintText: el.placeholder.isNotEmpty ? el.placeholder : null,
            helperText: el.hint.isNotEmpty ? el.hint : null,
            helperStyle: const TextStyle(fontSize: 10, color: AppColors.hint),
          ),
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.foreground, fontSize: 14),
          items: el.options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) => setState(() => _fieldValues[label] = v),
          validator: el.required ? (v) => v == null ? 'Required' : null : null,
        );
      case 'checkbox':
        return CheckboxListTile(
          title: Text('$label${el.required ? ' *' : ''}', style: AppTypography.bodyMedium),
          value: (_fieldValues[label] as bool?) ?? false,
          onChanged: (v) => setState(() => _fieldValues[label] = v ?? false),
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        );
      default: return const SizedBox.shrink();
    }
  }

  void _showSendingOverlay(String recipient) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingLogo(size: 100),
              const SizedBox(height: 24),
              const BrandedTitle(fontSize: 28, logoHeight: 0, showLogo: false),
              const SizedBox(height: 12),
              Text(
                'Sending request to',
                style: AppTypography.bodyMuted.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                recipient.toUpperCase(),
                style: AppTypography.headingMedium.copyWith(color: Colors.white, letterSpacing: 1.2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

