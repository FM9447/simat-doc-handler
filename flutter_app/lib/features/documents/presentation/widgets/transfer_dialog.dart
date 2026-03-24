import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/loading_logo.dart';
import '../../../../core/constants/app_constants.dart';

class TransferDialog extends ConsumerStatefulWidget {
  final String documentId;
  final String role;
  final VoidCallback onSuccess;

  const TransferDialog({
    required this.documentId,
    required this.role,
    required this.onSuccess,
    super.key,
  });

  @override
  ConsumerState<TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends ConsumerState<TransferDialog> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _selectedUserId;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEligibleUsers();
  }

  Future<void> _fetchEligibleUsers() async {
    try {
      final auth = ref.read(authProvider).value;
      if (auth == null) return;

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/colleagues'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> colleagues = jsonDecode(response.body);
        setState(() {
          _users = colleagues.where((u) => u['_id'] != auth.id).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching users for transfer: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitTransfer() async {
    if (_selectedUserId == null) return;
    final selectedUser = _users.firstWhere((u) => u['_id'] == _selectedUserId);
    final selectedName = selectedUser['name'] ?? widget.role.toUpperCase();

    _showTransferringOverlay(selectedName);

    try {
      final auth = ref.read(authProvider).value;
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/documents/${widget.documentId}/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth?.token}'
        },
        body: jsonEncode({
          'newApproverId': _selectedUserId,
          'role': widget.role,
          'comment': _commentCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          // Pop the transferring overlay
          Navigator.of(context, rootNavigator: true).pop();
          // Pop the TransferDialog itself
          Navigator.pop(context);
          
          widget.onSuccess();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document transferred successfully!')));
        }
      } else {
        if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close overlay
        final error = jsonDecode(response.body)['message'] ?? 'Transfer failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.rejected));
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close overlay
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rejected));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
      title: Text('Transfer Request', style: AppTypography.headingSmall),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select a ${widget.role.toUpperCase()} to handle this request:', style: AppTypography.bodyMuted),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: LoadingLogo(size: 60),
              ))
            else if (_users.isEmpty)
              const Text('No eligible colleagues found for this role.', style: TextStyle(color: AppColors.muted))
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _users.length,
                  itemBuilder: (context, i) {
                    final u = _users[i];
                    final isSel = _selectedUserId == u['_id'];
                    return ListTile(
                      title: Text(u['name'], style: TextStyle(color: isSel ? AppColors.primary : AppColors.foreground, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(u['email'], style: const TextStyle(fontSize: 11)),
                      trailing: isSel ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () => setState(() => _selectedUserId = u['_id']),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              maxLines: 2,
              style: const TextStyle(color: AppColors.foreground),
              decoration: const InputDecoration(labelText: 'Transfer Reason (Optional)', hintText: 'e.g. On leave, please handle...'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        GradientButton(
          text: 'Transfer',
          onPressed: _selectedUserId != null ? _submitTransfer : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ],
    );
  }

  void _showTransferringOverlay(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingLogo(size: 100),
              const SizedBox(height: 32),
              Text(
                'Transferring document to',
                style: AppTypography.bodyMuted.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                name.toUpperCase(),
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
