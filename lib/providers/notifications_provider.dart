import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain/api.dart';
import 'package:grain/models/notification.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<Notification>>((
  ref,
) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<List<Notification>> {
  NotificationsNotifier() : super([]) {
    _connectAndListen();
  }

  WebSocket? _ws;
  StreamSubscription? _wsSubscription;

  void _connectAndListen() async {
    _ws = await apiService.connectAndListenWs(
      onMessage: (message) async {
        try {
          final data = message is String ? jsonDecode(message) : message;
          if (data is Map<String, dynamic> && data['type'] == 'refresh-notifications') {
            final notifications = await apiService.getNotifications();
            state = notifications;
          } else {
            final notification = Notification.fromJson(data);
            state = [...state, notification];
          }
        } catch (e) {
          // Handle parse error or ignore non-notification messages
        }
      },
    );
  }

  /// Marks all notifications as seen both on the server and locally.
  Future<void> updateSeen() async {
    final success = await apiService.updateSeen();
    if (success) {
      state = [for (final n in state) n.copyWith(isRead: true)];
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _ws?.close();
    super.dispose();
  }
}
