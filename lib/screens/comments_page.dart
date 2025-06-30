import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/comment.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/utils.dart';
import 'package:grain/widgets/gallery_photo_view.dart';

class CommentsPage extends StatefulWidget {
  final String galleryUri;
  const CommentsPage({super.key, required this.galleryUri});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  bool _loading = true;
  bool _error = false;
  Gallery? _gallery;
  List<Comment> _comments = [];
  GalleryPhoto? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _fetchThread();
  }

  Future<void> _fetchThread() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final data = await apiService.getGalleryThread(uri: widget.galleryUri);
      setState(() {
        _gallery = Gallery.fromJson(data['gallery']);
        _comments = (data['comments'] as List<dynamic>? ?? [])
            .map((c) => Comment.fromJson(c as Map<String, dynamic>))
            .toList();
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
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          body: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
                ) // Tailwind sky-500)
              : _error
              ? const Center(child: Text('Failed to load comments.'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (_gallery != null)
                      Text(
                        _gallery!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    const SizedBox(height: 12),
                    _CommentsList(
                      comments: _comments,
                      onPhotoTap: (photo) {
                        setState(() {
                          _selectedPhoto = photo;
                        });
                      },
                    ),
                  ],
                ),
        ),
        if (_selectedPhoto != null)
          Positioned.fill(
            child: GalleryPhotoView(
              photos: [_selectedPhoto!],
              initialIndex: 0,
              onClose: () => setState(() => _selectedPhoto = null),
            ),
          ),
      ],
    );
  }
}

class _CommentsList extends StatelessWidget {
  final List<Comment> comments;
  final void Function(GalleryPhoto photo) onPhotoTap;
  const _CommentsList({required this.comments, required this.onPhotoTap});

  Map<String, List<Comment>> _groupReplies(List<Comment> comments) {
    final repliesByParent = <String, List<Comment>>{};
    for (final comment in comments) {
      if (comment.replyTo != null) {
        repliesByParent.putIfAbsent(comment.replyTo!, () => []).add(comment);
      }
    }
    return repliesByParent;
  }

  List<Comment> _topLevel(List<Comment> comments) {
    return comments.where((c) => c.replyTo == null).toList();
  }

  Widget _buildCommentTree(
    Comment comment,
    Map<String, List<Comment>> repliesByParent,
    int depth,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentTile(comment: comment, onPhotoTap: onPhotoTap),
          if (repliesByParent[comment.uri] != null)
            ...repliesByParent[comment.uri]!.map(
              (reply) => _buildCommentTree(reply, repliesByParent, depth + 1),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repliesByParent = _groupReplies(comments);
    final topLevel = _topLevel(comments);
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('No comments yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final comment in topLevel)
          _buildCommentTree(comment, repliesByParent, 0),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final void Function(GalleryPhoto photo)? onPhotoTap;
  const _CommentTile({required this.comment, this.onPhotoTap});

  @override
  Widget build(BuildContext context) {
    final author = comment.author;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (author['avatar'] != null)
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(author['avatar']),
            )
          else
            const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author['displayName'] ?? '@${author['handle'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(comment.text, style: const TextStyle(fontSize: 15)),
                if (comment.focus != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 180, // Limit max width
                        maxHeight: 180, // Limit max height
                      ),
                      child: AspectRatio(
                        aspectRatio:
                            (comment.focus!.width > 0 &&
                                comment.focus!.height > 0)
                            ? comment.focus!.width / comment.focus!.height
                            : 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GestureDetector(
                            onTap: onPhotoTap != null
                                ? () => onPhotoTap!(
                                    GalleryPhoto(
                                      uri: comment.focus!.uri,
                                      cid: comment.focus!.cid,
                                      thumb: comment.focus!.thumb,
                                      fullsize: comment.focus!.fullsize,
                                      alt: comment.focus!.alt,
                                      width: comment.focus!.width,
                                      height: comment.focus!.height,
                                    ),
                                  )
                                : null,
                            child: Image.network(
                              comment.focus!.thumb.isNotEmpty
                                  ? comment.focus!.thumb
                                  : comment.focus!.fullsize,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (comment.createdAt != null)
                  Text(
                    formatRelativeTime(comment.createdAt!),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
