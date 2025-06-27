class Profile {
  final String did;
  final String handle;
  final String displayName;
  final String description;
  final String avatar;
  final int followersCount;
  final int followsCount;
  final int galleryCount;

  Profile({
    required this.did,
    required this.handle,
    required this.displayName,
    required this.description,
    required this.avatar,
    required this.followersCount,
    required this.followsCount,
    required this.galleryCount,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      did: json['did'] ?? '',
      handle: json['handle'] ?? '',
      displayName: json['displayName'] ?? '',
      description: json['description'] ?? '',
      avatar: json['avatar'] ?? '',
      followersCount: json['followersCount'] ?? 0,
      followsCount: json['followsCount'] ?? 0,
      galleryCount: json['galleryCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'did': did,
      'handle': handle,
      'displayName': displayName,
      'description': description,
      'avatar': avatar,
      'followersCount': followersCount,
      'followsCount': followsCount,
      'galleryCount': galleryCount,
    };
  }
}
