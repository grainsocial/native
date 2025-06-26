import 'package:flutter/material.dart';
import 'package:grain/gallery.dart';
import 'package:grain/api.dart';
import 'package:grain/justified_gallery_view.dart';
import 'package:grain/comments_page.dart';
import 'utils.dart';

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error || _gallery == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load gallery.')),
      );
    }
    final gallery = _gallery!;
    final isCreator = widget.currentUserDid == gallery.creator?.did;
    final isLoggedIn = widget.currentUserDid != null;
    final galleryItems = gallery.items
        .where((item) => item.thumb.isNotEmpty)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(gallery.title.isNotEmpty ? gallery.title : 'Gallery'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            // Gallery info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage:
                      gallery.creator?.avatar != null &&
                          gallery.creator!.avatar.isNotEmpty
                      ? NetworkImage(gallery.creator!.avatar)
                      : null,
                  child:
                      (gallery.creator == null ||
                          gallery.creator!.avatar.isEmpty)
                      ? const Icon(
                          Icons.account_circle,
                          size: 32,
                          color: Colors.grey,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gallery.creator?.displayName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        '@${gallery.creator?.handle ?? ''}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      if ((gallery.createdAt ?? '').isNotEmpty)
                        Text(
                          formatRelativeTime(gallery.createdAt ?? ''),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (gallery.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  gallery.description,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            // Action buttons
            if (isLoggedIn)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isCreator)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  IconButton(
                    icon: Icon(
                      gallery.viewer != null && gallery.viewer!['fav'] != null
                          ? Icons
                                .favorite // filled
                          : Icons.favorite_border, // outline
                      color:
                          gallery.viewer != null &&
                              gallery.viewer!['fav'] != null
                          ? Color(0xFFEC4899) // Tailwind pink-500
                          : Colors.black54,
                    ),
                    onPressed: () {},
                  ),
                  if (gallery.favCount != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        gallery.favCount.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              CommentsPage(galleryUri: gallery.uri),
                        ),
                      );
                    },
                  ),
                  if (gallery.commentCount != null)
                    Text(
                      gallery.commentCount.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  IconButton(icon: const Icon(Icons.share), onPressed: () {}),
                ],
              ),
            const SizedBox(height: 8),
            // Gallery items grid
            if (galleryItems.isNotEmpty)
              JustifiedGalleryView(items: galleryItems),
            if (galleryItems.isEmpty)
              const Center(child: Text('No photos in this gallery.')),
          ],
        ),
      ),
    );
  }
}
