import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/workflow_model.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../models/workflow_element.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import '../../../../shared/widgets/loading_logo.dart'; // Added import for LoadingLogo
// import '../../../../core/widgets/workflow_canvas_preview.dart'; // Removed for now

class WorkflowEditorDialog extends ConsumerStatefulWidget {
  final WorkflowModel? flow;

  const WorkflowEditorDialog({super.key, this.flow});

  @override
  ConsumerState<WorkflowEditorDialog> createState() => _WorkflowEditorDialogState();
}

class _WorkflowEditorDialogState extends ConsumerState<WorkflowEditorDialog> {
  late TextEditingController nameController;
  late TextEditingController toController;
  late TextEditingController templateController;
  late TextEditingController closingController;
  
  late List<String> steps;
  late List<WorkflowElement> elements;
  late bool allowCustomHeading;
  late bool includeLetterhead;
  late bool includeRefDate;
  late bool includeSeal;
  String? customHeaderUrl;
  String? customApprovedSealUrl;
  String? customRejectedSealUrl;
  bool isUploadingImage = false;
  bool _isLoading = false; // Added _isLoading state variable

  @override
  void initState() {
    super.initState();
    final flow = widget.flow;
    nameController = TextEditingController(text: flow?.name ?? '');
    toController = TextEditingController(text: flow?.templateTo ?? '');
    templateController = TextEditingController(text: flow?.letterTemplate ?? '');
    closingController = TextEditingController(text: flow?.templateClosing ?? 'Sincerely,');
    
    steps = flow != null ? flow.steps.map((s) => s.toLowerCase() == 'teacher' ? 'tutor' : s.toLowerCase()).toList() : ['tutor', 'hod', 'principal'];
    elements = flow != null ? List.from(flow.elements) : [];
    allowCustomHeading = flow?.allowCustomHeading ?? false;
    includeLetterhead = flow?.includeLetterhead ?? true;
    includeRefDate = flow?.includeRefDate ?? true;
    includeSeal = flow?.includeSeal ?? false;
    customHeaderUrl = flow?.customHeaderUrl;
    customApprovedSealUrl = flow?.customApprovedSealUrl;
    customRejectedSealUrl = flow?.customRejectedSealUrl;
  }

  @override
  void dispose() {
    nameController.dispose();
    toController.dispose();
    templateController.dispose();
    closingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;
        
        return DefaultTabController(
          length: 3,
          child: Dialog(
            backgroundColor: const Color(0xFF0F071A),
            insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24, vertical: isMobile ? 8 : 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF2D1B4D))),
            child: Container(
              width: isMobile ? double.infinity : 1100,
              height: isMobile ? double.infinity : 800,
              padding: EdgeInsets.all(isMobile ? 12 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildTabsIndicator(),
                  const Divider(color: Color(0xFF2D1B4D), height: 32),
                  _buildGlobalSettings(isMobile),
                  const SizedBox(height: 24),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildFieldsTab(),
                        _buildTemplateTab(isMobile),
                        _buildPdfSettingsTab(),
                        // _buildPreviewTab(), // Removed for now
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF2D1B4D), height: 32),
                  _buildFooter(isMobile),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.flow == null ? 'New Document Flow' : 'Edit — ${widget.flow!.name}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTabsIndicator() {
    return const TabBar(
      isScrollable: true,
      labelColor: Color(0xFFC084FC),
      unselectedLabelColor: Colors.white54,
      indicatorColor: Color(0xFFC084FC),
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: [
        Tab(child: Row(children: [Icon(Icons.list_alt_rounded, size: 16), SizedBox(width: 8), Text('Form Fields')])),
        Tab(child: Row(children: [Icon(Icons.description_outlined, size: 16), SizedBox(width: 8), Text('Letter Template')])),
        Tab(child: Row(children: [Icon(Icons.settings_outlined, size: 16), SizedBox(width: 8), Text('PDF Settings')])),
      ],
    );
  }

  Widget _buildGlobalSettings(bool isMobile) {
    final nameField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Document name', style: TextStyle(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g. Bonafide Certificate',
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D1B4D))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2D1B4D))),
          ),
        ),
      ],
    );

    final approvalField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Approval steps', style: TextStyle(fontSize: 11, color: Colors.white54)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...steps.asMap().entries.map((e) {
              final idx = e.key;
              final step = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1B4D),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(step.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => steps.removeAt(idx)),
                      child: const Icon(Icons.close, size: 12, color: Colors.white38),
                    ),
                  ],
                ),
              );
            }),
            IconButton(
              onPressed: () => _showAddStepDialog(),
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFC084FC), size: 24),
              tooltip: 'Add Step',
            ),
          ],
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          nameField,
          const SizedBox(height: 16),
          approvalField,
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 2, child: nameField),
        const SizedBox(width: 24),
        Expanded(flex: 3, child: approvalField),
      ],
    );
  }

  Widget _buildFooter(bool isMobile) {
    final actions = [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel', style: TextStyle(color: Color(0xFFC084FC))),
      ),
      SizedBox(width: isMobile ? 8 : 16, height: isMobile ? 8 : 16),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D1B4D),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: isMobile ? 12 : 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: _saveWorkflow,
        child: Text(widget.flow == null ? 'Create Flow' : 'Save Workflow'),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: actions,
    );
  }

  Future<void> _saveWorkflow() async {
    if (nameController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
    });
    final updatedFlow = WorkflowModel(
      id: widget.flow?.id,
      name: nameController.text.trim(),
      steps: steps.map((s) => s.toLowerCase()).toList(),
      elements: elements,
      letterTemplate: templateController.text,
      templateTo: toController.text,
      templateClosing: closingController.text,
      allowCustomHeading: allowCustomHeading,
      includeLetterhead: includeLetterhead,
      includeRefDate: includeRefDate,
      includeSeal: includeSeal,
      customHeaderUrl: customHeaderUrl,
      customApprovedSealUrl: customApprovedSealUrl,
      customRejectedSealUrl: customRejectedSealUrl,
    );
    if (widget.flow == null) {
      await ref.read(adminWorkflowProvider.notifier).addWorkflow(updatedFlow);
    } else {
      await ref.read(adminWorkflowProvider.notifier).updateWorkflow(widget.flow!.id!, updatedFlow);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
    }
  }

  // ---- TABS ----

  Widget _buildFieldsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FORM FIELDS (STUDENT INPUTS)', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAddFieldBtn('Add Input Field', Icons.add_box_outlined, const Color(0xFFC084FC), () {
                setState(() {
                  elements.add(WorkflowElement(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    kind: 'field',
                    label: 'New Field',
                    type: 'text',
                    required: true,
                  ));
                });
              }),
              const SizedBox(width: 12),
              _buildAddFieldBtn('Add System Info', Icons.settings_input_component, const Color(0xFF3B82F6), () {
                setState(() {
                  elements.add(WorkflowElement(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    kind: 'system',
                    label: 'Student Name',
                    sysKey: 'name',
                  ));
                });
              }),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF2D1B4D)),
          const SizedBox(height: 16),
          if (_isLoading) // Added conditional loading indicator
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: LoadingLogo(size: 60),
            ))
          else if (elements.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No fields added yet', style: TextStyle(color: Colors.white10)),
            ))
          else
            ...elements.map((el) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D1B4D)),
                ),
                child: Row(
                  children: [
                    Icon(_getKindIcon(el.kind), size: 16, color: _getKindColor(el.kind)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(el.label ?? 'Unnamed Field', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('${el.kind.toUpperCase()} • ${el.kind == 'system' ? (el.sysKey ?? "N/A") : el.type}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white54),
                      onPressed: () => _showEditFieldDialog(el),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      onPressed: () => setState(() => elements.removeWhere((e) => e.id == el.id)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAddFieldBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(border: Border.all(color: color.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateTab(bool isMobile) {
    final placeholders = <String>{};
    for (final el in elements) {
      if (el.kind == 'system' && el.sysKey != null) {
        placeholders.add('{{${el.sysKey}}}');
      } else if (el.kind == 'field' && el.label != null && el.label!.isNotEmpty) {
        final tag = el.label!.replaceAll(' ', '_');
        placeholders.add('{{$tag}}');
      }
    }
    placeholders.addAll(['{{date}}', '{{ref_no}}']);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available placeholders — click to insert in active field:', style: TextStyle(fontSize: 11, color: Colors.white38)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: placeholders.map((p) => GestureDetector(
              onTap: () {
                final controller = templateController;
                final text = controller.text;
                final selection = controller.selection;
                final start = selection.isValid ? selection.start : text.length;
                final end = selection.isValid ? selection.end : text.length;
                
                final newText = text.replaceRange(start, end, p);
                controller.value = controller.value.copyWith(
                  text: newText,
                  selection: TextSelection.collapsed(offset: start + p.length),
                );
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1B4D).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFF2D1B4D)),
                ),
                child: Text(p, style: const TextStyle(fontSize: 10, color: Color(0xFFC084FC), fontWeight: FontWeight.bold)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          
          if (isMobile) ...[
            _buildStructuredField('Recipient (To)', toController, 'e.g. The Principal, SIMAT'),
            const SizedBox(height: 16),
            _buildStructuredField('Date', TextEditingController(text: 'Auto-placed on Right'), '', enabled: false),
          ] else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildStructuredField('Recipient (To)', toController, 'e.g. The Principal, SIMAT'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildStructuredField('Date', TextEditingController(text: 'Auto-placed on Right'), '', enabled: false),
                ),
              ],
            ),
          const SizedBox(height: 16),
          
          _buildStructuredField('Letter Content / Body', templateController, 'This is to certify that...', maxLines: 12),
          const SizedBox(height: 16),
          
          if (isMobile) ...[
            _buildStructuredField('Closing', closingController, 'Sincerely,'),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auto Signature', style: TextStyle(fontSize: 10, color: Colors.white54)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: const Text('Student Name & Sign', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _buildStructuredField('Closing', closingController, 'Sincerely,'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Auto Signature', style: TextStyle(fontSize: 10, color: Colors.white54)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: const Text('Student Name & Sign', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStructuredField(String label, TextEditingController controller, String hint, {int? maxLines = 1, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2D1B4D)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: enabled,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.white24),
            ),
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfSettingsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DOCUMENT EXPORT SETTINGS', style: TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1.1)),
          const SizedBox(height: 20),
          _buildSettingSwitch('Allow Custom Heading', 'Allow students to provide a custom document heading', Icons.title_rounded, allowCustomHeading, (v) => setState(() => allowCustomHeading = v)),
          _buildSettingSwitch('Include Letterhead', 'Show the institutional header on the generated PDF', Icons.branding_watermark_outlined, includeLetterhead, (v) => setState(() => includeLetterhead = v)),
          if (includeLetterhead) _buildImageUploadSection('header', customHeaderUrl),
          
          _buildSettingSwitch('Reference & Date', 'Include automatic reference number and current date', Icons.calendar_today_rounded, includeRefDate, (v) => setState(() => includeRefDate = v)),
          
          _buildSettingSwitch('Approval Status Stamp', 'Include an Approved/Rejected stamp on the final document', Icons.verified_user_outlined, includeSeal, (v) => setState(() => includeSeal = v)),
          if (includeSeal) ...[
            const SizedBox(height: 8),
            _buildImageUploadSection('approvedSeal', customApprovedSealUrl),
            _buildImageUploadSection('rejectedSeal', customRejectedSealUrl),
          ],
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFC084FC).withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFC084FC).withOpacity(0.1))),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFC084FC)),
                SizedBox(width: 12),
                Expanded(child: Text('These settings apply to the final PDF generation process. Letterhead and Seal will use the institutional defaults.', style: TextStyle(fontSize: 11, color: Colors.white54))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF2D1B4D))),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: value ? const Color(0xFFC084FC) : Colors.white24, size: 20),
        title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        activeThumbColor: const Color(0xFFC084FC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildImageUploadSection(String type, String? currentUrl) {
    String label = '';
    if (type == 'header') {
      label = 'Using default institutional header';
    } else if (type == 'approvedSeal') label = 'Using text-based APPROVED stamp';
    else if (type == 'rejectedSeal') label = 'Using text-based REJECTED stamp';
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              currentUrl != null ? 'Custom image selected' : label,
              style: TextStyle(fontSize: 11, color: currentUrl != null ? const Color(0xFFC084FC) : Colors.white54),
            ),
          ),
          if (isUploadingImage)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          else if (currentUrl != null)
            TextButton.icon(
              onPressed: () => setState(() {
                if (type == 'header') {
                  customHeaderUrl = null;
                } else if (type == 'approvedSeal') customApprovedSealUrl = null;
                else if (type == 'rejectedSeal') customRejectedSealUrl = null;
              }),
              icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
              label: const Text('Remove', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
            )
          else
            TextButton.icon(
              onPressed: () => _pickAndUploadImage(type),
              icon: const Icon(Icons.upload_file, size: 14, color: Colors.blueAccent),
              label: const Text('Upload Custom', style: TextStyle(fontSize: 11, color: Colors.blueAccent)),
            ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(String type) async {
    final result = await file_picker.FilePicker.platform.pickFiles(type: file_picker.FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() => isUploadingImage = true);
      try {
        final url = await ref.read(adminWorkflowProvider.notifier).uploadImage(
          result.files.single.bytes!, 
          result.files.single.name,
        );
        setState(() {
          if (type == 'header') {
            customHeaderUrl = url;
          } else if (type == 'approvedSeal') customApprovedSealUrl = url;
          else if (type == 'rejectedSeal') customRejectedSealUrl = url;
        });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      } finally {
        if (mounted) setState(() => isUploadingImage = false);
      }
    }
  }

  // _buildPreviewTab() method removed for now

  // --- DIALOGS ---

  void _showAddStepDialog() {
    String selectedRole = 'tutor';
    final roles = ['tutor', 'hod', 'principal', 'office', 'admin'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1F1033),
          title: const Text('Add Approval Step', style: TextStyle(color: Colors.white)),
          content: DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2D1B4D)),
              ),
              child: DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                dropdownColor: const Color(0xFF1F1033),
                style: const TextStyle(color: Colors.white),
                items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                onChanged: (v) => setModalState(() => selectedRole = v!),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () { 
              setState(() => steps.add(selectedRole));
              Navigator.pop(context); 
            }, child: const Text('Add')),
          ],
        ),
      ),
    );
  }

  void _showEditFieldDialog(WorkflowElement el) {
    final labelCtrl = TextEditingController(text: el.label);
    String type = el.type;
    String sysKey = el.sysKey ?? 'name';
    bool isRequired = el.required;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1F1033),
          title: Text('Edit ${el.kind.toUpperCase()}', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField('Label', labelCtrl),
                if (el.kind == 'field') ...[
                  const SizedBox(height: 16),
                  _buildDialogDropdown('Type', type, ['text', 'number', 'date', 'textarea'], (v) => setModalState(() => type = v!)),
                  CheckboxListTile(title: const Text('Required', style: TextStyle(color: Colors.white, fontSize: 13)), value: isRequired, onChanged: (v) => setModalState(() => isRequired = v!), dense: true),
                ] else if (el.kind == 'system') ...[
                  const SizedBox(height: 16),
                  _buildDialogDropdown('System Value', sysKey, ['name', 'registerNo', 'dept', 'course', 'sem', 'year', 'division'], (v) => setModalState(() => sysKey = v!)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: () { 
              setState(() {
                final idx = elements.indexWhere((e) => e.id == el.id);
                if (idx != -1) {
                  elements[idx] = el.copyWith(label: labelCtrl.text, type: type, sysKey: sysKey, required: isRequired);
                }
              });
              Navigator.pop(context); 
            }, child: const Text('Update')),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController ctrl) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)), TextField(controller: ctrl, style: const TextStyle(color: Colors.white))]);
  }

  Widget _buildDialogDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)), DropdownButton<String>(value: value, isExpanded: true, dropdownColor: const Color(0xFF2D1B4D), style: const TextStyle(color: Colors.white), items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged)]);
  }

  IconData _getKindIcon(String kind) {
    switch (kind) {
      case 'field': return Icons.text_fields_rounded;
      case 'system': return Icons.settings_input_component;
      default: return Icons.category_outlined;
    }
  }

  Color _getKindColor(String kind) {
    switch (kind) {
      case 'field': return const Color(0xFFC084FC);
      case 'system': return const Color(0xFF3B82F6);
      default: return Colors.white54;
    }
  }
}
