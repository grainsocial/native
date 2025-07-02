import 'package:flutter/material.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/widgets/app_image.dart';

class GalleryPhotoView extends StatefulWidget {
  final List<GalleryPhoto> photos;
  final int initialIndex;
  final VoidCallback? onClose;
  const GalleryPhotoView({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.onClose,
  });

  @override
  State<GalleryPhotoView> createState() => _GalleryPhotoViewState();
}

class _GalleryPhotoViewState extends State<GalleryPhotoView> {
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
          icon: const Icon(Icons.close),
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
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              if (photo.alt.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    photo.alt,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
