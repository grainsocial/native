import 'package:bluesky_text/bluesky_text.dart';
import 'package:grain/api.dart';
import 'package:grain/models/comment.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/providers/gallery_cache_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_thread_cache_provider.g.dart';

class GalleryThreadState {
  final bool loading;
  final bool error;
  final Gallery? gallery;
  final List<Comment> comments;
  final String? errorMessage;
  const GalleryThreadState({
    this.loading = false,
    this.error = false,
    this.gallery,
    this.comments = const [],
    this.errorMessage,
  });

  GalleryThreadState copyWith({
    bool? loading,
    bool? error,
    Gallery? gallery,
    List<Comment>? comments,
    String? errorMessage,
  }) {
    return GalleryThreadState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      gallery: gallery ?? this.gallery,
      comments: comments ?? this.comments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

@Riverpod(keepAlive: false)
class GalleryThread extends _$GalleryThread {
  late String galleryUri;

  @override
  GalleryThreadState build(String galleryUriParam) {
    galleryUri = galleryUriParam;
    // Set initial state synchronously, schedule fetchThread async
    Future.microtask(fetchThread);
    return const GalleryThreadState(loading: true);
  }

  Future<void> fetchThread() async {
    state = state.copyWith(loading: true, error: false);
    try {
      final thread = await apiService.getGalleryThread(uri: galleryUri);
      state = state.copyWith(
        gallery: thread?.gallery,
        comments: thread?.comments ?? [],
        loading: false,
        error: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: true, errorMessage: e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> _extractFacets(String text) async {
    final blueskyText = BlueskyText(text);
    final entities = blueskyText.entities;
    final facets = await entities.toFacets();
    return List<Map<String, dynamic>>.from(facets);
  }

  Future<bool> createComment({required String text, String? replyTo}) async {
    try {
      final facetsList = await _extractFacets(text);
      final facets = facetsList.isEmpty ? null : facetsList;
      final uri = await apiService.createComment(
        text: text,
        subject: galleryUri,
        replyTo: replyTo,
        facets: facets,
      );
      if (uri != null) {
        final thread = await apiService.pollGalleryThreadComments(
          galleryUri: galleryUri,
          expectedCount: state.comments.length + 1,
        );
        if (thread != null) {
          state = state.copyWith(gallery: thread.gallery, comments: thread.comments);
          // Update the gallery cache with the latest gallery
          ref.read(galleryCacheProvider.notifier).setGallery(thread.gallery);
        } else {
          await fetchThread();
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteComment(Comment comment) async {
    final deleted = await apiService.deleteRecord(comment.uri);
    if (!deleted) return false;
    final expectedCount = state.comments.length - 1;
    final thread = await apiService.pollGalleryThreadComments(
      galleryUri: galleryUri,
      expectedCount: expectedCount,
    );
    if (thread != null) {
      state = state.copyWith(gallery: thread.gallery, comments: thread.comments);
      // Update the gallery cache with the latest gallery
      ref.read(galleryCacheProvider.notifier).setGallery(thread.gallery);
    } else {
      await fetchThread();
    }
    return true;
  }
}
