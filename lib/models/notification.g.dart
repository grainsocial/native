// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationImpl _$$NotificationImplFromJson(Map<String, dynamic> json) =>
    _$NotificationImpl(
      uri: json['uri'] as String,
      cid: json['cid'] as String,
      author: Profile.fromJson(json['author'] as Map<String, dynamic>),
      record: json['record'] as Map<String, dynamic>,
      reason: json['reason'] as String,
      reasonSubject: json['reasonSubject'] as String?,
      isRead: json['isRead'] as bool,
      indexedAt: json['indexedAt'] as String,
    );

Map<String, dynamic> _$$NotificationImplToJson(_$NotificationImpl instance) =>
    <String, dynamic>{
      'uri': instance.uri,
      'cid': instance.cid,
      'author': instance.author,
      'record': instance.record,
      'reason': instance.reason,
      'reasonSubject': instance.reasonSubject,
      'isRead': instance.isRead,
      'indexedAt': instance.indexedAt,
    };
