import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class DocTransitLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const DocTransitLogo({
    super.key,
    this.size = 120,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (showGlow)
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.glow.withOpacity(0.3),
                  blurRadius: size * 0.5,
                  spreadRadius: size * 0.1,
                )
              ],
            ),
          ),
        ShaderMask(
          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: Icon(
            Icons.shield_rounded,
            size: size,
            color: Colors.white,
          ),
        ),
        Icon(
          Icons.article_rounded,
          size: size * 0.4,
          color: Colors.white.withOpacity(0.9),
        ),
      ],
    );
  }
}
