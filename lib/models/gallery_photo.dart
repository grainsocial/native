import 'package:freezed_annotation/freezed_annotation.dart';

import 'aspect_ratio.dart';

part 'gallery_photo.freezed.dart';
part 'gallery_photo.g.dart';

@freezed
class GalleryPhoto with _$GalleryPhoto {
  const factory GalleryPhoto({
    String? uri,
    String? cid,
    String? thumb,
    String? fullsize,
    String? alt,
    AspectRatio? aspectRatio,
  }) = _GalleryPhoto;

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) => _$GalleryPhotoFromJson(json);
}
