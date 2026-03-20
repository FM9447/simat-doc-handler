import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationState {
  final bool isEnabled;
  final List<Map<String, String>> messages;

  NotificationState({
    required this.isEnabled,
    required this.messages,
  });

  NotificationState copyWith({
    bool? isEnabled,
    List<Map<String, String>>? messages,
  }) {
    return NotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      messages: messages ?? this.messages,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState(
    isEnabled: true,
    messages: [
      {'title': 'Welcome to AntiGravity', 'body': 'Start submitting your document requests today!', 'time': 'Just now'},
      {'title': 'System Update', 'body': 'New features added: Scan document and History.', 'time': '1h ago'},
      {'title': 'Pending Approval', 'body': 'You have 3 documents awaiting your review.', 'time': '2h ago'},
    ],
  ));

  void toggleNotifications(bool value) {
    state = state.copyWith(isEnabled: value);
  }

  void addNotification(String title, String body) {
    state = state.copyWith(
      messages: [
        {'title': title, 'body': body, 'time': 'Just now'},
        ...state.messages,
      ],
    );
  }

  void clearNotifications() {
    state = state.copyWith(messages: []);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
