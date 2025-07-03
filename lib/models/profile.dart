import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String did,
    required String handle,
    String? displayName,
    String? description,
    String? avatar,
    int? followersCount,
    int? followsCount,
    int? galleryCount,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
