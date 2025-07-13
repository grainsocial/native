import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain/app_icons.dart';
import 'package:grain/models/gallery_photo.dart';
import 'package:grain/providers/gallery_thread_cache_provider.dart';
import 'package:grain/widgets/add_comment_button.dart';
import 'package:grain/widgets/add_comment_sheet.dart';
import 'package:grain/widgets/app_image.dart';
import 'package:grain/widgets/photo_exif_dialog.dart';

class GalleryPhotoView extends ConsumerStatefulWidget {
  final List<GalleryPhoto> photos;
  final int initialIndex;
  final VoidCallback? onClose;
  final void Function(String galleryUri)? onCommentPosted;
  final dynamic gallery;
  final bool showAddCommentButton;
  const GalleryPhotoView({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.onClose,
    this.onCommentPosted,
    this.gallery,
    this.showAddCommentButton = true,
  });

  @override
  ConsumerState<GalleryPhotoView> createState() => _GalleryPhotoViewState();
}

class _GalleryPhotoViewState extends ConsumerState<GalleryPhotoView> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(AppIcons.close),
          onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onClose ?? () => Navigator.of(context).maybePop(),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.photos.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, i) => Center(
                    child: AppImage(
                      url: widget.photos[i].fullsize,
                      fit: BoxFit.contain,
                      placeholder: Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                      errorWidget: Container(
                        color: Colors.black,
                        child: Icon(AppIcons.brokenImage, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              if (photo.alt != null && photo.alt?.isNotEmpty == true)
                Container(
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    photo.alt!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (widget.showAddCommentButton)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: AddCommentButton(
                            onPressed: () async {
                              final photo = widget.photos[_currentIndex];
                              final creator = widget.gallery?.creator;
                              final replyTo = {
                                'author': creator != null
                                    ? {
                                        'avatar': creator.avatar,
                                        'displayName': creator.displayName,
                                        'handle': creator.handle,
                                      }
                                    : {'avatar': null, 'displayName': '', 'handle': ''},
                                'focus': photo,
                                'text': '',
                              };
                              bool commentPosted = false;
                              await showAddCommentSheet(
                                context,
                                gallery: null,
                                replyTo: replyTo,
                                initialText: '',
                                onSubmit: (text) async {
                                  final photo = widget.photos[_currentIndex];
                                  final gallery = widget.gallery;
                                  final subject = gallery?.uri;
                                  final focus = photo.uri;
                                  if (subject == null || focus == null) {
                                    return;
                                  }
                                  // Use the provider's createComment method
                                  final notifier = ref.read(
                                    galleryThreadProvider(subject).notifier,
                                  );
                                  final success = await notifier.createComment(
                                    text: text,
                                    focus: focus,
                                  );
                                  if (success) commentPosted = true;
                                  // Sheet will pop itself
                                },
                              );
                              // After sheet closes, notify parent if a comment was posted
                              if (commentPosted && widget.gallery?.uri != null) {
                                widget.onClose?.call(); // Remove GalleryPhotoView overlay
                                widget.onCommentPosted?.call(widget.gallery!.uri);
                              }
                            },
                            backgroundColor: Colors.grey[900],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (photo.exif != null)
                          IconButton(
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => PhotoExifDialog(exif: photo.exif!),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
