import 'dart:io';

import 'package:flutter/material.dart';

import '../screens/create_gallery_page.dart';

class UploadProgressOverlay extends StatelessWidget {
  final List<GalleryImage> images;
  final int currentIndex;
  final double progress; // 0.0 - 1.0
  final bool visible;

  const UploadProgressOverlay({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.progress,
    this.visible = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final theme = Theme.of(context);

    // Get the current image being uploaded
    final currentImage = currentIndex < images.length ? images[currentIndex] : null;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.9))),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Uploading photos...',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Show current image at true aspect ratio
                  if (currentImage != null)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                      child: Image.file(
                        File(currentImage.file.path),
                        fit: BoxFit.contain, // Maintain aspect ratio
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Progress indicator
                  SizedBox(
                    width: 300,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Position counter and progress percentage
                  Text(
                    '${currentIndex + 1} of ${images.length} • ${(progress * 100).toInt()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
