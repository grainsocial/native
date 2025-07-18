import 'package:freezed_annotation/freezed_annotation.dart';

import 'atproto_session.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
class Session with _$Session {
  const factory Session({
    required AtprotoSession session,
    required String token,
    required String pds,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);
}
