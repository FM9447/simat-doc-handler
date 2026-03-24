import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../models/user_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/loading_logo.dart';

class DelegationDialog extends ConsumerStatefulWidget {
  const DelegationDialog({super.key});

  @override
  ConsumerState<DelegationDialog> createState() => _DelegationDialogState();
}

class _DelegationDialogState extends ConsumerState<DelegationDialog> {
  List<UserModel> _colleagues = [];
  bool _isLoading = true;
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _loadColleagues();
  }

  Future<void> _loadColleagues() async {
    try {
      final list = await ref.read(authProvider.notifier).fetchColleagues();
      if (mounted) {
        setState(() {
          _colleagues = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load colleagues: $e'), backgroundColor: AppColors.rejected),
        );
      }
    }
  }

  void _submit() async {
    if (_selectedUserId == null) return;
    
    try {
      setState(() => _isLoading = true);
      await ref.read(authProvider.notifier).delegateRole(_selectedUserId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delegation activated successfully! 🏖️')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rejected),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
      title: Text('Setup Delegation', style: AppTypography.headingSmall),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a colleague to handle your requests while you are away.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: LoadingLogo(size: 60),
              ))
            else if (_colleagues.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No colleagues found for your role.', style: TextStyle(color: AppColors.muted)),
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _colleagues.length,
                  itemBuilder: (context, i) {
                    final u = _colleagues[i];
                    final isSel = _selectedUserId == u.id;
                    return ListTile(
                      title: Text(u.name, style: TextStyle(color: isSel ? AppColors.primary : AppColors.foreground, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(u.email, style: const TextStyle(fontSize: 11)),
                      trailing: isSel ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () => setState(() => _selectedUserId = u.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        GradientButton(
          text: 'Activate',
          onPressed: _selectedUserId != null && !_isLoading ? _submit : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ],
    );
  }
}
