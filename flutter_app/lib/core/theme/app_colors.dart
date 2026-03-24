import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core
  static const background = Colors.transparent;
  static const surface    = Color(0xFF0F0F19);
  static const card       = Color(0xFF1A1A28);
  static const foreground = Color(0xFFF0F0F5);
  static const muted      = Color(0xFFA0A0B0);
  static const hint       = Color(0xFF44445A);
  static const border     = Color(0xFF23233A);
  static const borderHigh = Color(0xFF3A3A5C);

  // Brand
  static const primary   = Color(0xFF8B5CF6); // Violet
  static const accent    = Color(0xFF6366F1); // Indigo
  static const secondary = Color(0xFF3B82F6); // Blue

  // Status
  static const approved = Color(0xFF22C55E); // Emerald
  static const pending  = Color(0xFFF59E0B); // Amber
  static const rejected = Color(0xFFEF4444); // Rose

  // Glass
  static const glassBg     = Color(0x990F0F19); // 60% opacity
  static const glassBorder = Color(0x338B5CF6); // 20% opacity
  static const glow        = Color(0x668B5CF6); // 40% opacity

  // Gradient
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status themed maps (for badge/chip use)
  static Map<String, Color> statusColor(String status) {
    switch (status) {
      case 'final_approved': return {'bg': const Color(0x1A22C55E), 'border': const Color(0x4D22C55E), 'text': approved};
      case 'partially_approved': return {'bg': const Color(0x1A3B82F6), 'border': const Color(0x4D3B82F6), 'text': secondary};
      case 'pending': return {'bg': const Color(0x1AF59E0B), 'border': const Color(0x4DF59E0B), 'text': pending};
      case 'rejected': return {'bg': const Color(0x1AEF4444), 'border': const Color(0x4DEF4444), 'text': rejected};
      default: return {'bg': const Color(0x1AA0A0B0), 'border': const Color(0x4DA0A0B0), 'text': muted};
    }
  }

  // Role color map
  static Color roleColor(String role) {
    switch (role) {
      case 'student':   return secondary;
      case 'tutor':     return primary;
      case 'hod':       return accent;
      case 'principal': return const Color(0xFF818CF8);
      case 'office':    return const Color(0xFF2DD4BF);
      case 'admin':     return rejected;
      default:          return muted;
    }
  }
}
