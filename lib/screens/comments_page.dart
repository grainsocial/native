import 'package:bluesky_text/bluesky_text.dart';
import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:grain/models/comment.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/models/gallery_photo.dart';
import 'package:grain/screens/profile_page.dart';
import 'package:grain/utils.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/widgets/faceted_text.dart';
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
  bool _showInputBar = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();
  String? _replyTo;

  @override
  void initState() {
    super.initState();
    _fetchThread();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchThread() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final thread = await apiService.getGalleryThread(uri: widget.galleryUri);
      setState(() {
        _gallery = thread?.gallery;
        _comments = thread?.comments ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _showReplyBar({String? replyTo, String? mention}) {
    setState(() {
      _showInputBar = true;
      _replyTo = replyTo;
    });
    if (mention != null && mention.isNotEmpty) {
      _replyController.text = mention;
      _replyController.selection = TextSelection.fromPosition(
        TextPosition(offset: _replyController.text.length),
      );
    } else {
      _replyController.clear();
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) FocusScope.of(context).requestFocus(_replyFocusNode);
    });
  }

  void _hideReplyBar() {
    setState(() {
      _showInputBar = false;
      _replyController.clear();
      _replyTo = null;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> handleDeleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(const SnackBar(content: Text('Deleting comment...')));
    final deleted = await apiService.deleteRecord(comment.uri);
    if (!deleted) {
      scaffold.removeCurrentSnackBar();
      scaffold.showSnackBar(const SnackBar(content: Text('Failed to delete comment.')));
      return;
    }
    final expectedCount = _comments.length - 1;
    final thread = await apiService.pollGalleryThreadComments(
      galleryUri: widget.galleryUri,
      expectedCount: expectedCount,
    );
    if (thread != null) {
      setState(() {
        _gallery = thread.gallery;
        _comments = thread.comments;
      });
    } else {
      await _fetchThread();
    }
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(const SnackBar(content: Text('Comment deleted.')));
  }

  // Extract facets using the async BlueskyText/entities/toFacets pattern
  Future<List<Map<String, dynamic>>> _extractFacets(String text) async {
    final blueskyText = BlueskyText(text);
    final entities = blueskyText.entities;
    final facets = await entities.toFacets();
    return List<Map<String, dynamic>>.from(facets);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            title: Text('Comments', style: theme.appBarTheme.titleTextStyle),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_showInputBar) _hideReplyBar();
            },
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _error
                ? Center(child: Text('Failed to load comments.', style: theme.textTheme.bodyMedium))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    children: [
                      if (_gallery != null)
                        Text(_gallery!.title ?? '', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _CommentsList(
                        comments: _comments,
                        onPhotoTap: (photo) {
                          setState(() {
                            _selectedPhoto = photo;
                          });
                        },
                        onReply: (replyTo, {mention}) =>
                            _showReplyBar(replyTo: replyTo, mention: mention),
                        onDelete: handleDeleteComment,
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: _showInputBar
              ? AnimatedPadding(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Builder(
                    builder: (context) {
                      final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                      return Padding(
                        padding: EdgeInsets.only(bottom: keyboardOpen ? 0 : 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Divider(height: 1, thickness: 1, color: theme.dividerColor),
                            Container(
                              color: theme.colorScheme.surfaceContainer,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest
                                            .withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 40,
                                          maxHeight: 120,
                                        ),
                                        child: Scrollbar(
                                          child: TextField(
                                            controller: _replyController,
                                            focusNode: _replyFocusNode,
                                            autofocus: true,
                                            minLines: 1,
                                            maxLines: 5,
                                            textInputAction: TextInputAction.newline,
                                            decoration: const InputDecoration(
                                              hintText: 'Write a reply...',
                                              border: InputBorder.none,
                                              isCollapsed: true,
                                            ),
                                            style: theme.textTheme.bodyLarge,
                                            onSubmitted: (value) async {
                                              if (value.trim().isEmpty) return;
                                              final text = value.trim();
                                              final facets = await _extractFacets(text);
                                              final uri = await apiService.createComment(
                                                text: text,
                                                subject: widget.galleryUri,
                                                replyTo: _replyTo,
                                                facets: facets,
                                              );
                                              if (uri != null) {
                                                final thread = await apiService
                                                    .pollGalleryThreadComments(
                                                      galleryUri: widget.galleryUri,
                                                      expectedCount: _comments.length + 1,
                                                    );
                                                if (thread != null) {
                                                  setState(() {
                                                    _gallery = thread.gallery;
                                                    _comments = thread.comments;
                                                  });
                                                } else {
                                                  await _fetchThread();
                                                }
                                              }
                                              _hideReplyBar();
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    margin: const EdgeInsets.only(right: 10, bottom: 8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.send, color: theme.colorScheme.onPrimary),
                                      onPressed: () async {
                                        final value = _replyController.text.trim();
                                        if (value.isEmpty) return;
                                        final facets = await _extractFacets(value);
                                        final uri = await apiService.createComment(
                                          text: value,
                                          subject: widget.galleryUri,
                                          replyTo: _replyTo,
                                          facets: facets,
                                        );
                                        if (uri != null) {
                                          final thread = await apiService.pollGalleryThreadComments(
                                            galleryUri: widget.galleryUri,
                                            expectedCount: _comments.length + 1,
                                          );
                                          if (thread != null) {
                                            setState(() {
                                              _gallery = thread.gallery;
                                              _comments = thread.comments;
                                            });
                                          } else {
                                            await _fetchThread();
                                          }
                                        }
                                        _hideReplyBar();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  color: theme.colorScheme.surface,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: _showReplyBar,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.reply, color: theme.iconTheme.color, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add a reply...',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          // Show photo view overlay if needed
          extendBody: true,
          extendBodyBehindAppBar: false,
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
  final void Function(String replyTo, {String? mention}) onReply;
  final void Function(Comment comment) onDelete;
  const _CommentsList({
    required this.comments,
    required this.onPhotoTap,
    required this.onReply,
    required this.onDelete,
  });

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

  /// Returns the top-level parent for a comment (itself if already top-level)
  Comment _findTopLevelParent(Comment comment, Map<String, Comment> byUri) {
    var current = comment;
    while (current.replyTo != null && byUri[current.replyTo!] != null) {
      final parent = byUri[current.replyTo!];
      if (parent == null) break;
      if (parent.replyTo == null) return parent;
      current = parent;
    }
    return current.replyTo == null ? current : byUri[current.replyTo!] ?? current;
  }

  Widget _buildCommentTree(
    Comment comment,
    Map<String, List<Comment>> repliesByParent,
    int depth,
    Map<String, Comment> byUri,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentTile(
            comment: comment,
            onPhotoTap: onPhotoTap,
            onReply: (replyTo, {mention}) {
              // Only two levels: replyTo should always be the top-level parent
              final parent = _findTopLevelParent(comment, byUri);
              onReply(parent.uri, mention: mention);
            },
            onDelete: onDelete,
          ),
          if (repliesByParent[comment.uri] != null)
            ...repliesByParent[comment.uri]!.map(
              (reply) => _buildCommentTree(reply, repliesByParent, depth + 1, byUri),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repliesByParent = _groupReplies(comments);
    final topLevel = _topLevel(comments);
    final byUri = {for (final c in comments) c.uri: c};
    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No comments yet',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final comment in topLevel) _buildCommentTree(comment, repliesByParent, 0, byUri),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final void Function(GalleryPhoto photo)? onPhotoTap;
  final void Function(String replyTo, {String? mention})? onReply;
  final void Function(Comment comment)? onDelete;
  const _CommentTile({required this.comment, this.onPhotoTap, this.onReply, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = comment.author;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (author['avatar'] != null)
            ClipOval(
              child: AppImage(url: author['avatar'], width: 32, height: 32, fit: BoxFit.cover),
            )
          else
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.person, size: 16, color: theme.iconTheme.color),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author['displayName'] ?? '@${author['handle'] ?? ''}',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                FacetedText(
                  text: comment.text,
                  facets: comment.facets,
                  style: theme.textTheme.bodyMedium,
                  linkStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  onMentionTap: (did) {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (context) => ProfilePage(did: did)));
                  },
                  onLinkTap: (url) {
                    // Navigator.of(
                    //   context,
                    // ).push(MaterialPageRoute(builder: (context) => WebViewPage(url: url)));
                  },
                  onTagTap: (tag) {
                    // TODO: Implement hashtag navigation
                  },
                ),
                if (comment.focus != null &&
                    ((comment.focus!.thumb?.isNotEmpty ?? false) ||
                        (comment.focus!.fullsize?.isNotEmpty ?? false)))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180, maxHeight: 180),
                        child: AspectRatio(
                          aspectRatio:
                              (comment.focus!.aspectRatio != null &&
                                  (comment.focus!.aspectRatio!.width > 0 &&
                                      comment.focus!.aspectRatio!.height > 0))
                              ? comment.focus!.aspectRatio!.width /
                                    comment.focus!.aspectRatio!.height
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
                                        aspectRatio: comment.focus!.aspectRatio,
                                      ),
                                    )
                                  : null,
                              child: AppImage(
                                url: (comment.focus!.thumb?.isNotEmpty ?? false)
                                    ? comment.focus!.thumb
                                    : comment.focus!.fullsize,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (comment.createdAt != null)
                  Text(
                    formatRelativeTime(comment.createdAt!),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                const SizedBox(height: 4), // Add vertical spacing above the buttons
                Row(
                  children: [
                    if (comment.replyTo == null)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          final handle = comment.author['handle'] ?? '';
                          final mention = handle.isNotEmpty ? '@$handle ' : '';
                          if (onReply != null) onReply!(comment.uri, mention: mention);
                        },
                        child: Text(
                          'Reply',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    if (comment.author['did'] == (apiService.currentUser?.did ?? '')) ...[
                      const SizedBox(width: 16),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          if (onDelete != null) onDelete!(comment);
                        },
                        child: Text(
                          'Delete',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
