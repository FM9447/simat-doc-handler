import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/animated_cosmic_background.dart';

class SignatureSetupScreen extends ConsumerStatefulWidget {
  const SignatureSetupScreen({super.key});

  @override
  ConsumerState<SignatureSetupScreen> createState() => _SignatureSetupScreenState();
}

class _SignatureSetupScreenState extends ConsumerState<SignatureSetupScreen> {
  final SignatureController _ctrl = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _isUploading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _saveSignature() async {
    if (_ctrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please draw your signature first')));
      return;
    }
    final bytes = await _ctrl.toPngBytes();
    if (bytes != null) {
      await _performUpload(bytes, 'signature_${DateTime.now().millisecondsSinceEpoch}.png');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      await _performUpload(result.files.single.bytes!, result.files.single.name);
    }
  }

  Future<void> _performUpload(Uint8List bytes, String filename) async {
    setState(() => _isUploading = true);
    try {
      await ref.read(authProvider.notifier).uploadSignature(bytes, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature saved!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.rejected));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Digital Signature', style: AppTypography.headingSmall)),
      body: AnimatedCosmicBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, gradient: AppColors.primaryGradient,
                  boxShadow: [BoxShadow(color: AppColors.glow, blurRadius: 20)],
                ),
                child: const Icon(Icons.draw_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text('Define Your Signature', style: AppTypography.headingMedium),
              const SizedBox(height: 6),
              Text('Your signature will be embedded in approved documents.',
                  style: AppTypography.bodyMuted, textAlign: TextAlign.center),
              const SizedBox(height: 28),

              GlassCard(
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  clipBehavior: Clip.antiAlias,
                  child: Signature(controller: _ctrl, height: 220, backgroundColor: Colors.transparent),
                ),
              ),

              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _ctrl.clear(),
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.muted),
                    label: const Text('Clear', style: TextStyle(color: AppColors.muted)),
                  ),
                  const SizedBox(width: 20),
                  TextButton.icon(
                    onPressed: _isUploading ? null : _pickFile,
                    icon: const Icon(Icons.file_upload_outlined, size: 18, color: AppColors.primary),
                    label: const Text('Upload Image', style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              GradientButton(
                text: 'Save & Activate',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isUploading,
                onPressed: _isUploading ? null : _saveSignature,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
