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
    final theme = Theme.of(context);
    final Color bgColor = theme.brightness == Brightness.dark
        ? Colors.grey[900]!
        : Colors.grey[100]!;
    if (url == null || url!.isEmpty) {
      return errorWidget ??
          Container(
            width: width,
            height: height,
            color: bgColor,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
    }
    final image = CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, _) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: bgColor,
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
            color: bgColor,
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
