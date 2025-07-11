import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api.dart';
import '../models/gallery.dart';
import '../models/gallery_item.dart';
import '../photo_manip.dart';

part 'gallery_cache_provider.g.dart';

/// Holds a cache of galleries by URI.
@Riverpod(keepAlive: true)
class GalleryCache extends _$GalleryCache {
  @override
  Map<String, Gallery> build() => {};

  void setGalleries(List<Gallery> galleries) {
    final newMap = {for (final g in galleries) g.uri: g};
    state = {...state, ...newMap};
  }

  void setGallery(Gallery gallery) {
    state = {...state, gallery.uri: gallery};
  }

  void removeGallery(String uri) {
    final newState = {...state}..remove(uri);
    state = newState;
  }

  Gallery? getGallery(String uri) => state[uri];

  void setGalleriesForActor(String did, List<Gallery> galleries) {
    setGalleries(galleries);
    // Optionally, you could keep a mapping of actor DID to gallery URIs if needed
  }

  Future<void> toggleFavorite(String uri) async {
    // Fetch the latest gallery from the API to ensure up-to-date favorite state
    final latestGallery = await apiService.getGallery(uri: uri);
    if (latestGallery == null) return;
    final isCurrentlyFav = latestGallery.viewer?.fav != null;
    final isFav = !isCurrentlyFav;
    bool success = false;
    String? newFavUri;
    if (isFav) {
      newFavUri = await apiService.createFavorite(galleryUri: uri);
      success = newFavUri != null;
    } else {
      success = await apiService.deleteRecord(latestGallery.viewer?.fav ?? uri);
      newFavUri = null;
    }
    if (success) {
      final newCount = (latestGallery.favCount ?? 0) + (isFav ? 1 : -1);
      final updatedViewer = latestGallery.viewer?.copyWith(fav: newFavUri);
      state = {...state, uri: latestGallery.copyWith(favCount: newCount, viewer: updatedViewer)};
    }
  }

  /// Removes a photo from a gallery in the cache by galleryItemUri and deletes it from the backend.
  Future<void> removePhotoFromGallery(String galleryUri, String galleryItemUri) async {
    final gallery = state[galleryUri];
    if (gallery == null) return;
    // Call backend to delete the gallery item
    await apiService.deleteRecord(galleryItemUri);
    // Remove by gallery item record URI, not photo URI
    final updatedItems = gallery.items.where((p) => p.gallery?.item != galleryItemUri).toList();
    final updatedGallery = gallery.copyWith(items: updatedItems);
    state = {...state, galleryUri: updatedGallery};
  }

  /// Uploads multiple photos, gets their dimensions, resizes them, creates the photos, and adds them as gallery items.
  /// At the end, polls for the updated gallery items and updates the cache.
  /// Returns the list of new photoUris if successful, or empty list otherwise.
  Future<List<String>> uploadAndAddPhotosToGallery({
    required String galleryUri,
    required List<XFile> xfiles,
    int? startPosition,
  }) async {
    // Fetch the latest gallery from the API to avoid stale state
    final latestGallery = await apiService.getGallery(uri: galleryUri);
    if (latestGallery != null) {
      state = {...state, galleryUri: latestGallery};
    }
    final gallery = latestGallery ?? state[galleryUri];
    final int initialCount = gallery?.items.length ?? 0;
    final int positionOffset = startPosition ?? initialCount;
    final List<String> photoUris = [];
    int position = positionOffset;
    for (final xfile in xfiles) {
      // Resize the image
      final file = File(xfile.path);
      final resizedResult = await compute<File, ResizeResult>((f) => resizeImage(file: f), file);
      // Upload the blob
      final blobResult = await apiService.uploadBlob(resizedResult.file);
      if (blobResult == null) continue;
      // Get image dimensions
      final bytes = await xfile.readAsBytes();
      final completer = Completer<Map<String, int>>();
      ui.decodeImageFromList(bytes, (image) {
        completer.complete({'width': image.width, 'height': image.height});
      });
      final dims = await completer.future;
      // Create the photo
      final photoUri = await apiService.createPhoto(
        blob: blobResult,
        width: dims['width']!,
        height: dims['height']!,
      );
      if (photoUri == null) continue;
      // Create the gallery item
      await apiService.createGalleryItem(
        galleryUri: galleryUri,
        photoUri: photoUri,
        position: position,
      );
      photoUris.add(photoUri);
      position++;
    }
    // Poll for updated gallery items
    final expectedCount = (gallery?.items.length ?? 0) + photoUris.length;
    await apiService.pollGalleryItems(galleryUri: galleryUri, expectedCount: expectedCount);
    // Fetch the updated gallery and update the cache
    final updatedGallery = await apiService.getGallery(uri: galleryUri);
    if (updatedGallery != null) {
      state = {...state, galleryUri: updatedGallery};
    }
    return photoUris;
  }

  /// Creates a new gallery, uploads photos, and adds them as gallery items.
  /// Returns the new gallery URI and the list of new photoUris if successful, or null/empty list otherwise.
  Future<(String?, List<String>)> createGalleryAndAddPhotos({
    required String title,
    required String description,
    required List<XFile> xfiles,
  }) async {
    // Create the gallery
    final galleryUri = await apiService.createGallery(title: title, description: description);
    if (galleryUri == null) return (null, <String>[]);
    // Upload and add photos
    final photoUris = await uploadAndAddPhotosToGallery(galleryUri: galleryUri, xfiles: xfiles);
    return (galleryUri, photoUris);
  }

  /// Creates gallery items for existing photoUris, polls for updated gallery items, and updates the cache.
  /// Returns the list of new gallery item URIs if successful, or empty list otherwise.
  Future<List<String>> addGalleryItemsToGallery({
    required String galleryUri,
    required List<String> photoUris,
    int? startPosition,
  }) async {
    // Fetch the latest gallery from the API to avoid stale state
    final latestGallery = await apiService.getGallery(uri: galleryUri);
    if (latestGallery != null) {
      state = {...state, galleryUri: latestGallery};
    }
    final gallery = latestGallery ?? state[galleryUri];
    final int initialCount = gallery?.items.length ?? 0;
    final int positionOffset = startPosition ?? initialCount;
    final List<String> galleryItemUris = [];
    int position = positionOffset;
    for (final photoUri in photoUris) {
      // Create the gallery item
      final itemUri = await apiService.createGalleryItem(
        galleryUri: galleryUri,
        photoUri: photoUri,
        position: position,
      );
      if (itemUri != null) {
        galleryItemUris.add(itemUri);
        position++;
      }
    }
    // Poll for updated gallery items
    final expectedCount = (gallery?.items.length ?? 0) + galleryItemUris.length;
    await apiService.pollGalleryItems(galleryUri: galleryUri, expectedCount: expectedCount);
    // Fetch the updated gallery and update the cache
    final updatedGallery = await apiService.getGallery(uri: galleryUri);
    if (updatedGallery != null) {
      state = {...state, galleryUri: updatedGallery};
    }
    return galleryItemUris;
  }

  /// Deletes a gallery from the backend and removes it from the cache.
  Future<void> deleteGallery(String uri) async {
    await apiService.deleteRecord(uri);
    removeGallery(uri);
  }

  /// Reorders gallery items and updates backend, then updates cache.
  Future<void> reorderGalleryItems({
    required String galleryUri,
    required List<dynamic> newOrder, // List<GalleryPhoto>
  }) async {
    final gallery = state[galleryUri];
    if (gallery == null) return;
    final orderedItems = newOrder.map((photo) {
      // Map GalleryPhoto to GalleryItem
      return GalleryItem(
        uri: photo.gallery?.item ?? '',
        gallery: galleryUri,
        item: photo.uri,
        createdAt: photo.gallery?.itemCreatedAt ?? '',
        position: photo.gallery?.itemPosition,
      );
    }).toList();
    // Optionally update positions if needed
    for (int i = 0; i < orderedItems.length; i++) {
      orderedItems[i] = orderedItems[i].copyWith(position: i);
    }
    await apiService.updateGallerySortOrder(galleryUri: galleryUri, orderedItems: orderedItems);
    // Update cache with new order
    final updatedPhotos = orderedItems
        .where((item) => gallery.items.any((p) => p.uri == item.item))
        .map((item) {
          final photo = gallery.items.firstWhere((p) => p.uri == item.item);
          return photo.copyWith(gallery: photo.gallery?.copyWith(itemPosition: item.position));
        })
        .toList();
    final updatedGallery = gallery.copyWith(items: updatedPhotos);
    state = {...state, galleryUri: updatedGallery};
  }

  /// Updates gallery details (title, description) and updates cache if successful.
  /// Updates gallery details (title, description, createdAt), polls for cid change, and updates cache.
  Future<bool> updateGalleryDetails({
    required String galleryUri,
    required String title,
    required String description,
    required String createdAt,
  }) async {
    final prevGallery = state[galleryUri];
    final prevCid = prevGallery?.cid;
    final success = await apiService.updateGallery(
      galleryUri: galleryUri,
      title: title,
      description: description,
      createdAt: createdAt,
    );
    if (success) {
      final start = DateTime.now();
      const timeout = Duration(seconds: 20);
      const pollInterval = Duration(milliseconds: 1000);
      Gallery? updatedGallery;
      while (DateTime.now().difference(start) < timeout) {
        updatedGallery = await apiService.getGallery(uri: galleryUri);
        if (updatedGallery != null && updatedGallery.cid != prevCid) {
          break;
        }
        await Future.delayed(pollInterval);
      }
      if (updatedGallery != null) {
        state = {...state, galleryUri: updatedGallery};
      }
    }
    return success;
  }
}
