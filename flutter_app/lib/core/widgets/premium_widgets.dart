import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = const LinearGradient(colors: AppConstants.primaryGradient),
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.glowColor,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? glowColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      decoration: BoxDecoration(
        color: color ?? AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppConstants.borderColor),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.text,
    required this.status,
    this.small = false,
  });

  final String text;
  final String status;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = AppConstants.statusTheme[status] ?? AppConstants.statusTheme['pending'];
    final Color bg = theme['bg'];
    final Color border = theme['border'];
    final Color textColor = theme['text'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 9, vertical: small ? 1 : 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.role,
    this.small = false,
  });

  final String role;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final theme = AppConstants.roleTheme[role.toLowerCase()] ?? AppConstants.roleTheme['student'];
    final Color bg = theme['bg'];
    final Color border = theme['border'];
    final Color textColor = theme['text'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 9, vertical: small ? 1 : 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AnimatedFade extends StatefulWidget {
  const AnimatedFade({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<AnimatedFade> createState() => _AnimatedFadeState();
}

class _AnimatedFadeState extends State<AnimatedFade> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offset = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: SlideTransition(position: _offset, child: widget.child));
  }
}

class PremiumButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool outline;
  final Color? color;
  final bool small;

  const PremiumButton({
    super.key,
    required this.child,
    this.onPressed,
    this.fullWidth = false,
    this.outline = false,
    this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppConstants.primaryColor;
    
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: outline ? Colors.transparent : themeColor.withOpacity(0.15),
          foregroundColor: themeColor,
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 20, 
            vertical: small ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: themeColor.withOpacity(0.5)),
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}
