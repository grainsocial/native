import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jose/jose.dart';

part 'atproto_session.freezed.dart';
part 'atproto_session.g.dart';

@freezed
class AtprotoSession with _$AtprotoSession {
  const factory AtprotoSession({
    required String accessToken,
    required String tokenType,
    required DateTime expiresAt,
    required JsonWebKey dpopJwk,
    required String issuer,
    required String subject,
  }) = _AtprotoSession;

  factory AtprotoSession.fromJson(Map<String, dynamic> json) => _$AtprotoSessionFromJson(json);
}
