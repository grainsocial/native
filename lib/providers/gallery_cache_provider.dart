import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bluesky_text/bluesky_text.dart';
import 'package:flutter/foundation.dart';
import 'package:grain/models/gallery_photo.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api.dart';
import '../models/gallery.dart';
import '../models/gallery_item.dart';
import '../photo_manip.dart';
import '../utils/exif_utils.dart';

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

  Future<List<Map<String, dynamic>>> _extractFacets(String text) async {
    final blueskyText = BlueskyText(text);
    final entities = blueskyText.entities;
    final facets = await entities.toFacets();
    return List<Map<String, dynamic>>.from(facets);
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
    bool includeExif = true,
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
      final file = File(xfile.path);
      // Parse EXIF if requested
      final exif = includeExif ? await parseAndNormalizeExif(file: file) : null;
      // Resize the image
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

      // If EXIF data was found, create photo exif record
      if (exif != null) {
        await apiService.createPhotoExif(
          photo: photoUri,
          dateTimeOriginal: exif['dateTimeOriginal'] as String?,
          exposureTime: exif['exposureTime'] as int?,
          fNumber: exif['fNumber'] as int?,
          flash: exif['flash'] as String?,
          focalLengthIn35mmFormat: exif['focalLengthIn35mmFilm'] as int?,
          iSO: exif['iSOSpeedRatings'] as int?,
          lensMake: exif['lensMake'] as String?,
          lensModel: exif['lensModel'] as String?,
          make: exif['make'] as String?,
          model: exif['model'] as String?,
        );
      }

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
    bool includeExif = true,
  }) async {
    // Extract facets from description
    final facetsList = await _extractFacets(description);
    final facets = facetsList.isEmpty ? null : facetsList;
    // Create the gallery with facets
    final galleryUri = await apiService.createGallery(
      title: title,
      description: description,
      facets: facets,
    );
    if (galleryUri == null) return (null, <String>[]);
    // Upload and add photos
    final photoUris = await uploadAndAddPhotosToGallery(
      galleryUri: galleryUri,
      xfiles: xfiles,
      includeExif: includeExif,
    );
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
    // Fetch the latest gallery from backend to ensure all items are deleted
    final gallery = await apiService.getGallery(uri: uri);
    if (gallery != null) {
      // Delete all gallery item records
      for (final item in gallery.items) {
        final itemUri = item.gallery?.item;
        if (itemUri != null && itemUri.isNotEmpty) {
          await apiService.deleteRecord(itemUri);
        }
      }
    }
    await apiService.deleteRecord(uri);
    removeGallery(uri);
  }

  /// Reorders gallery items and updates backend, then updates cache.
  Future<void> reorderGalleryItems({
    required String galleryUri,
    required List<GalleryPhoto> newOrder,
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
        position: photo.gallery?.itemPosition ?? 0,
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

  /// Updates gallery details (title, description), polls for cid change, and updates cache.
  Future<bool> updateGalleryDetails({
    required String galleryUri,
    required String title,
    required String description,
    required String createdAt,
  }) async {
    final prevGallery = state[galleryUri];
    final prevCid = prevGallery?.cid;
    // Extract facets from description
    final facetsList = await _extractFacets(description);
    final facets = facetsList.isEmpty ? null : facetsList;
    final success = await apiService.updateGallery(
      galleryUri: galleryUri,
      title: title,
      description: description,
      createdAt: createdAt,
      facets: facets,
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

  /// Fetches timeline galleries from the API and updates the cache.
  /// Returns the list of galleries.
  Future<List<Gallery>> fetchTimeline({String? algorithm}) async {
    final galleries = await apiService.getTimeline(algorithm: algorithm);
    setGalleries(galleries);
    return galleries;
  }

  /// Updates alt text for multiple photos by calling apiService.updatePhotos, then updates the gallery cache state manually.
  /// [galleryUri]: The URI of the gallery containing the photos.
  /// [altUpdates]: List of maps with keys: photoUri, alt (and optionally aspectRatio, createdAt, photo).
  Future<bool> updatePhotoAltTexts({
    required String galleryUri,
    required List<Map<String, dynamic>> altUpdates,
  }) async {
    final success = await apiService.updatePhotos(altUpdates);
    if (!success) return false;

    // Update the gallery photos' alt text in the cache manually
    final gallery = state[galleryUri];
    if (gallery == null) return false;

    // Build a map of photoUri to new alt text
    final altMap = {for (final update in altUpdates) update['photoUri'] as String: update['alt']};

    final updatedPhotos = gallery.items.map((photo) {
      final newAlt = altMap[photo.uri];
      if (newAlt != null) {
        return photo.copyWith(alt: newAlt);
      }
      return photo;
    }).toList();

    final updatedGallery = gallery.copyWith(items: updatedPhotos);
    state = {...state, galleryUri: updatedGallery};
    return true;
  }
}
