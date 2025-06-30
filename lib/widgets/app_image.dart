import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
    }
    final image = CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, _) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            // child: const Center(
            //   child: CircularProgressIndicator(
            //     strokeWidth: 2,
            //     color: Color(0xFF0EA5E9),
            //   ),
            // ),
          ),
      errorWidget: (context, _, __) =>
          errorWidget ??
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
    );
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius:
            borderRadius!, // BorderRadius is a subclass of BorderRadiusGeometry
        child: image,
      );
    }
    return image;
  }
}
