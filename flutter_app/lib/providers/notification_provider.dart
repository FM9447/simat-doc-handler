import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/notification_model.dart';

class NotificationState {
  final bool isEnabled;
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationState({
    required this.isEnabled,
    required this.notifications,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? isEnabled,
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState(
    isEnabled: true,
    notifications: [],
    unreadCount: 0,
  )) {
    fetchNotifications();
    // Periodic refresh every 30 seconds to reduce perceived delay
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchNotifications());
  }

  late final Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await apiService.get('/notifications');
      final notifs = (response as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
      final unread = notifs.where((n) => !n.read).length;
      state = state.copyWith(
        notifications: notifs,
        unreadCount: unread,
      );
    } catch (e) {
      // Silently fail — notifications are non-critical
      print('Failed to fetch notifications: $e');
    }
  }

  Future<void> markAllRead() async {
    try {
      await apiService.put('/notifications/read', {});
      state = state.copyWith(
        notifications: state.notifications.map((n) => NotificationModel(
          id: n.id,
          message: n.message,
          type: n.type,
          read: true,
          createdAt: n.createdAt,
        )).toList(),
        unreadCount: 0,
      );
    } catch (e) {
      print('Failed to mark notifications read: $e');
    }
  }

  void toggleNotifications(bool value) {
    state = state.copyWith(isEnabled: value);
  }

  void clearNotifications() {
    state = state.copyWith(notifications: [], unreadCount: 0);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
