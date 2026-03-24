import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BrandedTitle extends StatelessWidget {
  final double fontSize;
  final double logoHeight;
  final bool showLogo;

  const BrandedTitle({
    super.key,
    this.fontSize = 18,
    this.logoHeight = 28,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          Image.asset(
            'assets/images/logo.png',
            height: logoHeight,
            errorBuilder: (_, __, ___) => Icon(
              Icons.description_rounded,
              color: AppColors.primary,
              size: logoHeight,
            ),
          ),
          const SizedBox(width: 8),
        ],
        ShaderMask(
          shaderCallback: (r) => AppColors.primaryGradient.createShader(r),
          child: Text(
            'docTransit',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}
