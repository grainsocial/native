import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api.dart';
import '../models/gallery.dart';

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
}
