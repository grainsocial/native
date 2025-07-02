import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/screens/create_gallery_page.dart';
import 'package:grain/screens/profile_page.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/widgets/faceted_text.dart';
import 'package:grain/widgets/gallery_action_buttons.dart';
import 'package:grain/widgets/gallery_photo_view.dart';
import 'package:grain/widgets/justified_gallery_view.dart';

class GalleryPage extends StatefulWidget {
  final String uri;
  final String? currentUserDid;
  const GalleryPage({super.key, required this.uri, this.currentUserDid});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  Gallery? _gallery;
  bool _loading = true;
  bool _error = false;
  GalleryPhoto? _selectedPhoto;
  int? _selectedPhotoIndex;

  @override
  void initState() {
    super.initState();
    _fetchGallery();
  }

  Future<void> _fetchGallery() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final gallery = await apiService.getGallery(uri: widget.uri);
      setState(() {
        _gallery = gallery;
        _loading = false;
      });
      // Pre-cache thumbnails and fullsize images in the background
      if (gallery != null) {
        Future.microtask(() {
          for (final item in gallery.items) {
            if (item.thumb.isNotEmpty) {
              precacheImage(CachedNetworkImageProvider(item.thumb), context);
            }
            if (item.fullsize.isNotEmpty) {
              precacheImage(CachedNetworkImageProvider(item.fullsize), context);
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0EA5E9)),
        ),
      );
    }
    if (_error || _gallery == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: Text('Failed to load gallery.')),
      );
    }
    final gallery = _gallery!;
    final isLoggedIn = widget.currentUserDid != null;
    final galleryItems = gallery.items.where((item) => item.thumb.isNotEmpty).toList();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.appBarTheme.backgroundColor,
            surfaceTintColor: theme.appBarTheme.backgroundColor,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: theme.dividerColor, height: 1),
            ),
            title: Text(
              'Gallery',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            iconTheme: theme.appBarTheme.iconTheme,
            titleTextStyle: theme.appBarTheme.titleTextStyle,
            actions: [
              if (gallery.creator?.did == widget.currentUserDid)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Gallery',
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => CreateGalleryPage(gallery: gallery),
                    );
                    _fetchGallery();
                  },
                ),
            ],
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      gallery.title.isNotEmpty ? gallery.title : 'Gallery',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: gallery.creator != null && gallery.creator!.did.isNotEmpty
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfilePage(did: gallery.creator!.did, showAppBar: true),
                                    ),
                                  );
                                }
                              : null,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            backgroundImage:
                                gallery.creator?.avatar != null &&
                                    gallery.creator!.avatar.isNotEmpty
                                ? null
                                : null,
                            child: (gallery.creator == null || gallery.creator!.avatar.isEmpty)
                                ? Icon(
                                    Icons.account_circle,
                                    size: 24,
                                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                                  )
                                : ClipOval(
                                    child: AppImage(
                                      url: gallery.creator!.avatar,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: gallery.creator != null && gallery.creator!.did.isNotEmpty
                                ? () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ProfilePage(
                                          did: gallery.creator!.did,
                                          showAppBar: true,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  gallery.creator?.displayName ?? '',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if ((gallery.creator?.displayName ?? '').isNotEmpty &&
                                    (gallery.creator?.handle ?? '').isNotEmpty)
                                  const SizedBox(width: 8),
                                Text(
                                  '@${gallery.creator?.handle ?? ''}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (gallery.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 8),
                  child: FacetedText(
                    text: gallery.description,
                    facets: gallery.facets,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                    linkStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    onMentionTap: (did) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(did: did, showAppBar: true),
                        ),
                      );
                    },
                    onLinkTap: (url) {
                      // TODO: Implement or use your WebViewPage
                    },
                    onTagTap: (tag) {
                      // TODO: Implement hashtag navigation
                    },
                  ),
                ),
              if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GalleryActionButtons(
                    gallery: gallery,
                    parentContext: context,
                    currentUserDid: widget.currentUserDid,
                    isLoggedIn: isLoggedIn,
                  ),
                ),
              const SizedBox(height: 8),
              // Gallery items grid (edge-to-edge)
              if (galleryItems.isNotEmpty)
                JustifiedGalleryView(
                  items: galleryItems,
                  onImageTap: (index) {
                    if (index >= 0 && index < galleryItems.length) {
                      setState(() {
                        _selectedPhoto = galleryItems[index];
                        _selectedPhotoIndex = index;
                      });
                    }
                  },
                ),
              if (galleryItems.isEmpty)
                Center(
                  child: Text('No photos in this gallery.', style: theme.textTheme.bodyMedium),
                ),
            ],
          ),
        ),
        if (_selectedPhoto != null && _selectedPhotoIndex != null)
          Positioned.fill(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPhoto = null;
                      _selectedPhotoIndex = null;
                    });
                  },
                  child: Container(color: Colors.black.withOpacity(0.85)),
                ),
                Center(
                  child: GalleryPhotoView(
                    photos: galleryItems,
                    initialIndex: _selectedPhotoIndex!,
                    onClose: () {
                      setState(() {
                        _selectedPhoto = null;
                        _selectedPhotoIndex = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
