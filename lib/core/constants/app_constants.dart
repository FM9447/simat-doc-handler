import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // Use localhost for Web, or your physical device/emulator IP for Android/iOS
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    return 'http://192.168.1.39:5000/api'; // Using laptop IP for physical device/emulator
  }
  
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFFFF5722);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);

  static const String tokenKey = 'secure_auth_token';
  static const String userKey = 'cached_user_data';
}
