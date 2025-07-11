import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain/api.dart';
import 'package:grain/models/gallery.dart';
import 'package:grain/providers/profile_provider.dart';
import 'package:grain/widgets/app_button.dart';
import 'package:grain/widgets/plain_text_field.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/gallery_cache_provider.dart';
import 'gallery_page.dart';

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
      _titleController.text = widget.gallery?.title ?? '';
      _descController.text = widget.gallery?.description ?? '';
    }
  }

  Future<String> _computeMd5(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    return md5.convert(bytes).toString();
  }

  Future<void> _pickImages() async {
    if (widget.gallery != null) return; // Only allow picking on create
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      // Use md5 hash for duplicate detection
      final existingHashes = <String>{};
      for (final img in _images) {
        final hash = await _computeMd5(img.file);
        existingHashes.add(hash);
      }
      final newImages = <GalleryImage>[];
      int skipped = 0;
      for (final xfile in picked) {
        final hash = await _computeMd5(xfile);
        if (!existingHashes.contains(hash)) {
          newImages.add(GalleryImage(file: xfile, isExisting: false));
          existingHashes.add(hash);
        } else {
          skipped++;
        }
      }
      if (newImages.isNotEmpty) {
        setState(() {
          _images.addAll(newImages);
        });
      }
      if (skipped > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Some images were skipped (duplicates).'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (widget.gallery == null && _images.length > 10) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Photo Limit'),
            content: const Text(
              'You can only add up to 10 photos on initial create but can add more later on.',
            ),
            actions: [
              TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    String? galleryUri;
    if (widget.gallery == null) {
      // Use provider to create gallery and add photos
      final newImages = _images.where((img) => !img.isExisting).toList();
      final container = ProviderScope.containerOf(context, listen: false);
      final galleryCache = container.read(galleryCacheProvider.notifier);
      final (createdUri, newPhotoUris) = await galleryCache.createGalleryAndAddPhotos(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        xfiles: newImages.map((img) => img.file).toList(),
      );
      galleryUri = createdUri;
      // Update profile provider state to include new gallery
      if (galleryUri != null && mounted) {
        final newGallery = container.read(galleryCacheProvider)[galleryUri];
        final profileNotifier = container.read(
          profileNotifierProvider(apiService.currentUser!.did).notifier,
        );
        if (newGallery != null) {
          profileNotifier.addGalleryToProfile(newGallery);
        }
      }
    } else {
      // Only support editing title/description for existing galleries
      galleryUri = widget.gallery!.uri;
      // If you have a provider method for updating, use it. Otherwise, call the correct API method.
      // await apiService.updateGallery(
      //   uri: galleryUri,
      //   title: _titleController.text.trim(),
      //   description: _descController.text.trim(),
      // );
    }
    setState(() => _submitting = false);
    if (mounted && galleryUri != null) {
      Navigator.of(context).pop();
      if (widget.gallery == null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                GalleryPage(uri: galleryUri!, currentUserDid: apiService.currentUser?.did),
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

    return CupertinoPageScaffold(
      backgroundColor: theme.colorScheme.surface,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
        middle: Text(
          widget.gallery == null ? 'New Gallery' : 'Edit Gallery',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _submitting ? null : _submit,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.gallery == null ? 'Create' : 'Save',
                style: TextStyle(
                  color: _submitting ? theme.disabledColor : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_submitting) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    semanticsLabel: widget.gallery == null ? 'Creating' : 'Saving',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      child: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                maxLines: 6,
                hintText: 'Enter a description',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  AppButton(
                    label: 'Upload photos',
                    onPressed: _pickImages,
                    icon: Icons.photo_library,
                    variant: AppButtonVariant.primary,
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(galleryImage.file.path), fit: BoxFit.cover),
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
                                color: theme.colorScheme.secondary.withOpacity(0.7),
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
                                color: Colors.grey.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
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
    );
  }
}

Future<void> showCreateGallerySheet(BuildContext context, {Gallery? gallery}) async {
  final theme = Theme.of(context);
  await showCupertinoSheet(
    context: context,
    useNestedNavigation: false,
    pageBuilder: (context) => Material(
      type: MaterialType.transparency,
      child: CreateGalleryPage(gallery: gallery),
    ),
  );
  // Restore status bar style or any other cleanup
  SystemChrome.setSystemUIOverlayStyle(
    theme.brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
  );
}
