class Gallery {
  final String uri;
  final String cid;
  final String title;
  final String description;
  final List<GalleryPhoto> items;

  Gallery({
    required this.uri,
    required this.cid,
    required this.title,
    required this.description,
    required this.items,
  });

  factory Gallery.fromJson(Map<String, dynamic> json) {
    return Gallery(
      uri: json['uri'] ?? '',
      cid: json['cid'] ?? '',
      title: json['record']?['title'] ?? '',
      description: json['record']?['description'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => GalleryPhoto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GalleryPhoto {
  final String uri;
  final String cid;
  final String thumb;
  final String fullsize;
  final String alt;
  final int width;
  final int height;

  GalleryPhoto({
    required this.uri,
    required this.cid,
    required this.thumb,
    required this.fullsize,
    required this.alt,
    required this.width,
    required this.height,
  });

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) {
    return GalleryPhoto(
      uri: json['uri'] ?? '',
      cid: json['cid'] ?? '',
      thumb: json['thumb'] ?? '',
      fullsize: json['fullsize'] ?? '',
      alt: json['alt'] ?? '',
      width: json['aspectRatio']?['width'] ?? 0,
      height: json['aspectRatio']?['height'] ?? 0,
    );
  }
}
