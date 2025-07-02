import 'gallery.dart';

class Comment {
  final String uri;
  final String cid;
  final Map<String, dynamic> author;
  final String text;
  final String? replyTo;
  final String? createdAt;
  final GalleryPhoto? focus;
  final List<Map<String, dynamic>>? facets;

  Comment({
    required this.uri,
    required this.cid,
    required this.author,
    required this.text,
    this.replyTo,
    this.createdAt,
    this.focus,
    this.facets,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final record = json['record'] as Map<String, dynamic>? ?? {};
    return Comment(
      uri: json['uri'] ?? '',
      cid: json['cid'] ?? '',
      author: json['author'] ?? {},
      text: json['text'] ?? record['text'] ?? '',
      replyTo: json['replyTo'] ?? record['replyTo'],
      createdAt: json['createdAt'] ?? record['createdAt'],
      focus: json['focus'] != null ? GalleryPhoto.fromJson(json['focus']) : null,
      facets:
          (json['facets'] as List?)?.map((f) => Map<String, dynamic>.from(f)).toList() ??
          (record['facets'] as List?)?.map((f) => Map<String, dynamic>.from(f)).toList(),
    );
  }
}
