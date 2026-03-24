import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoadingLogo extends StatefulWidget {
  final double size;
  const LoadingLogo({super.key, this.size = 80});

  @override
  State<LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<LoadingLogo> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Glow
            Container(
              width: widget.size * 0.8,
              height: widget.size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.glow.withOpacity(0.4 * _glow.value),
                    blurRadius: 40 * _glow.value,
                    spreadRadius: 10 * _glow.value,
                  )
                ],
              ),
            ),
            // Logo
            Transform.scale(
              scale: _pulse.value,
              child: Image.asset(
                'assets/images/logo.png',
                width: widget.size,
                height: widget.size,
                errorBuilder: (_, __, ___) => const Icon(Icons.shield_rounded, color: AppColors.primary, size: 40),
              ),
            ),
          ],
        );
      },
    );
  }
}
