import 'package:flutter/material.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/api.dart';
import 'package:grain/widgets/justified_gallery_view.dart';
import './comments_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:grain/widgets/gallery_photo_view.dart';
import 'package:at_uri/at_uri.dart';
import 'package:share_plus/share_plus.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grain/screens/create_gallery_page.dart';

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
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF0EA5E9),
          ),
        ),
      );
    }
    if (_error || _gallery == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load gallery.')),
      );
    }
    final gallery = _gallery!;
    final isLoggedIn = widget.currentUserDid != null;
    final galleryItems = gallery.items
        .where((item) => item.thumb.isNotEmpty)
        .toList();

    // The Stack is now OUTSIDE the Scaffold!
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: Theme.of(context).dividerColor,
                height: 1,
              ),
            ),
            title: const Text(
              'Gallery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            iconTheme: const IconThemeData(color: Colors.black87),
            titleTextStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            actions: [
              if (gallery.creator?.did == widget.currentUserDid)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Gallery',
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => CreateGalleryPage(
                        // Optionally pass initial data for editing
                        gallery: gallery,
                      ),
                    );
                    // Optionally refresh after editing
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
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage:
                              gallery.creator?.avatar != null &&
                                  gallery.creator!.avatar.isNotEmpty
                              ? null
                              : null,
                          child:
                              (gallery.creator == null ||
                                  gallery.creator!.avatar.isEmpty)
                              ? const Icon(
                                  Icons.account_circle,
                                  size: 24,
                                  color: Colors.grey,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                gallery.creator?.displayName ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              if ((gallery.creator?.displayName ?? '')
                                      .isNotEmpty &&
                                  (gallery.creator?.handle ?? '').isNotEmpty)
                                const SizedBox(width: 8),
                              Text(
                                '@${gallery.creator?.handle ?? ''}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ).copyWith(bottom: 8),
                  child: Text(
                    gallery.description,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ),
              if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // Favorite button
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  gallery.viewer != null &&
                                          gallery.viewer!['fav'] != null
                                      ? FontAwesomeIcons.solidHeart
                                      : FontAwesomeIcons.heart,
                                  color:
                                      gallery.viewer != null &&
                                          gallery.viewer!['fav'] != null
                                      ? const Color(0xFFEC4899)
                                      : Colors.black54,
                                  size: 20,
                                ),
                                if (gallery.favCount != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    gallery.favCount.toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Comment button
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CommentsPage(galleryUri: gallery.uri),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.comment,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                if (gallery.commentCount != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    gallery.commentCount.toString(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Share button
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Parse the gallery URI to get handle and rkey
                            final atUri = AtUri.parse(gallery.uri);
                            final handle = gallery.creator?.handle ?? '';
                            final galleryRkey = atUri.rkey;
                            final url =
                                'https://grain.social/profile/$handle/gallery/$galleryRkey';
                            final shareText =
                                "Check out this gallery on @grain.social \n$url";
                            SharePlus.instance.share(
                              ShareParams(text: shareText),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.arrowUpFromBracket,
                                color: Colors.black54,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                const Center(child: Text('No photos in this gallery.')),
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
