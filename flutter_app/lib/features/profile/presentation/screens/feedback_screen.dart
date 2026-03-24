import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../services/api_service.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _type = 'feedback';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await apiService.post('/feedback', {
        'type': _type,
        'title': _titleCtrl.text.trim(),
        'content': _contentCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback! 🚀'), backgroundColor: AppColors.approved),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rejected),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Feedback & Report'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We value your input!', style: AppTypography.headingMedium),
            const SizedBox(height: 8),
            const Text(
              'Submit a bug report, suggest a feature, or just let us know how we are doing.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 32),
            
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(color: AppColors.foreground),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., App crashes on login',
                      prefixIcon: const Icon(Icons.title, size: 20, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.foreground),
                    decoration: InputDecoration(
                      labelText: 'Message',
                      hintText: 'Describe your issue or feedback in detail...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  GradientButton(
                    text: 'Submit',
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    isLoading: _isSubmitting,
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _typeChip('Feedback', 'feedback', Icons.chat_bubble_outline),
        const SizedBox(width: 8),
        _typeChip('Report Bug', 'bug', Icons.bug_report_outlined),
        const SizedBox(width: 8),
        _typeChip('Other', 'other', Icons.more_horiz),
      ],
    );
  }

  Widget _typeChip(String label, String value, IconData icon) {
    final isSel = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSel ? AppColors.primary : AppColors.muted, size: 18),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, color: isSel ? AppColors.primary : AppColors.muted, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}
