import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppConstants {
  static String _currentBaseUrl = 'https://api.doctransit.live/api';

  static String get baseUrl => _currentBaseUrl;

  /// Probes for local server on startup, falls back to Render if not found.
  static Future<void> init() async {
    const localPort = '80';
    final localUrl = kIsWeb ? 'http://localhost:$localPort/api' : 'http://10.0.2.2:$localPort/api';
    const wifiIp = '192.168.1.39';
    const wifiUrl = 'http://$wifiIp:$localPort/api';

    debugPrint('🔍 Probing for Local Backend...');

    try {
      // 1. Try WiFi IP first (Priority for local testing on physical device)
      final response = await http.get(Uri.parse('$wifiUrl/auth/tutors')).timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        _currentBaseUrl = wifiUrl;
        debugPrint('✅ Using Local WiFi Backend: $wifiUrl');
        return;
      }
    } catch (_) {}

    try {
      // 2. Try Emulator/Localhost candidate
      final response = await http.get(Uri.parse('$localUrl/auth/tutors')).timeout(const Duration(milliseconds: 1000));
      if (response.statusCode == 200) {
        _currentBaseUrl = localUrl;
        debugPrint('✅ Using Local Interface: $localUrl');
        return;
      }
    } catch (_) {}

    debugPrint('⚠️ Local server fallback to Cloud: $_currentBaseUrl');
  }
  
  // docTransit Premium Palette
  static const Color bgColor = Color(0xFF080810);
  static const Color surfaceColor = Color(0xFF0F0F1A);
  static const Color cardColor = Color(0xFF13131F);
  static const Color cardColorLight = Color(0xFF1A1A2E);
  static const Color borderColor = Color(0xFF23233A);
  static const Color borderColorHigh = Color(0xFF3A3A5C);
  static const Color textColor = Color(0xFFF0F0FF);
  static const Color mutedColor = Color(0xFF8888AA);
  static const Color hintColor = Color(0xFF44445A);
  static const Color errorColor = Color(0xFFEF4444);

  // Gradient Colors
  static const List<Color> primaryGradient = [Color(0xFFA78BFA), Color(0xFF60A5FA)];
  static const Color primaryColor = Color(0xFF7C3AED); // Purple
  
  // Role Colors
  static const Map<String, dynamic> roleTheme = {
    'student': {'bg': Color(0xFF070F2A), 'border': Color(0xFF1D4ED8), 'text': Color(0xFF60A5FA)},
    'tutor': {'bg': Color(0xFF150A2A), 'border': Color(0xFF7C3AED), 'text': Color(0xFFA78BFA)},
    'hod': {'bg': Color(0xFF1A0A2E), 'border': Color(0xFF6D28D9), 'text': Color(0xFFC084FC)},
    'principal': {'bg': Color(0xFF0C0A2E), 'border': Color(0xFF3730A3), 'text': Color(0xFF818CF8)},
    'office': {'bg': Color(0xFF031A18), 'border': Color(0xFF134E4A), 'text': Color(0xFF2DD4BF)},
    'admin': {'bg': Color(0xFF1A0505), 'border': Color(0xFF7F1D1D), 'text': Color(0xFFF87171)},
  };

  // Status Colors
  static const Map<String, dynamic> statusTheme = {
    'pending': {'bg': Color(0xFF1A1000), 'border': Color(0xFF78350F), 'text': Color(0xFFFBBF24)},
    'partiallyApproved': {'bg': Color(0xFF070F2A), 'border': Color(0xFF1D4ED8), 'text': Color(0xFF60A5FA)},
    'finalApproved': {'bg': Color(0xFF031A0E), 'border': Color(0xFF166534), 'text': Color(0xFF4ADE80)},
    'rejected': {'bg': Color(0xFF1A0505), 'border': Color(0xFF7F1D1D), 'text': Color(0xFFF87171)},
  };

  static const String tokenKey = 'secure_auth_token';
  static const String userKey = 'cached_user_data';
}
