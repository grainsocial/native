import 'dart:io';

import 'package:image/image.dart' as img;

enum ResizeMode { cover, contain, stretch }

class ResizeResult {
  final File file;
  final int width;
  final int height;
  final int size;
  final String mime;
  ResizeResult({
    required this.file,
    required this.width,
    required this.height,
    required this.size,
    this.mime = 'image/jpeg',
  });
}

Future<ResizeResult> resizeImage({
  required File file,
  int targetWidth = 2000,
  int targetHeight = 2000,
  int maxBytes = 1000000,
  ResizeMode mode = ResizeMode.cover,
}) async {
  final bytes = await file.readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) throw Exception('Could not decode image');

  // Calculate scale
  double scale;
  if (mode == ResizeMode.cover) {
    scale = [
      targetWidth / image.width,
      targetHeight / image.height,
    ].reduce((a, b) => a > b ? a : b);
  } else if (mode == ResizeMode.contain) {
    scale = [
      targetWidth / image.width,
      targetHeight / image.height,
    ].reduce((a, b) => a < b ? a : b);
  } else {
    scale = 1.0;
  }

  int newWidth = (image.width * scale).round();
  int newHeight = (image.height * scale).round();

  if (mode == ResizeMode.stretch) {
    newWidth = targetWidth;
    newHeight = targetHeight;
  }

  img.Image resized = img.copyResize(image, width: newWidth, height: newHeight);

  // Binary search for best quality under maxBytes
  int minQ = 0, maxQ = 101;
  List<int> bestJpg = [];
  while (maxQ - minQ > 1) {
    int q = ((minQ + maxQ) / 2).round();
    final jpg = img.encodeJpg(resized, quality: q);
    if (jpg.length < maxBytes) {
      minQ = q;
      bestJpg = jpg;
    } else {
      maxQ = q;
    }
  }
  if (bestJpg.isEmpty) {
    // fallback: lowest quality
    bestJpg = img.encodeJpg(resized, quality: minQ);
  }

  final outFile = File(file.path.replaceFirst(RegExp(r'\.(jpg|jpeg|png) ?'), '_resized.jpg'));
  await outFile.writeAsBytes(bestJpg);

  return ResizeResult(
    file: outFile,
    width: resized.width,
    height: resized.height,
    size: bestJpg.length,
    mime: 'image/jpeg',
  );
}
