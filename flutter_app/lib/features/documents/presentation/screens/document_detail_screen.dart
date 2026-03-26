import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/user_model.dart';
import '../../../../models/workflow_model.dart';
import '../../pdf_export.dart';
import '../../../../models/document_model.dart';
import '../../../../models/approval_model.dart';
import '../../../../providers/document_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/workflow_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../core/widgets/workflow_canvas_preview.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../shared/widgets/branded_title.dart';
import '../widgets/transfer_dialog.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final DocumentModel document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.primary,
    exportBackgroundColor: Colors.transparent,
  );

  bool   _isSigning          = false;
  bool   _useSavedSignature  = false;
  bool   _pdfLoadFailed      = false;
  bool   _showCanvasPreview  = false;
  final  _commentCtrl        = TextEditingController();

  @override
  void dispose() {
    _signatureController.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<Uint8List?> _getSignatureBytes() async {
    if (_signatureController.isEmpty) return null;
    return await _signatureController.toPngBytes();
  }

  void _processApproval(String action) async {
    final nextIdx = widget.document.approvals.length + 1;
    String nextRecipient = 'Final Approval';
    
    if (nextIdx < widget.document.workflow.length) {
      final role = widget.document.workflow[nextIdx];
      final assignedInfo = widget.document.assigned[role];
      if (assignedInfo is Map) {
        nextRecipient = assignedInfo['name'] ?? role.toUpperCase();
      } else {
        nextRecipient = role.toUpperCase();
      }
    }

    if (action == 'approved' && !_useSavedSignature && _signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please provide your digital signature')));
      return;
    }
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (action == 'approved') {
      _showSendingOverlay(nextRecipient);
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Processing…'), duration: Duration(seconds: 1)));
    }

    Uint8List? signatureBytes;
    String?    signatureUrl;

    if (_useSavedSignature) {
      signatureUrl = ref.read(authProvider).value?.signatureUrl;
    } else {
      signatureBytes = await _getSignatureBytes();
    }

    ref.read(documentListProvider.notifier).approveDocument(
      widget.document.id, action, _commentCtrl.text,
      signatureBytes: signatureBytes,
      signatureName: 'signature.png',
      signatureUrl: signatureUrl,
    ).then((_) {
      if (mounted) {
        // Pop the sending overlay dialog if it was shown
        if (action == 'approved') {
          Navigator.of(context, rootNavigator: true).pop();
        }
        
        scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Document ${action == 'approved' ? 'approved' : 'rejected'} successfully')));
        Navigator.pop(context); // Go back to Approval Queue
      }
    }).catchError((error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed: $error'), backgroundColor: AppColors.rejected));
      }
    });
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
                'Moving document to',
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final nextIdx = widget.document.approvals.length;
    final isCurrentApprover = user != null &&
        nextIdx < widget.document.workflow.length &&
        !['final_approved', 'rejected'].contains(widget.document.status.name.toLowerCase()) &&
        (widget.document.assigned[widget.document.workflow[nextIdx]] == user.id ||
            user.role == widget.document.workflow[nextIdx]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const BrandedTitle(),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (user != null &&
              (['tutor', 'hod', 'office', 'admin'].contains(user.role) ||
                  (user.role == 'student' &&
                      widget.document.status == DocumentStatus.pending)))
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: _showEditDialog,
              tooltip: 'Edit Details',
            ),
          if (widget.document.status == DocumentStatus.finalApproved)
            IconButton(
              icon: const Icon(Icons.download_rounded, color: AppColors.approved),
              onPressed: _downloadPdf,
              tooltip: 'Download PDF',
            ),
        ],
      ),
      body: MaxWidthWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.document.title, style: AppTypography.headingMedium),
                            const SizedBox(height: 6),
                            if (widget.document.studentId is Map)
                              Text(
                                '${widget.document.studentId['name'] ?? ''}'
                                '${widget.document.studentId['registerNo'] != null ? ' · ${widget.document.studentId['registerNo']}' : ''}'
                                '${widget.document.studentId['dept'] != null ? ' · ${widget.document.studentId['dept']}' : ''}',
                                style: AppTypography.caption,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(status: widget.document.status.name),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _badge(widget.document.priority.name.toUpperCase(), _priorityColor(widget.document.priority)),
                      const SizedBox(width: 8),
                      _badge(widget.document.flow ?? widget.document.category, AppColors.primary),
                      const Spacer(),
                      Text(_fmt(widget.document.createdAt), style: AppTypography.caption),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _sectionHeader('APPROVAL PROGRESS'),
            _buildApprovalTimeline(),

            if (widget.document.formData != null && widget.document.formData!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionHeader('REQUEST DETAILS'),
              GlassCard(
                child: Column(
                  children: widget.document.formData!.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(e.key, style: AppTypography.bodyMuted.copyWith(fontSize: 13)),
                        ),
                        Expanded(child: Text(
                          e.value == true ? 'Yes' : e.value == false ? 'No' : (e.value?.toString() ?? '—'),
                          style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                        )),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],

            if (widget.document.approvals.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionHeader('ACTIVITY LOG'),
              GlassCard(
                child: Column(
                  children: widget.document.approvals.asMap().entries.map((entry) {
                    final ap = entry.value;
                    final isApproved = ap.action == 'approved';
                    final approverName = ap.approverId is Map ? ap.approverId['name'] ?? 'Unknown' : 'Approver';
                    return Padding(
                      padding: EdgeInsets.only(bottom: entry.key == widget.document.approvals.length - 1 ? 0 : 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isApproved ? AppColors.approved.withOpacity(0.1) : AppColors.rejected.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isApproved ? AppColors.approved.withOpacity(0.3) : AppColors.rejected.withOpacity(0.3)),
                            ),
                            child: Icon(
                              isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
                              size: 16,
                              color: isApproved ? AppColors.approved : AppColors.rejected,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(approverName, style: AppTypography.headingSmall.copyWith(fontSize: 13)),
                                    _roleChip(ap.role ?? 'Staff'),
                                  ],
                                ),
                                if (ap.comment != null && ap.comment!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('"${ap.comment}"',
                                        style: AppTypography.bodyMuted.copyWith(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ),
                                if (ap.signatureUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Image.network(ap.signatureUrl!, height: 30, fit: BoxFit.contain,
                                        color: Colors.white, colorBlendMode: BlendMode.modulate,
                                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            if (widget.document.fileUrl != null && widget.document.fileUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionHeader('DOCUMENT PREVIEW'),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildDocumentPreview(),
              ),
            ],

            if (isCurrentApprover) ...[
              const SizedBox(height: 20),
              _isSigning
                  ? _buildSignaturePad(user)
                  : Row(
                      children: [
                        Expanded(
                          child: GradientButton(
                            text: 'Reject',
                            icon: Icons.cancel_outlined,
                            outline: true,
                            onPressed: _showRejectDialog,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GradientButton(
                            text: 'Approve & Sign',
                            icon: Icons.check_circle_outline_rounded,
                            onPressed: () => setState(() => _isSigning = true),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
              if (isCurrentApprover && !_isSigning) ...[
                const SizedBox(height: 12),
                GradientButton(
                  text: 'Transfer/Delegate Request',
                  icon: Icons.forward_to_inbox_rounded,
                  outline: true,
                  onPressed: _showTransferDialog,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
      ),
    );
  }

  void _downloadPdf() async {
    List<WorkflowModel> flows = ref.read(workflowProvider).value ?? [];
    if (flows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loading document template…')));
      await ref.read(workflowProvider.notifier).getFlows();
      flows = ref.read(workflowProvider).value ?? [];
    }
    
    _showDownloadingOverlay();
    
    try {
      await PdfExportHelper.generateAndPrintDocument(widget.document, flows);
      // Give a tiny buffer for the system dialog to take over
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showDownloadingOverlay() {
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
                'Generating your document',
                style: AppTypography.bodyMuted.copyWith(color: Colors.white70),
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

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(title, style: AppTypography.labelSmall),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _roleChip(String role) {
    final c = AppColors.roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withOpacity(0.3))),
      child: Text(role.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: c)),
    );
  }

  Color _priorityColor(PriorityLevel p) => switch (p) {
    PriorityLevel.urgent => AppColors.rejected,
    PriorityLevel.high   => AppColors.pending,
    PriorityLevel.medium => AppColors.secondary,
    PriorityLevel.low    => AppColors.muted,
  };

  String _fmt(DateTime? d) => d == null ? '—' : '${d.day}/${d.month}/${d.year}';

  Widget _buildDocumentPreview() {
    final flows = ref.watch(workflowProvider).maybeWhen(data: (f) => f, orElse: () => <WorkflowModel>[]);
    final workflow = flows.firstWhere((f) => f.name == widget.document.flow, orElse: () => WorkflowModel(name: 'Default', steps: []));
    final url = widget.document.fileUrl ?? '';

    if (url.isNotEmpty && !_pdfLoadFailed && !_showCanvasPreview && url.toLowerCase().contains('.pdf')) {
      return Stack(
        children: [
          SfPdfViewer.network(url, onDocumentLoadFailed: (_) => setState(() => _pdfLoadFailed = true)),
          Positioned(
            top: 8, right: 8,
            child: IconButton(
              icon: const Icon(Icons.view_quilt_rounded, color: AppColors.primary),
              onPressed: () => setState(() => _showCanvasPreview = true),
              tooltip: 'Switch to Canvas View',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (url.isNotEmpty && _pdfLoadFailed)
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.rejected.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.rejected, size: 16),
                const SizedBox(width: 8),
                const Text('PDF load failed. Showing layout preview.', style: TextStyle(fontSize: 10, color: AppColors.rejected)),
                const Spacer(),
                TextButton(onPressed: () => _launchUrl(url), child: const Text('Open in browser', style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
        Expanded(
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: WorkflowCanvasPreview(
                workflow: workflow,
                elements: workflow.elements,
                formData: widget.document.formData ?? {},
                student: widget.document.studentId is Map ? widget.document.studentId : {},
              ),
            ),
          ),
        ),
        if (url.isNotEmpty && _showCanvasPreview)
          TextButton.icon(
            onPressed: () => setState(() { _showCanvasPreview = false; _pdfLoadFailed = false; }),
            icon: const Icon(Icons.picture_as_pdf, size: 14),
            label: const Text('Back to PDF View', style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  Widget _buildSignaturePad(UserModel? user) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign to Approve', style: AppTypography.headingSmall),
          const SizedBox(height: 12),
          if (user?.signatureUrl != null) ...[
            CheckboxListTile(
              title: Text('Use my saved signature', style: AppTypography.bodyMedium),
              value: _useSavedSignature,
              onChanged: (val) => setState(() => _useSavedSignature = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
            ),
            if (_useSavedSignature)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.approved.withOpacity(0.3)),
                ),
                child: Image.network(user!.signatureUrl!, height: 60, color: Colors.white, colorBlendMode: BlendMode.modulate),
              ),
          ],
          if (!_useSavedSignature) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.glassBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Signature(controller: _signatureController, height: 150, backgroundColor: Colors.transparent),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _signatureController.clear(),
                child: const Text('Clear', style: TextStyle(color: AppColors.muted)),
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            style: const TextStyle(color: AppColors.foreground),
            decoration: const InputDecoration(labelText: 'Comments (Optional)', hintText: 'Add a note…'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Cancel', outline: true,
                  onPressed: () => setState(() => _isSigning = false),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  text: 'Confirm Approval',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () => _processApproval('approved'),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
        title: Text('Reject Document', style: AppTypography.headingSmall),
        content: TextField(
          controller: _commentCtrl,
          style: const TextStyle(color: AppColors.foreground),
          decoration: const InputDecoration(hintText: 'Enter reason for rejection…'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GradientButton(
            text: 'Confirm Reject',
            outline: true,
            onPressed: () {
              Navigator.pop(ctx);
              if (_commentCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
                return;
              }
              _processApproval('rejected');
            },
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalTimeline() {
    final steps    = widget.document.workflow;
    final approvals = widget.document.approvals;
    final status   = widget.document.status;

    return GlassCard(
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final i    = entry.key;
          final role = entry.value;
          final ap   = approvals.firstWhere((a) => a.role == role,
              orElse: () => ApprovalModel(approverId: '', role: role, action: 'pending'));
          final done     = ap.action == 'approved';
          final rejected = ap.action == 'rejected';
          final isCurrent = (status == DocumentStatus.pending || status == DocumentStatus.partiallyApproved) &&
                             approvals.length == i;

          final roleColor   = AppColors.roleColor(role);
          final indicatorC  = isCurrent ? roleColor : (done ? AppColors.approved : (rejected ? AppColors.rejected : AppColors.hint));
          final indicatorBg = isCurrent ? roleColor.withOpacity(0.1)
              : (done ? AppColors.approved.withOpacity(0.08)
              : (rejected ? AppColors.rejected.withOpacity(0.08) : AppColors.card));

          return IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: indicatorBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: indicatorC.withOpacity(0.5), width: 1.5),
                        boxShadow: isCurrent ? [BoxShadow(color: roleColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)] : null,
                      ),
                      child: Center(
                        child: Text(
                          rejected ? '✕' : (done ? '✓' : '${i + 1}'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: indicatorC),
                        ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(child: Container(width: 1.5, color: done ? AppColors.approved.withOpacity(0.4) : AppColors.border)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(role.toUpperCase(),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                                    color: isCurrent ? roleColor : AppColors.foreground)),
                            const SizedBox(width: 8),
                            if (isCurrent) _chip('CURRENT', roleColor),
                            if (done) _chip('DONE', AppColors.approved),
                            if (rejected) _chip('REJECTED', AppColors.rejected),
                          ],
                        ),
                        if (done)
                          Text('Approved by ${ap.approverId is Map ? ap.approverId['name'] : 'Staff'}',
                              style: AppTypography.caption),
                        if (isCurrent)
                          Text('Awaiting review…',
                              style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showTransferDialog() {
    final role = widget.document.workflow[widget.document.approvals.length];
    showDialog(
      context: context,
      builder: (ctx) => TransferDialog(
        documentId: widget.document.id,
        role: role,
        onSuccess: () {
          ref.read(documentListProvider.notifier).refresh();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditDialog() {
    final titleCtrl = TextEditingController(text: widget.document.title);
    final descCtrl = TextEditingController(text: widget.document.description);
    final headingCtrl = TextEditingController(text: widget.document.customHeading ?? '');
    
    // Get the workflow definition to know which fields are editable
    final flows = ref.read(workflowProvider).value ?? [];
    final currentFlow = flows.firstWhere(
      (f) => f.name == widget.document.flow || f.name == widget.document.category,
      orElse: () => WorkflowModel(name: '', steps: []),
    );
    
    final Map<String, TextEditingController> dynamicCtrls = {};
    final Map<String, dynamic> dynamicValues = {};
    
    if (widget.document.formData != null) {
      widget.document.formData!.forEach((key, value) {
        if (value is bool) {
          dynamicValues[key] = value;
        } else {
          dynamicCtrls[key] = TextEditingController(text: value?.toString() ?? '');
        }
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
          title: Text('Edit Document Details', style: AppTypography.headingSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                if (currentFlow.allowCustomHeading) ...[
                  TextField(
                    controller: headingCtrl,
                    style: const TextStyle(color: AppColors.foreground),
                    decoration: const InputDecoration(labelText: 'Custom Heading (for PDF)'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                
                if (dynamicCtrls.isNotEmpty || dynamicValues.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 10),
                  Text('FORM DATA', style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.primary)),
                  const SizedBox(height: 12),
                  ...dynamicCtrls.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: e.value,
                      style: const TextStyle(color: AppColors.foreground, fontSize: 13),
                      decoration: InputDecoration(labelText: e.key),
                    ),
                  )),
                  ...dynamicValues.entries.map((e) => CheckboxListTile(
                    title: Text(e.key, style: const TextStyle(color: AppColors.foreground, fontSize: 13)),
                    value: dynamicValues[e.key],
                    onChanged: (v) => setModalState(() => dynamicValues[e.key] = v),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  )),
                ],
              ],
            ),
          ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          GradientButton(
            text: 'Save Changes',
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              // Collect form data
              final Map<String, dynamic> updatedFormData = {};
              if (widget.document.formData != null) {
                widget.document.formData!.forEach((key, value) {
                  if (value is bool) {
                    updatedFormData[key] = dynamicValues[key];
                  } else {
                    updatedFormData[key] = dynamicCtrls[key]?.text;
                  }
                });
              }

              try {
                await ref.read(documentListProvider.notifier).updateDocument(
                  id: widget.document.id,
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  customHeading: headingCtrl.text,
                  formData: updatedFormData.isNotEmpty ? updatedFormData : null,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Document updated successfully')));
                  Navigator.pop(context); // Go back to list
                }
              } catch (e) {
                scaffoldMessenger.showSnackBar(SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.rejected));
              }
            },
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ],
      ),
    ),
  );
}

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(text, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
  );
}
