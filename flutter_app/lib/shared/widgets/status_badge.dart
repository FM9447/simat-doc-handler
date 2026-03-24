import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 11});

  static String _label(String s) {
    switch (s) {
      case 'final_approved':    return 'Approved';
      case 'finalApproved':     return 'Approved';
      case 'partially_approved': return 'In Progress';
      case 'partiallyApproved': return 'In Progress';
      case 'pending':           return 'Pending';
      case 'rejected':          return 'Rejected';
      default: return s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;
    }
  }

  static String _key(String s) {
    if (s == 'finalApproved') return 'final_approved';
    if (s == 'partiallyApproved') return 'partially_approved';
    return s;
  }

  static IconData _icon(String s) {
    switch (s) {
      case 'final_approved':
      case 'finalApproved':     return Icons.check_circle_outline_rounded;
      case 'partially_approved':
      case 'partiallyApproved': return Icons.timelapse_rounded;
      case 'pending':           return Icons.radio_button_unchecked_rounded;
      case 'rejected':          return Icons.cancel_outlined;
      default:                  return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final key    = _key(status);
    final colors = AppColors.statusColor(key);
    final bg     = colors['bg']!;
    final border = colors['border']!;
    final text   = colors['text']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(status), size: fontSize + 2, color: text),
          const SizedBox(width: 5),
          Text(
            _label(status),
            style: TextStyle(fontSize: fontSize, color: text, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}
