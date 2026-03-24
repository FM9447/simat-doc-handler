import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/utils/dialog_utils.dart';
import '../../../../shared/widgets/animated_cosmic_background.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../dashboard/presentation/screens/main_screen.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _obscure       = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );
    if (mounted && ref.read(authProvider).valueOrNull != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    ref.listen(authProvider, (_, next) {
      if (next is AsyncError) {
        DialogUtils.showErrorDialog(context, next.error.toString());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedCosmicBackground(
        child: SafeArea(
          child: Center(
            child: MaxWidthWrapper(
              maxWidth: 450,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Branding
                      Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing Glow
                              Container(
                                height: 60, width: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.glow.withOpacity(0.5), 
                                      blurRadius: 32, 
                                      spreadRadius: 8
                                    )
                                  ],
                                ),
                              ),
                              Image.asset(
                                'assets/images/logo.png',
                                height: 100, width: 100,
                                errorBuilder: (_, __, ___) => const Icon(Icons.description_rounded, size: 48, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ShaderMask(
                            shaderCallback: (r) => AppColors.primaryGradient.createShader(r),
                            child: const Text(
                              'docTransit',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SIMAT Secure Paperless Approvals',
                            style: AppTypography.bodyMuted.copyWith(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 52),

                      // Login Card
                      GlassCard(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sign In', style: AppTypography.headingMedium),
                            const SizedBox(height: 6),
                            Text('Welcome back! Enter your credentials.', style: AppTypography.bodyMuted),
                            const SizedBox(height: 28),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              style: const TextStyle(color: AppColors.foreground),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@college.edu',
                                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.muted, size: 20),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Email is required' : null,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _login(),
                              style: const TextStyle(color: AppColors.foreground),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.muted, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppColors.muted, size: 20),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'Password is required' : null,
                            ),
                            const SizedBox(height: 32),

                            // Sign In Button
                            GradientButton(
                              text: 'Sign In',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: isLoading ? null : _login,
                              isLoading: isLoading,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Register link
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: AppTypography.bodyMuted,
                              children: const [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Register',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
