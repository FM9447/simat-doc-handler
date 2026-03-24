import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/animated_cosmic_background.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _oldCtrl     = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading    = false;
  bool _obscureOld   = true;
  bool _obscureNew   = true;
  bool _obscureConf  = true;

  @override
  void dispose() { _oldCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).changePassword(_oldCtrl.text, _newCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rejected));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Change Password', style: AppTypography.headingSmall)),
      body: AnimatedCosmicBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [BoxShadow(color: AppColors.glow, blurRadius: 20)],
                ),
                child: const Icon(Icons.shield_rounded, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text('Update Security', style: AppTypography.headingMedium),
              const SizedBox(height: 6),
              Text('Use a strong, unique password to keep your account safe.',
                  style: AppTypography.bodyMuted, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _oldCtrl,
                        obscureText: _obscureOld,
                        style: const TextStyle(color: AppColors.foreground),
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.muted),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.muted),
                            onPressed: () => setState(() => _obscureOld = !_obscureOld),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newCtrl,
                        obscureText: _obscureNew,
                        style: const TextStyle(color: AppColors.foreground),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20, color: AppColors.muted),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.muted),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Required';
                          if (v.length < 6) return 'At least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConf,
                        style: const TextStyle(color: AppColors.foreground),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.muted),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConf ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.muted),
                            onPressed: () => setState(() => _obscureConf = !_obscureConf),
                          ),
                        ),
                        validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Update Password',
                icon: Icons.lock_reset_rounded,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
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
