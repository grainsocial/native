import 'profile.dart';

class Notification {
  final String uri;
  final String cid;
  final Profile author;
  final Map<String, dynamic> record;
  final String reason;
  final String? reasonSubject;
  final bool isRead;
  final String indexedAt;

  Notification({
    required this.uri,
    required this.cid,
    required this.author,
    required this.record,
    required this.reason,
    this.reasonSubject,
    required this.isRead,
    required this.indexedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      uri: json['uri'] as String,
      cid: json['cid'] as String,
      author: Profile.fromJson(json['author'] as Map<String, dynamic>),
      record: json['record'] as Map<String, dynamic>,
      reason: json['reason'] as String,
      reasonSubject: json['reasonSubject'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      indexedAt: json['indexedAt'] as String,
    );
  }
}
