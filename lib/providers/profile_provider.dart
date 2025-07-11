import 'dart:io';

import 'package:bluesky_text/bluesky_text.dart';
import 'package:grain/api.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/models/profile.dart';
import 'package:grain/models/profile_with_galleries.dart';
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
    if (profile != null) {
      final facets = await computeAndFilterFacets(profile.description);
      return ProfileWithGalleries(
        profile: profile.copyWith(descriptionFacets: facets),
        galleries: galleries,
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
    final currentProfile = state.value?.profile;
    final isUnchanged =
        currentProfile != null &&
        currentProfile.displayName == displayName &&
        currentProfile.description == description &&
        avatarFile == null;
    if (isUnchanged) {
      // No changes, skip API call
      return true;
    }
    File? file;
    if (avatarFile is XFile) {
      file = File(avatarFile.path);
    } else if (avatarFile is File) {
      file = avatarFile;
    } else {
      file = null;
    }
    final success = await apiService.updateProfile(
      displayName: displayName,
      description: description,
      avatarFile: file,
    );
    if (success) {
      final start = DateTime.now();
      const timeout = Duration(seconds: 20);
      const pollInterval = Duration(milliseconds: 1000);
      Profile? updated;
      final prevCid = state.value?.profile.cid;
      state = const AsyncValue.loading(); // Force UI to show loading and rebuild
      while (DateTime.now().difference(start) < timeout) {
        updated = await apiService.fetchProfile(did: did);
        if (updated != null && updated.cid != prevCid) {
          break;
        }
        await Future.delayed(pollInterval);
      }
      // Always assign a new instance to state
      if (updated != null) {
        final galleries = await apiService.fetchActorGalleries(did: did);
        final facets = await computeAndFilterFacets(updated.description);
        // Update the gallery cache provider
        ref.read(galleryCacheProvider.notifier).setGalleriesForActor(did, galleries);
        state = AsyncValue.data(
          ProfileWithGalleries(
            profile: updated.copyWith(descriptionFacets: facets),
            galleries: galleries,
          ),
        );
      } else {
        state = const AsyncValue.data(null);
      }
      if (updated == null) {
        await refresh();
      }
    }
    return success;
  }

  Future<void> toggleFollow(String? followerDid) async {
    final current = state.value;
    final profile = current?.profile;
    if (profile == null || followerDid == null) return;
    final viewer = profile.viewer;
    final followUri = viewer?.following;
    if (followUri != null && followUri.isNotEmpty) {
      // Unfollow
      final success = await apiService.deleteRecord(followUri);
      if (success) {
        final updatedProfile = profile.copyWith(
          viewer: viewer?.copyWith(following: null),
          followersCount: (profile.followersCount ?? 1) - 1,
        );
        state = AsyncValue.data(
          ProfileWithGalleries(profile: updatedProfile, galleries: current!.galleries),
        );
      }
    } else {
      // Follow
      final newFollowUri = await apiService.createFollow(followeeDid: did);
      if (newFollowUri != null) {
        final updatedProfile = profile.copyWith(
          viewer: viewer?.copyWith(following: newFollowUri),
          followersCount: (profile.followersCount ?? 0) + 1,
        );
        state = AsyncValue.data(
          ProfileWithGalleries(profile: updatedProfile, galleries: current!.galleries),
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
        ProfileWithGalleries(profile: updatedProfile, galleries: updatedGalleries),
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
        ProfileWithGalleries(profile: updatedProfile, galleries: updatedGalleries),
      );
    }
  }
}
