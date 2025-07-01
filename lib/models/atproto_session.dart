import 'package:jose/jose.dart';

class AtprotoSession {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final DateTime expiresAt;
  final JsonWebKey dpopJwk;
  final String issuer;
  final String subject;

  AtprotoSession({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
    required this.expiresAt,
    required this.dpopJwk,
    required this.issuer,
    required this.subject,
  });

  factory AtprotoSession.fromJson(Map<String, dynamic> json) {
    final token = json['tokenSet'] ?? {};
    final dpopJwkJson = json['dpopJwk'] ?? {};

    return AtprotoSession(
      accessToken: token['access_token'],
      refreshToken: token['refresh_token'],
      tokenType: token['token_type'],
      expiresAt: DateTime.parse(token['expires_at']),
      dpopJwk: JsonWebKey.fromJson(dpopJwkJson),
      issuer: token['iss'],
      subject: token['sub'],
    );
  }

  Map<String, dynamic> toJson() => {
    'tokenSet': {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_at': expiresAt.toIso8601String(),
      'iss': issuer,
      'sub': subject,
    },
    'dpopJwk': dpopJwk.toJson(),
  };
}
