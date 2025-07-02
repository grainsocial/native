import 'gallery.dart';

class Comment {
  final String uri;
  final String cid;
  final Map<String, dynamic> author;
  final String text;
  final String? replyTo;
  final String? createdAt;
  final GalleryPhoto? focus;

  Comment({
    required this.uri,
    required this.cid,
    required this.author,
    required this.text,
    this.replyTo,
    this.createdAt,
    this.focus,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      uri: json['uri'] ?? '',
      cid: json['cid'] ?? '',
      author: json['author'] ?? {},
      text: json['text'] ?? '',
      replyTo: json['replyTo'],
      createdAt: json['createdAt'],
      focus: json['focus'] != null ? GalleryPhoto.fromJson(json['focus']) : null,
    );
  }
}
