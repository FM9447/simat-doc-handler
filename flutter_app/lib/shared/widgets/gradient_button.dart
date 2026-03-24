import 'package:flutter/material.dart';
import 'loading_logo.dart';
import '../../core/theme/app_colors.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool outline;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.padding,
    this.borderRadius = 12,
    this.outline = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDown(_) => _ctrl.reverse();
  void _onUp(_)   => _ctrl.forward();
  void _onCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    Widget inner = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading)
          const SizedBox(
            width: 16, height: 16,
            child: LoadingLogo(size: 16),
          )
        else ...[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(widget.text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.2)),
        ],
      ],
    );

    return ScaleTransition(
      scale: _ctrl,
      child: GestureDetector(
        onTapDown: enabled ? _onDown : null,
        onTapUp:   enabled ? _onUp   : null,
        onTapCancel: enabled ? _onCancel : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.5,
          child: Container(
            width: widget.width,
            padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: widget.outline ? null : AppColors.primaryGradient,
              color: widget.outline ? Colors.transparent : null,
              border: widget.outline ? Border.all(color: AppColors.primary, width: 1.5) : null,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: enabled && !widget.outline
                  ? [BoxShadow(color: AppColors.glow, blurRadius: 20, offset: const Offset(0, 4))]
                  : [],
            ),
            child: inner,
          ),
        ),
      ),
    );
  }
}
