import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/user_model.dart';
import '../../pdf_export.dart';
import '../../../../models/document_model.dart';
import '../../../../providers/document_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final DocumentModel document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  bool _isSigning = false;
  bool _useSavedSignature = false;
  final _commentController = TextEditingController();

  Future<Uint8List?> _getSignatureBytes() async {
    if (_signatureController.isEmpty) return null;
    return await _signatureController.toPngBytes();
  }

  void _processApproval(String action) async {
    if (action != 'rejected' && !_useSavedSignature && _signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide your digital signature')));
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Processing...'), duration: Duration(seconds: 1)));
    
    Uint8List? signatureBytes;
    String? signatureUrl;

    if (_useSavedSignature) {
      signatureUrl = ref.read(authProvider).value?.signatureUrl;
    } else {
      signatureBytes = await _getSignatureBytes();
    }

    ref.read(documentListProvider.notifier).approveDocument(
      widget.document.id, 
      action, 
      _commentController.text, 
      signatureBytes: signatureBytes,
      signatureName: 'signature.png',
      signatureUrl: signatureUrl
    ).then((_) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Document ${action == 'approved' ? 'approved' : 'rejected'} successfully')));
        Navigator.pop(context);
      }
    }).catchError((error) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed: $error'), backgroundColor: Colors.red));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final isApprover = user?.role != 'student'; // Simplification for demo

    final isCurrentApprover = user != null && 
        widget.document.workflow.length > widget.document.approvals.length &&
        user.role == widget.document.workflow[widget.document.approvals.length];

    return Scaffold(
      appBar: AppBar(title: const Text('Document Details')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.description, size: 40, color: Colors.blue),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.document.studentId is Map 
                          ? 'Student: ${widget.document.studentId['name']}' 
                          : 'Student ID: ${widget.document.studentId}', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                      ),
                      if (widget.document.studentId is Map) ...[
                        if (user?.role == 'student')
                          Text(
                            'Reg No: ${widget.document.studentId['registerNo'] ?? 'N/A'} • Dept: ${widget.document.studentId['dept'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          )
                        else if (user?.role == 'teacher')
                          Text(
                            'Dept: ${widget.document.studentId['dept'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                      ],
                      Text('${widget.document.category} • ${widget.document.priority.name.toUpperCase()}'),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                _buildCurrentStageInfo(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(widget.document.status.name.toUpperCase(), 
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                ),
              ],
            ),
          ),
          _buildApprovalTimeline(),
          const Divider(height: 1),
          if (widget.document.status == DocumentStatus.finalApproved)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => PdfExportHelper.generateAndPrintDocument(widget.document),
                icon: const Icon(Icons.download),
                label: const Text('DOWNLOAD SIGNED PDF'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          Expanded(
            child: _isSigning 
              ? _buildSignaturePad(user)
              : _buildDocumentPreview(),
          ),
        ],
      ),
      bottomNavigationBar: isCurrentApprover && !_isSigning && widget.document.status != DocumentStatus.finalApproved 
        ? SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppConstants.errorColor),
                      onPressed: () => _showRejectDialog(),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.successColor),
                      onPressed: () => setState(() => _isSigning = true),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
            ),
          ) 
        : null,
    );
  }

  bool _pdfLoadFailed = false;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the document link.')),
      );
    }
  }

  Widget _buildDocumentPreview() {
    final url = widget.document.fileUrl ?? '';
    if (url.isEmpty) {
      return const Center(child: Text('No document file attached.'));
    }
    
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif'].any((ext) => url.toLowerCase().split('?').first.endsWith('.$ext'));

    // Provide a simple PDF viewer if the file is PDF
    if (widget.document.fileUrl!.toLowerCase().contains('.pdf')) {
      if (_pdfLoadFailed) {
        // Try loading Cloudinary PDF as image (thumbnail of first page)
        String thumbnailUrl = widget.document.fileUrl!.replaceAll('.pdf', '.jpg');
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Inline PDF preview failed. Showing preview image instead:', style: TextStyle(fontSize: 12, color: Colors.orange)),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  thumbnailUrl,
                  errorBuilder: (context, error, stackTrace) => _buildErrorUI('Could not load PDF thumbnail.'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(widget.document.fileUrl!),
                icon: const Icon(Icons.open_in_new),
                label: const Text('OPEN FULL PDF IN NEW TAB'),
              ),
            ),
          ],
        );
      }
      
      return SfPdfViewer.network(
        widget.document.fileUrl!,
        onDocumentLoadFailed: (details) {
          if (mounted) setState(() => _pdfLoadFailed = true);
        },
      );
    }
    
    // Otherwise image
    if (isImage || !url.contains('.')) { // Fallback to image if no extension for Cloudinary
      return InteractiveViewer(
        child: Image.network(
          url,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorUI('$error');
          },
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          const Text('Document Request Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 24),
          if (widget.document.formData != null)
            ...widget.document.formData!.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
              child: Row(
                children: [
                  Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(e.value)),
                ],
              ),
            )).toList(),
          const SizedBox(height: 32),
          const Text('This is a form-based request. Complete PDF will be generated upon final approval.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      )
    );
  }

  Widget _buildErrorUI(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text('Failed to load document: $error'),
          const SizedBox(height: 8),
          const Text('You can try opening the link directly:', style: TextStyle(fontSize: 12)),
          GestureDetector(
            onTap: () => _launchUrl(widget.document.fileUrl!),
            child: Text(
              widget.document.fileUrl!,
              style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pdfLoadFailed = false;
              });
              ref.read(documentListProvider.notifier).refresh();
            },
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturePad(UserModel? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Digital Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          if (user?.signatureUrl != null) ...[
            CheckboxListTile(
              title: const Text('Use my saved digital signature'),
              value: _useSavedSignature,
              onChanged: (val) => setState(() => _useSavedSignature = val ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_useSavedSignature)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      const Text('Saved Signature Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Image.network(user!.signatureUrl!, height: 60),
                    ],
                  ),
                ),
              ),
          ],
          if (!_useSavedSignature) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
              child: Signature(
                controller: _signatureController,
                height: 200,
                backgroundColor: Colors.white,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => _signatureController.clear(), child: const Text('Clear')),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Comments (Optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _isSigning = false), child: const Text('CANCEL'))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: () => _processApproval('approved'), child: const Text('CONFIRM APPROVAL'))),
            ],
          )
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Reject Document'),
            content: TextField(
              controller: _commentController,
              decoration: const InputDecoration(hintText: 'Reason for rejection'),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL')),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.errorColor),
                  onPressed: () {
                    Navigator.pop(context);
                    _processApproval('rejected');
                  },
                  child: const Text('CONFIRM REJECT')),
            ],
          );
        });
  }

  Widget _buildCurrentStageInfo() {
    final approvals = widget.document.approvals;
    final workflow = widget.document.workflow;
    final user = ref.read(authProvider).value;

    if (widget.document.status == DocumentStatus.finalApproved) {
      return const Text('✅ ALL STAGES COMPLETE',
          style: TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11));
    }
    if (widget.document.status == DocumentStatus.rejected) {
      return const Text('❌ REJECTED',
          style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11));
    }

    if (approvals.length < workflow.length) {
      final nextStage = workflow[approvals.length];
      final isMyTurn = user?.role == nextStage;

      return Text(
          isMyTurn
              ? '⚠️ PENDING YOUR APPROVAL'
              : '⏳ WAITING FOR: ${nextStage.toUpperCase()}',
          style: TextStyle(
              color: isMyTurn ? Colors.orange.shade800 : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 11));
    }

    return const SizedBox.shrink();
  }

  Widget _buildApprovalTimeline() {
    final approvals = widget.document.approvals;
    final workflow = widget.document.workflow;
    
    if (workflow.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 80,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: workflow.length,
        itemBuilder: (context, index) {
          final isDone = index < approvals.length;
          final isCurrent = index == approvals.length;
          
          return Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDone ? Colors.green : (isCurrent ? Colors.orange : Colors.grey.shade300),
                    child: isDone 
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text('${index + 1}', style: TextStyle(fontSize: 12, color: isCurrent ? Colors.white : Colors.grey)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDone ? approvals[index].action.toUpperCase() : (isCurrent ? 'PENDING' : 'WAITING'),
                    style: TextStyle(
                      fontSize: 8, 
                      fontWeight: FontWeight.bold,
                      color: isDone ? Colors.green : (isCurrent ? Colors.orange : Colors.grey)
                    ),
                  ),
                ],
              ),
              if (index < workflow.length - 1)
                Container(
                  width: 30,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: isDone ? Colors.green : Colors.grey.shade300,
                ),
            ],
          );
        },
      ),
    );
  }
}
