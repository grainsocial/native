import 'dart:io';
import 'package:flutter/material.dart';
import 'package:grain/api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grain/widgets/plain_text_field.dart';
import 'package:grain/widgets/app_button.dart';
import 'gallery_page.dart';

class CreateGalleryPage extends StatefulWidget {
  const CreateGalleryPage({super.key});

  @override
  State<CreateGalleryPage> createState() => _CreateGalleryPageState();
}

class _CreateGalleryPageState extends State<CreateGalleryPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<XFile> _images = [];
  bool _submitting = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final galleryUri = await apiService.createGallery(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
    );
    setState(() => _submitting = false);
    if (mounted && galleryUri != null) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GalleryPage(
            uri: galleryUri,
            currentUserDid: apiService.currentUser?.did,
          ),
        ),
      );
    } else if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight =
        MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
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
                    foregroundColor: const Color(
                      0xFF0EA5E9,
                    ), // Tailwind sky-500
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                Text(
                  'New Gallery',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                AppButton(
                  label: 'Create',
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
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Image.file(
                                  File(_images[index].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
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
    );
  }
}
