import 'package:flutter/material.dart';
import 'package:grain/models/gallery.dart';

class JustifiedGalleryView extends StatelessWidget {
  final List<GalleryPhoto> items;
  final double spacing;
  final double maxRowHeight;
  final void Function(int index)? onImageTap;

  const JustifiedGalleryView({
    super.key,
    required this.items,
    this.spacing = 4,
    this.maxRowHeight = 220,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No photos in this gallery.'));
    }
    final screenWidth =
        MediaQuery.of(context).size.width - 32; // 16px padding each side
    final rows = _computeRows(items, screenWidth, spacing, maxRowHeight);
    int globalIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) ...[
          Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < row.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      right: i == row.length - 1 ? 0 : spacing,
                    ),
                    child: GestureDetector(
                      onTap: onImageTap != null
                          ? () => onImageTap!(globalIndex + i)
                          : null,
                      child: SizedBox(
                        width: row[i].displayWidth,
                        height: row[i].displayHeight,
                        child: ClipRRect(
                          child: Image.network(
                            row[i].thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // increment globalIndex after each row (not as a widget)
        ],
      ],
    );
    // increment globalIndex after each row
    // (do this after the widget, not inside the widget list)
  }
}

class _JustifiedImage {
  final String thumb;
  final double displayWidth;
  final double displayHeight;
  _JustifiedImage({
    required this.thumb,
    required this.displayWidth,
    required this.displayHeight,
  });
}

List<List<_JustifiedImage>> _computeRows(
  List<GalleryPhoto> items,
  double maxWidth,
  double spacing,
  double maxRowHeight,
) {
  final rows = <List<_JustifiedImage>>[];
  var currentRow = <_JustifiedImage>[];
  double aspectSum = 0;
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final imgW = item.width.toDouble();
    final imgH = item.height.toDouble();
    final aspect = imgW / imgH;
    currentRow.add(
      _JustifiedImage(
        thumb: item.thumb,
        displayWidth: imgW.toDouble(),
        displayHeight: imgH.toDouble(),
      ),
    );
    aspectSum += aspect;
    // Estimate row height
    final rowSpacing = spacing * (currentRow.length - 1);
    final estRowHeight = (maxWidth - rowSpacing) / aspectSum;
    // If row is full enough or last image, finalize row
    if (estRowHeight < maxRowHeight || i == items.length - 1) {
      final rowHeight = estRowHeight.clamp(80.0, maxRowHeight);
      for (var j = 0; j < currentRow.length; j++) {
        final img = currentRow[j];
        final width = rowHeight * (img.displayWidth / img.displayHeight);
        currentRow[j] = _JustifiedImage(
          thumb: img.thumb,
          displayWidth: width,
          displayHeight: rowHeight.toDouble(),
        );
      }
      rows.add(List<_JustifiedImage>.from(currentRow));
      currentRow = <_JustifiedImage>[];
      aspectSum = 0;
    }
  }
  return rows;
}
