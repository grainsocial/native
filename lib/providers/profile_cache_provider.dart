import 'package:grain/api.dart';
import 'package:grain/models/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_cache_provider.g.dart';

@Riverpod(keepAlive: true)
class ProfileCache extends _$ProfileCache {
  @override
  Map<String, Profile> build() => {};

  Future<Profile?> fetch(String did) async {
    if (state.containsKey(did)) {
      return state[did];
    }
    final profile = await apiService.fetchProfile(did: did);
    if (profile != null) {
      state = {...state, did: profile};
    }
    return profile;
  }

  void setProfile(Profile profile) {
    state = {...state, profile.did: profile};
  }

  Future<void> toggleFollow(String followeeDid, String? followerDid) async {
    final profile = state[followeeDid];
    if (profile == null || followerDid == null) return;
    final viewer = profile.viewer;
    final followUri = viewer?.following;
    if (followUri != null && followUri.isNotEmpty) {
      // Unfollow
      final success = await apiService.deleteRecord(followUri);
      if (success) {
        final updatedProfile = profile.copyWith(viewer: viewer?.copyWith(following: null));
        state = {...state, followeeDid: updatedProfile};
      }
    } else {
      // Follow
      final newFollowUri = await apiService.createFollow(followeeDid: followeeDid);
      if (newFollowUri != null) {
        final updatedProfile = profile.copyWith(viewer: viewer?.copyWith(following: newFollowUri));
        state = {...state, followeeDid: updatedProfile};
      }
    }
  }
}
