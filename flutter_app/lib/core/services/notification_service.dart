import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import 'dart:convert';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const _storage = FlutterSecureStorage();

  /// Initialize FCM — wrapped in try/catch so a Firebase failure never crashes the app.
  static Future<void> init() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('⚠️ [FCM] Skipping init: No Firebase app found (expected on Web if not configured).');
      return;
    }
    try {
      // 1. Request Permission
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('🔔 [FCM] User granted permission');
      }

      // 2. Initialize Local Notifications (foreground display)
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _localNotifications.initialize(initSettings);

      // Create high-importance channel for Android 8.0+
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
          'doctransit_channel',
          'DocTransit Notifications',
          description: 'Used for important document status updates.',
          importance: Importance.max,
          playSound: true,
          showBadge: true,
        ));
      }

      // 3. Foreground listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('🔔 [FCM] Foreground: ${message.notification?.title}');
        _showLocalNotification(message);
      });

      // 4. Background handler
      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      // 5. Get token & sync
      final token = await _fcm.getToken();
      if (token != null) {
        debugPrint('🔔 [FCM] Token obtained');
        await _syncToken(token);
      }

      // 6. Listen for token refresh
      _fcm.onTokenRefresh.listen(_syncToken);
    } catch (e) {
      // Never let notification setup crash the app
      debugPrint('⚠️ [FCM] Init failed (non-fatal): $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'doctransit_channel',
        'DocTransit Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title,
        message.notification?.body,
        details,
      );
    } catch (e) {
      debugPrint('⚠️ [FCM] Show notification failed: $e');
    }
  }

  static Future<void> _syncToken(String token) async {
    try {
      final userDataStr = await _storage.read(key: AppConstants.userKey);
      if (userDataStr == null) return;

      final userData = jsonDecode(userDataStr);
      final jwt = userData['token'];
      if (jwt == null) return;

      await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'token': token}),
      );
      debugPrint('🔔 [FCM] Token synced with backend');
    } catch (e) {
      debugPrint('⚠️ [FCM] Token sync failed (non-fatal): $e');
    }
  }
}

// Must be a top-level function
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [FCM] Background message: ${message.messageId}');
}
