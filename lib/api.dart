import 'package:grain/app_logger.dart';
import 'package:grain/main.dart';
import 'package:grain/models/atproto_session.dart';
import 'models/profile.dart';
import 'models/gallery.dart';
import 'models/notification.dart' as grain;
import './auth.dart';
import 'package:xrpc/xrpc.dart' as xrpc;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:grain/dpop_client.dart';
import 'dart:io';
import 'package:mime/mime.dart';

class ApiService {
  String? _accessToken;
  Profile? currentUser;
  Profile? loadedProfile;
  List<Gallery> galleries = [];

  String get _apiUrl => AppConfig.apiUrl;

  setToken(String? token) {
    _accessToken = token;
  }

  Future<AtprotoSession?> fetchSession() async {
    if (_accessToken == null) return null;

    final response = await http.get(
      Uri.parse('$_apiUrl/oauth/session'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch session');
    }

    return AtprotoSession.fromJson(jsonDecode(response.body));
  }

  Future<Profile?> fetchCurrentUser() async {
    final session = await auth.getValidSession();

    if (session == null || session.subject.isEmpty) {
      return null;
    }

    final user = await fetchProfile(did: session.subject);

    currentUser = user;

    return user;
  }

  Future<Profile?> fetchProfile({required String did}) async {
    appLogger.i('Fetching profile for did: $did');
    final response = await xrpc.query(
      service: _apiUrl.replaceFirst(RegExp(r'^https?://'), ''),
      xrpc.NSID.create('actor.grain.social', 'getProfile'),
      parameters: {'actor': did},
      to: Profile.fromJson,
    );
    return response.data;
  }

  Future<List<Gallery>> fetchActorGalleries({required String did}) async {
    appLogger.i('Fetching galleries for actor did: $did');
    final record = await xrpc.query(
      service: _apiUrl.replaceFirst(RegExp(r'^https?://'), ''),
      xrpc.NSID.create('gallery.grain.social', 'getActorGalleries'),
      parameters: {'actor': did},
      to: (json) =>
          (json['items'] as List<dynamic>?)
              ?.map((item) => Gallery.fromJson(item))
              .toList() ??
          [],
    );
    galleries = record.data;
    return galleries;
  }

  Future<List<Gallery>> getTimeline({String? algorithm}) async {
    if (_accessToken == null) {
      return [];
    }
    appLogger.i('Fetching timeline with algorithm: ${algorithm ?? 'default'}');
    final record = await xrpc.query(
      service: _apiUrl.replaceFirst(RegExp(r'^https?://'), ''),
      xrpc.NSID.create('feed.grain.social', 'getTimeline'),
      parameters: algorithm != null ? {'algorithm': algorithm} : null,
      headers: {'Authorization': "Bearer $_accessToken"},
      to: (json) =>
          (json['feed'] as List<dynamic>?)
              ?.map((item) => Gallery.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
    return record.data;
  }

  Future<Gallery?> getGallery({required String uri}) async {
    appLogger.i('Fetching gallery for uri: $uri');
    final record = await xrpc.query(
      service: _apiUrl.replaceFirst(RegExp(r'^https?://'), ''),
      xrpc.NSID.create('gallery.grain.social', 'getGallery'),
      parameters: {'uri': uri},
      to: Gallery.fromJson,
    );
    return record.data;
  }

  Future<Map<String, dynamic>> getGalleryThread({required String uri}) async {
    appLogger.i('Fetching gallery thread for uri: $uri');
    final record = await xrpc.query(
      service: _apiUrl.replaceFirst(RegExp(r'^https?://'), ''),
      xrpc.NSID.create('gallery.grain.social', 'getGalleryThread'),
      parameters: {'uri': uri},
      to: (json) => json as Map<String, dynamic>,
    );
    return record.data;
  }

  Future<List<grain.Notification>> getNotifications() async {
    if (_accessToken == null) {
      appLogger.w('No access token for getNotifications');
      return [];
    }
    appLogger.i('Fetching notifications');
    final record = await xrpc.query(
      service: _apiUrl.replaceFirst(RegExp(r'^https?://'), ''),
      xrpc.NSID.create('notification.grain.social', 'getNotifications'),
      headers: {'Authorization': "Bearer $_accessToken"},
      to: (json) =>
          (json['notifications'] as List<dynamic>?)
              ?.map(
                (item) =>
                    grain.Notification.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
    return record.data;
  }

  Future<List<Profile>> searchActors(String query) async {
    if (_accessToken == null) {
      appLogger.w('No access token for searchActors');
      return [];
    }
    appLogger.i('Searching actors with query: $query');
    final record = await xrpc.query(
      service: _apiUrl.replaceFirst(RegExp(r'^https?://'), ''),
      xrpc.NSID.create('actor.grain.social', 'searchActors'),
      parameters: {'q': query},
      to: (json) =>
          (json['actors'] as List<dynamic>?)
              ?.map((item) => Profile.fromJson(item))
              .toList() ??
          [],
    );
    return record.data;
  }

  Future<List<Gallery>> getActorFavs({required String did}) async {
    appLogger.i('Fetching actor favs for did: $did');
    final record = await xrpc.query(
      service: _apiUrl.replaceFirst(RegExp(r'^https?://'), ''),
      xrpc.NSID.create('actor.grain.social', 'getActorFavs'),
      parameters: {'actor': did},
      to: (json) =>
          (json['items'] as List<dynamic>?)
              ?.map((item) => Gallery.fromJson(item))
              .toList() ??
          [],
    );
    return record.data;
  }

  Future<String?> createGallery({
    required String title,
    required String description,
  }) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for createGallery');
      return null;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final did = session.subject;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.createRecord');
    final record = {
      'collection': 'social.grain.gallery',
      'repo': did,
      'record': {
        'title': title,
        'description': description,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    };
    appLogger.i('Creating gallery: $record');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w(
        'Failed to create gallery: \\${response.statusCode} \\${response.body}',
      );
      throw Exception('Failed to create gallery: \\${response.statusCode}');
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    appLogger.i('Created gallery result: $result');
    final uri = result['uri'] as String?;
    return uri;
  }

  /// Polls the gallery until the number of items matches [expectedCount] or timeout.
  /// Returns the Gallery if successful, or null if timeout.
  Future<Gallery?> pollGalleryItems({
    required String galleryUri,
    required int expectedCount,
    Duration pollDelay = const Duration(seconds: 2),
    int maxAttempts = 20,
  }) async {
    int attempts = 0;
    Gallery? gallery;
    while (attempts < maxAttempts) {
      gallery = await getGallery(uri: galleryUri);
      if (gallery != null && gallery.items.length == expectedCount) {
        appLogger.i(
          'Gallery $galleryUri has expected number of items: $expectedCount',
        );
        return gallery;
      }
      await Future.delayed(pollDelay);
      attempts++;
    }
    appLogger.w(
      'Gallery $galleryUri did not reach expected items count ($expectedCount) after polling.',
    );
    return null;
  }

  /// Uploads a blob (file) to the atproto uploadBlob endpoint using DPoP authentication.
  /// Returns the blob reference map on success, or null on failure.
  Future<Map<String, dynamic>?> uploadBlob(File file) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for uploadBlob');
      return null;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.uploadBlob');

    // Detect MIME type, fallback to application/octet-stream if unknown
    String? mimeType = lookupMimeType(file.path);
    final contentType = mimeType ?? 'application/octet-stream';

    appLogger.i('Uploading blob: ${file.path} (MIME: $mimeType)');

    final bytes = await file.readAsBytes();

    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w(
        'Failed to upload blob: \\${response.statusCode} \\${response.body} (File: \\${file.path}, MIME: \\${mimeType})',
      );
      return null;
    }

    try {
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      appLogger.i('Uploaded blob result: $result');
      return result;
    } catch (e, st) {
      appLogger.e('Failed to parse uploadBlob response: $e', stackTrace: st);
      return null;
    }
  }

  Future<String?> createPhoto({
    required Map<String, dynamic> blob,
    required int width,
    required int height,
    String alt = '',
  }) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for createPhotoRecord');
      return null;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final did = session.subject;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.createRecord');
    final record = {
      'collection': 'social.grain.photo',
      'repo': did,
      'record': {
        'photo': blob['blob'],
        'aspectRatio': {'width': width, 'height': height},
        'alt': "",
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    };
    appLogger.i('Creating photo record: $record');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w(
        'Failed to create photo record: \\${response.statusCode} \\${response.body}',
      );
      return null;
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    appLogger.i('Created photo record result: $result');
    return result['uri'] as String?;
  }

  Future<String?> createGalleryItem({
    required String galleryUri,
    required String photoUri,
    required int position,
  }) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for createGalleryItem');
      return null;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final did = session.subject;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.createRecord');
    final record = {
      'collection': 'social.grain.gallery.item',
      'repo': did,
      'record': {
        'gallery': galleryUri,
        'item': photoUri,
        'position': position,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    };
    appLogger.i('Creating gallery item: $record');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w(
        'Failed to create gallery item: \\${response.statusCode} \\${response.body}',
      );
      return null;
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    appLogger.i('Created gallery item result: $result');
    return result['uri'] as String?;
  }
}

final apiService = ApiService();
