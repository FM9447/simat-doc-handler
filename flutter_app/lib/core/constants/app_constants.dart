import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class AppConstants {
  // Use 10.0.2.2 for Android Emulator, localhost for Web/Windows, or your physical IP
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    if (Platform.isAndroid) {
      // Check if running on emulator or physical device
      // 10.0.2.2 is the special alias to your host loopback interface
      return 'http://192.168.1.39:5000/api'; // Using laptop IP for physical device/emulator
    }
    return 'http://192.168.1.39:5000/api';
  }
  
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFFFF5722);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);

  static const String tokenKey = 'secure_auth_token';
  static const String userKey = 'cached_user_data';
}
