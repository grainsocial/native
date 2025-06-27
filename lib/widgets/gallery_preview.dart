import 'package:flutter/material.dart';
import 'package:grain/models/gallery.dart';

class GalleryPreview extends StatelessWidget {
  final Gallery gallery;

  const GalleryPreview({super.key, required this.gallery});

  @override
  Widget build(BuildContext context) {
    final photos = gallery.items
        .where((item) => item.thumb.isNotEmpty)
        .toList();
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: photos.isNotEmpty
                ? Image.network(
                    photos[0].thumb,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Container(color: Colors.grey[300]),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: photos.length > 1
                      ? Image.network(
                          photos[1].thumb,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(color: Colors.grey[200]),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: photos.length > 2
                      ? Image.network(
                          photos[2].thumb,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(color: Colors.grey[200]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
