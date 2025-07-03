import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class Notification with _$Notification {
  const factory Notification({
    required String uri,
    required String cid,
    required Profile author,
    required Map<String, dynamic> record,
    required String reason,
    String? reasonSubject,
    required bool isRead,
    required String indexedAt,
  }) = _Notification;

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);
}
