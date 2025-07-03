// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'atproto_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AtprotoSessionImpl _$$AtprotoSessionImplFromJson(Map<String, dynamic> json) =>
    _$AtprotoSessionImpl(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      dpopJwk: JsonWebKey.fromJson(json['dpopJwk'] as Map<String, dynamic>),
      issuer: json['issuer'] as String,
      subject: json['subject'] as String,
    );

Map<String, dynamic> _$$AtprotoSessionImplToJson(
  _$AtprotoSessionImpl instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'tokenType': instance.tokenType,
  'expiresAt': instance.expiresAt.toIso8601String(),
  'dpopJwk': instance.dpopJwk,
  'issuer': instance.issuer,
  'subject': instance.subject,
};
