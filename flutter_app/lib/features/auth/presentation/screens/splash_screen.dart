import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/animated_cosmic_background.dart';
import 'login_screen.dart';
import '../../../dashboard/presentation/screens/main_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double>   _scaleAnim;
  late final Animation<double>   _glowAnim;
  late final Animation<double>   _textSlideAnim;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0.0, 0.4, curve: Curves.elasticOut))
    );

    _glowAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeInOutSine))
    );

    _textSlideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic))
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: const Interval(0.3, 0.6, curve: Curves.easeIn))
    );

    _animCtrl.forward();
    _checkAuth();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  void _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    final authState = await ref.read(authProvider.future);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: authState != null ? const MainScreen() : const LoginScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedCosmicBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _animCtrl,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _scaleAnim,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Glow
                          Container(
                            height: 100 * _glowAnim.value, 
                            width: 100 * _glowAnim.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.glow.withOpacity(0.4 * _glowAnim.value), 
                                  blurRadius: 50 * _glowAnim.value, 
                                  spreadRadius: 15 * _glowAnim.value
                                )
                              ],
                            ),
                          ),
                          // Main Logo (User-provided splash version)
                          Image.asset(
                            'assets/images/logo.png',
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 48),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Transform.translate(
                    offset: Offset(0, _textSlideAnim.value),
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, val, child) {
                            return Opacity(
                              opacity: val,
                              child: ShaderMask(
                                shaderCallback: (r) => AppColors.primaryGradient.createShader(r),
                                child: const Text(
                                  'DocTransit',
                                  style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2.5),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text('Digital Student Document Handler', 
                          style: AppTypography.bodyMuted.copyWith(letterSpacing: 1.0, fontSize: 13, color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // (Removed redundant LoadingLogo from bottom to prevent layout overlap)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
