import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grain/widgets/plain_text_field.dart';
import 'package:grain/widgets/app_button.dart';
import 'gallery_page.dart';
import 'package:grain/photo_manip.dart';
import 'package:flutter/foundation.dart';
import 'package:grain/models/gallery.dart';
import 'package:path_provider/path_provider.dart';

// Wrapper class for differentiating images
class GalleryImage {
  final XFile file;
  final bool isExisting;
  final String? remoteUri;
  GalleryImage({required this.file, this.isExisting = false, this.remoteUri});
}

class CreateGalleryPage extends StatefulWidget {
  final Gallery? gallery;
  const CreateGalleryPage({super.key, this.gallery});

  @override
  State<CreateGalleryPage> createState() => _CreateGalleryPageState();
}

class _CreateGalleryPageState extends State<CreateGalleryPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<GalleryImage> _images = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.gallery != null) {
      _titleController.text = widget.gallery!.title;
      _descController.text = widget.gallery!.description;
      // Load existing images
      Future.microtask(() async {
        final List<GalleryImage> loadedImages = [];
        for (final item in widget.gallery!.items) {
          try {
            final response = await HttpClient().getUrl(Uri.parse(item.thumb));
            final file = await response.close().then((res) async {
              final bytes = await consolidateHttpClientResponseBytes(res);
              final tempDir = await getTemporaryDirectory();
              final tempFile = File('${tempDir.path}/${item.uri.hashCode}.jpg');
              await tempFile.writeAsBytes(bytes);
              return tempFile;
            });
            loadedImages.add(
              GalleryImage(
                file: XFile(file.path),
                isExisting: true,
                remoteUri: item.uri,
              ),
            );
          } catch (_) {}
        }
        if (mounted) {
          setState(() {
            _images.addAll(loadedImages);
          });
        }
      });
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(
          picked.map((xfile) => GalleryImage(file: xfile, isExisting: false)),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<Map<String, int>> _getImageDimensions(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final completer = Completer<Map<String, int>>();
    ui.decodeImageFromList(bytes, (image) {
      completer.complete({'width': image.width, 'height': image.height});
    });
    return completer.future;
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final List<String> photoUris = [];
    for (final galleryImage in _images) {
      if (galleryImage.isExisting && galleryImage.remoteUri != null) {
        photoUris.add(galleryImage.remoteUri!);
        continue;
      }
      // Only upload, create photo, and create gallery item if not existing
      if (!galleryImage.isExisting) {
        final file = File(galleryImage.file.path);
        final resizedResult = await compute<File, ResizeResult>(
          (f) => resizeImage(file: f),
          file,
        );
        final blobResult = await apiService.uploadBlob(resizedResult.file);
        if (blobResult != null) {
          final dims = await _getImageDimensions(galleryImage.file);
          final photoUri = await apiService.createPhoto(
            blob: blobResult,
            width: dims['width']!,
            height: dims['height']!,
          );
          if (photoUri != null) {
            photoUris.add(photoUri);
          }
        }
      }
    }
    String? galleryUri;
    if (widget.gallery != null && widget.gallery!.uri.isNotEmpty) {
      galleryUri = widget.gallery!.uri;
    } else {
      galleryUri = await apiService.createGallery(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
      );
    }
    // Link only new photos to gallery as gallery items
    if (galleryUri != null) {
      int position = 0;
      for (final galleryImage in _images) {
        if (!galleryImage.isExisting) {
          // Only create gallery item for new photos
          if (position < photoUris.length) {
            await apiService.createGalleryItem(
              galleryUri: galleryUri,
              photoUri: photoUris[position],
              position: position,
            );
            position++;
          }
        } else {
          position++;
        }
      }
      await apiService.pollGalleryItems(
        galleryUri: galleryUri,
        expectedCount: _images.length,
      );
    }
    setState(() => _submitting = false);
    if (mounted && galleryUri != null) {
      // Mark all images as existing after successful save
      for (var i = 0; i < _images.length; i++) {
        if (!_images[i].isExisting && i < photoUris.length) {
          _images[i] = GalleryImage(
            file: _images[i].file,
            isExisting: true,
            remoteUri: photoUris[i],
          );
        }
      }
      Navigator.of(context).pop();
      if (widget.gallery == null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GalleryPage(
              uri: galleryUri!,
              currentUserDid: apiService.currentUser?.did,
            ),
          ),
        );
      }
    } else if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double maxHeight =
        MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    child: Text('Cancel', style: theme.textTheme.bodyLarge),
                  ),
                  Text(
                    widget.gallery == null ? 'New Gallery' : 'Edit Gallery',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppButton(
                    label: widget.gallery == null ? 'Create' : 'Save',
                    onPressed: _submitting ? null : _submit,
                    loading: _submitting,
                    variant: AppButtonVariant.primary,
                    height: 36,
                    fontSize: 15,
                    borderRadius: 6,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlainTextField(
                        label: 'Title',
                        controller: _titleController,
                        hintText: 'Enter a title',
                      ),
                      const SizedBox(height: 16),
                      PlainTextField(
                        label: 'Description',
                        controller: _descController,
                        maxLines: 3,
                        hintText: 'Enter a description',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          AppButton(
                            label: 'Add Images',
                            onPressed: _pickImages,
                            icon: Icons.photo_library,
                            variant: AppButtonVariant.secondary,
                            height: 40,
                            fontSize: 15,
                            borderRadius: 6,
                          ),
                        ],
                      ),
                      if (_images.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            final galleryImage = _images[index];
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(galleryImage.file.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                if (galleryImage.isExisting)
                                  Positioned(
                                    left: 2,
                                    top: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: theme.colorScheme.onSecondary,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceTint
                                            .withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: theme.colorScheme.onSurface,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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
