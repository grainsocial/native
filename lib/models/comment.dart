import 'package:freezed_annotation/freezed_annotation.dart';

import 'gallery_photo.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
class Comment with _$Comment {
  const factory Comment({
    required String uri,
    required String cid,
    required Map<String, dynamic> author,
    required String text,
    String? replyTo,
    String? createdAt,
    GalleryPhoto? focus,
    List<Map<String, dynamic>>? facets,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}
