import 'dart:io';

import 'package:bluesky_text/bluesky_text.dart';
import 'package:flutter/foundation.dart';
import 'package:grain/api.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/models/procedures/create_follow_request.dart';
import 'package:grain/models/procedures/delete_follow_request.dart';
import 'package:grain/models/procedures/update_profile_request.dart';
import 'package:grain/models/profile_with_galleries.dart';
import 'package:grain/photo_manip.dart';
import 'package:grain/providers/gallery_cache_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_provider.g.dart';

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<ProfileWithGalleries?> build(String did) async {
    return _fetchProfile(did);
  }

  // @TODO: Facets don't always render correctly.
  List<Map<String, dynamic>>? _filterValidFacets(
    List<Map<String, dynamic>>? computedFacets,
    String desc,
  ) {
    if (computedFacets == null) return null;
    return computedFacets.where((facet) {
      final index = facet['index'];
      if (index is Map) {
        final start = index['byteStart'] ?? 0;
        final end = index['byteEnd'] ?? 0;
        return start is int && end is int && start >= 0 && end > start && end <= desc.length;
      }
      final start = facet['index'] ?? facet['offset'] ?? 0;
      final end = facet['end'];
      final length = facet['length'];
      if (end is int && start is int) {
        return start >= 0 && end > start && end <= desc.length;
      } else if (length is int && start is int) {
        return start >= 0 && length > 0 && start + length <= desc.length;
      }
      return false;
    }).toList();
  }

  // Extract facet computation and filtering for reuse
  Future<List<Map<String, dynamic>>?> computeAndFilterFacets(String? description) async {
    final desc = description ?? '';
    if (desc.isEmpty) return null;
    try {
      final blueskyText = BlueskyText(desc);
      final entities = blueskyText.entities;
      final computedFacets = await entities.toFacets();
      return _filterValidFacets(computedFacets, desc);
    } catch (_) {
      return null;
    }
  }

  Future<ProfileWithGalleries?> _fetchProfile(String did) async {
    final profile = await apiService.fetchProfile(did: did);
    final galleries = await apiService.fetchActorGalleries(did: did);
    final favs = await apiService.getActorFavs(did: did);
    if (profile != null) {
      final facets = await computeAndFilterFacets(profile.description);
      return ProfileWithGalleries(
        profile: profile.copyWith(descriptionFacets: facets),
        galleries: galleries,
        favs: favs,
      );
    }
    return null;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProfile(did));
  }

  Future<bool> updateProfile({
    required String displayName,
    required String description,
    dynamic avatarFile,
  }) async {
    File? file;
    if (avatarFile is XFile) {
      file = File(avatarFile.path);
    } else if (avatarFile is File) {
      file = avatarFile;
    } else {
      file = null;
    }
    final profileRes = await apiService.updateProfile(
      request: UpdateProfileRequest(displayName: displayName, description: description),
    );
    bool avatarSuccess = true;
    if (file != null) {
      final resizedResult = await compute<File, ResizeResult>((f) => resizeImage(file: f), file);
      final avatarRes = await apiService.updateAvatar(avatarFile: resizedResult.file);
      avatarSuccess = avatarRes.success;
    }
    // Refetch updated profile if update succeeded
    if (profileRes.success || avatarSuccess) {
      final updated = await apiService.fetchProfile(did: did);
      if (updated != null) {
        final galleries = await apiService.fetchActorGalleries(did: did);
        final facets = await computeAndFilterFacets(updated.description);
        ref.read(galleryCacheProvider.notifier).setGalleriesForActor(did, galleries);
        state = AsyncValue.data(
          ProfileWithGalleries(
            profile: updated.copyWith(descriptionFacets: facets),
            galleries: galleries,
            favs: state.value?.favs ?? [],
          ),
        );
      } else {
        state = const AsyncValue.data(null);
        await refresh();
      }
      return true;
    } else {
      await refresh();
      return false;
    }
  }

  Future<void> toggleFollow(String? followerDid) async {
    final current = state.value;
    final profile = current?.profile;
    if (profile == null || followerDid == null) return;
    final viewer = profile.viewer;
    final followUri = viewer?.following;
    if (followUri != null && followUri.isNotEmpty) {
      // Unfollow
      final res = await apiService.deleteFollow(request: DeleteFollowRequest(uri: followUri));
      if (res.success) {
        final updatedProfile = profile.copyWith(
          viewer: viewer?.copyWith(following: null),
          followersCount: (profile.followersCount ?? 1) - 1,
        );
        state = AsyncValue.data(
          ProfileWithGalleries(
            profile: updatedProfile,
            galleries: current?.galleries ?? [],
            favs: current?.favs,
          ),
        );
      }
    } else {
      // Follow
      final res = await apiService.createFollow(request: CreateFollowRequest(subject: followerDid));
      if (res.followUri.isNotEmpty) {
        final updatedProfile = profile.copyWith(
          viewer: viewer?.copyWith(following: res.followUri),
          followersCount: (profile.followersCount ?? 0) + 1,
        );
        state = AsyncValue.data(
          ProfileWithGalleries(
            profile: updatedProfile,
            galleries: current?.galleries ?? [],
            favs: current?.favs,
          ),
        );
      }
    }
  }

  void addGalleryToProfile(Gallery newGallery) {
    final currentProfile = state.value;
    if (currentProfile != null) {
      final updatedGalleries = [newGallery, ...currentProfile.galleries];
      final updatedProfile = currentProfile.profile.copyWith(
        galleryCount: (currentProfile.profile.galleryCount ?? 0) + 1,
      );
      state = AsyncValue.data(
        ProfileWithGalleries(
          profile: updatedProfile,
          galleries: updatedGalleries,
          favs: currentProfile.favs,
        ),
      );
    }
  }

  void removeGalleryFromProfile(String galleryUri) {
    final currentProfile = state.value;
    if (currentProfile != null) {
      final updatedGalleries = currentProfile.galleries.where((g) => g.uri != galleryUri).toList();
      final updatedProfile = currentProfile.profile.copyWith(
        galleryCount: (currentProfile.profile.galleryCount ?? 1) - 1,
      );
      state = AsyncValue.data(
        ProfileWithGalleries(
          profile: updatedProfile,
          galleries: updatedGalleries,
          favs: currentProfile.favs,
        ),
      );
    }
  }

  /// Adds a gallery to the user's favorites in the profile state.
  void addFavorite(Gallery gallery) {
    final currentProfile = state.value;
    if (currentProfile != null) {
      final updatedFavs = [gallery, ...?currentProfile.favs];
      state = AsyncValue.data(
        ProfileWithGalleries(
          profile: currentProfile.profile,
          galleries: currentProfile.galleries,
          favs: updatedFavs,
        ),
      );
    }
  }

  /// Removes a gallery from the user's favorites in the profile state by URI.
  void removeFavorite(String galleryUri) {
    final currentProfile = state.value;
    if (currentProfile != null) {
      final updatedFavs = (currentProfile.favs ?? []).where((g) => g.uri != galleryUri).toList();
      state = AsyncValue.data(
        ProfileWithGalleries(
          profile: currentProfile.profile,
          galleries: currentProfile.galleries,
          favs: updatedFavs,
        ),
      );
    }
  }
}
