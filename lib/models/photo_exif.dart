import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_exif.freezed.dart';
part 'photo_exif.g.dart';

@freezed
class PhotoExif with _$PhotoExif {
  const factory PhotoExif({
    required String photo, // at-uri
    required String createdAt, // datetime
    String? dateTimeOriginal, // datetime
    int? exposureTime,
    int? fNumber,
    String? flash,
    int? focalLengthIn35mmFormat,
    int? iSO,
    String? lensMake,
    String? lensModel,
    String? make,
    String? model,
  }) = _PhotoExif;

  factory PhotoExif.fromJson(Map<String, dynamic> json) => _$PhotoExifFromJson(json);
}
