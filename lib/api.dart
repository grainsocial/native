import 'dart:convert';
import 'dart:io';

import 'package:at_uri/at_uri.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grain/app_logger.dart';
import 'package:grain/dpop_client.dart';
import 'package:grain/main.dart';
import 'package:grain/models/atproto_session.dart';
import 'package:grain/photo_manip.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';
import 'package:mime/mime.dart';

import './auth.dart';
import 'models/followers_result.dart';
import 'models/follows_result.dart';
import 'models/gallery.dart';
import 'models/gallery_item.dart';
import 'models/gallery_photo.dart';
import 'models/gallery_thread.dart';
import 'models/notification.dart' as grain;
import 'models/profile.dart';

class ApiService {
  // ...existing code...
  static const _storage = FlutterSecureStorage();
  String? _accessToken;
  Profile? currentUser;
  Profile? loadedProfile;
  List<Gallery> galleries = [];

  String get _apiUrl => AppConfig.apiUrl;

  Future<void> loadToken() async {
    _accessToken = await _storage.read(key: 'access_token');
  }

  Future<void> setToken(String? token) async {
    _accessToken = token;
    if (token != null) {
      await _storage.write(key: 'access_token', value: token);
    } else {
      await _storage.delete(key: 'access_token');
    }
  }

  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  Future<AtprotoSession?> fetchSession() async {
    if (_accessToken == null) return null;

    final response = await http.get(
      Uri.parse('$_apiUrl/oauth/session'),
      headers: {'Authorization': 'Bearer $_accessToken', 'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch session');
    }

    final json = jsonDecode(response.body);
    final token = json['tokenSet'] ?? {};
    return AtprotoSession(
      accessToken: token['access_token'] as String,
      tokenType: token['token_type'] as String,
      expiresAt: DateTime.parse(token['expires_at'] as String),
      dpopJwk: JsonWebKey.fromJson(json['dpopJwk'] as Map<String, dynamic>),
      issuer: token['iss'] as String,
      subject: token['sub'] as String,
    );
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
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.actor.getProfile?actor=$did'),
      headers: {'Content-Type': 'application/json', 'Authorization': "Bearer $_accessToken"},
    );
    if (response.statusCode != 200) {
      appLogger.w('Failed to fetch profile: ${response.statusCode} ${response.body}');
      return null;
    }
    return Profile.fromJson(jsonDecode(response.body));
  }

  Future<List<Gallery>> fetchActorGalleries({required String did}) async {
    appLogger.i('Fetching galleries for actor did: $did');
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.gallery.getActorGalleries?actor=$did'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      appLogger.w('Failed to fetch galleries: ${response.statusCode} ${response.body}');
      return [];
    }
    final json = jsonDecode(response.body);
    galleries =
        (json['items'] as List<dynamic>?)?.map((item) => Gallery.fromJson(item)).toList() ?? [];
    return galleries;
  }

  Future<List<GalleryPhoto>> fetchActorPhotos({required String did}) async {
    appLogger.i('Fetching photos for actor did: $did');
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.photo.getActorPhotos?actor=$did'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      appLogger.w('Failed to fetch photos: ${response.statusCode} ${response.body}');
      return [];
    }
    final json = jsonDecode(response.body);
    return (json['items'] as List<dynamic>?)?.map((item) => GalleryPhoto.fromJson(item)).toList() ??
        [];
  }

  Future<List<Gallery>> getTimeline({String? algorithm}) async {
    if (_accessToken == null) {
      return [];
    }
    appLogger.i('Fetching timeline with algorithm: \\${algorithm ?? 'default'}');
    final uri = algorithm != null
        ? Uri.parse('$_apiUrl/xrpc/social.grain.feed.getTimeline?algorithm=$algorithm')
        : Uri.parse('$_apiUrl/xrpc/social.grain.feed.getTimeline');
    final response = await http.get(
      uri,
      headers: {'Authorization': "Bearer $_accessToken", 'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      appLogger.w('Failed to fetch timeline: ${response.statusCode} ${response.body}');
      return [];
    }
    final json = jsonDecode(response.body);
    return (json['feed'] as List<dynamic>?)
            ?.map((item) => Gallery.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<Gallery?> getGallery({required String uri}) async {
    appLogger.i('Fetching gallery for uri: $uri');
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.gallery.getGallery?uri=$uri'),
      headers: {'Authorization': "Bearer $_accessToken", 'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      appLogger.w('Failed to fetch gallery: ${response.statusCode} ${response.body}');
      return null;
    }
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        return Gallery.fromJson(json);
      } else {
        appLogger.w('Unexpected response type for getGallery: ${response.body}');
        return null;
      }
    } catch (e, st) {
      appLogger.e('Error parsing getGallery response: $e', stackTrace: st);
      return null;
    }
  }

  Future<GalleryThread?> getGalleryThread({required String uri}) async {
    appLogger.i('Fetching gallery thread for uri: $uri');
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.gallery.getGalleryThread?uri=$uri'),
      headers: {'Content-Type': 'application/json', 'Authorization': "Bearer $_accessToken"},
    );
    if (response.statusCode != 200) {
      appLogger.w('Failed to fetch gallery thread: \\${response.statusCode} \\${response.body}');
      return null;
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return GalleryThread.fromJson(json);
  }

  Future<List<grain.Notification>> getNotifications() async {
    if (_accessToken == null) {
      appLogger.w('No access token for getNotifications');
      return [];
    }
    appLogger.i('Fetching notifications');
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.notification.getNotifications'),
      headers: {'Authorization': "Bearer $_accessToken", 'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      appLogger.w('Failed to fetch notifications: \\${response.statusCode} \\${response.body}');
      return [];
    }
    final json = jsonDecode(response.body);
    return (json['notifications'] as List<dynamic>?)
            ?.map((item) {
              final map = item as Map<String, dynamic>;
              final reasonSubject = map['reasonSubject'];
              if (reasonSubject != null && reasonSubject is Map<String, dynamic>) {
                final type =
                    reasonSubject['\$type'] ?? reasonSubject[r'$type'] ?? reasonSubject['type'];
                switch (type) {
                  case 'social.grain.gallery.defs#galleryView':
                    map['reasonSubjectGallery'] = map['reasonSubject'];
                    break;
                  case 'social.grain.actor.defs#profileView':
                    map['reasonSubjectProfile'] = map['reasonSubject'];
                    break;
                  case 'social.grain.comment.defs#commentView':
                    map['reasonSubjectComment'] = map['reasonSubject'];
                    break;
                }
              }
              map.remove('reasonSubject');
              try {
                return grain.Notification.fromJson(map);
              } catch (e, st) {
                appLogger.e('Failed to deserialize notification: $e', stackTrace: st);
                return null;
              }
            })
            .whereType<grain.Notification>()
            .toList() ??
        [];
  }

  Future<List<Profile>> searchActors(String query) async {
    if (_accessToken == null) {
      appLogger.w('No access token for searchActors');
      return [];
    }
    appLogger.i('Searching actors with query: $query');
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.actor.searchActors?q=$query'),
      headers: {'Authorization': "Bearer $_accessToken", 'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      appLogger.w('Failed to search actors: ${response.statusCode} ${response.body}');
      return [];
    }
    final json = jsonDecode(response.body);
    return (json['actors'] as List<dynamic>?)?.map((item) => Profile.fromJson(item)).toList() ?? [];
  }

  Future<List<Gallery>> getActorFavs({required String did}) async {
    appLogger.i('Fetching actor favs for did: $did');
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.actor.getActorFavs?actor=$did'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      appLogger.w('Failed to fetch actor favs: ${response.statusCode} ${response.body}');
      return [];
    }
    final json = jsonDecode(response.body);
    return (json['items'] as List<dynamic>?)?.map((item) => Gallery.fromJson(item)).toList() ?? [];
  }

  Future<String?> createGallery({
    required String title,
    required String description,
    List<Map<String, dynamic>>? facets,
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
        if (facets != null) 'facets': facets,
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
      appLogger.w('Failed to create gallery: \\${response.statusCode} \\${response.body}');
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
        appLogger.i('Gallery $galleryUri has expected number of items: $expectedCount');
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

  /// Polls the gallery thread until the number of comments matches [expectedCount] or timeout.
  /// Returns the thread map if successful, or null if timeout.
  Future<GalleryThread?> pollGalleryThreadComments({
    required String galleryUri,
    required int expectedCount,
    Duration pollDelay = const Duration(seconds: 2),
    int maxAttempts = 20,
  }) async {
    int attempts = 0;
    GalleryThread? thread;
    while (attempts < maxAttempts) {
      thread = await getGalleryThread(uri: galleryUri);
      if (thread != null && thread.comments.length == expectedCount) {
        appLogger.i('Gallery thread $galleryUri has expected number of comments: $expectedCount');
        return thread;
      }
      await Future.delayed(pollDelay);
      attempts++;
    }
    appLogger.w(
      'Gallery thread $galleryUri did not reach expected comments count ($expectedCount) after polling.',
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
      appLogger.w('Failed to create photo record: \\${response.statusCode} \\${response.body}');
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
      appLogger.w('Failed to create gallery item: \\${response.statusCode} \\${response.body}');
      return null;
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    appLogger.i('Created gallery item result: $result');
    return result['uri'] as String?;
  }

  Future<String?> createComment({
    required String text,
    List<Map<String, dynamic>>? facets,
    required String subject,
    String? focus, // Now a String (photo URI)
    String? replyTo,
  }) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for createComment');
      return null;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final did = session.subject;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.createRecord');
    final record = {
      'collection': 'social.grain.comment',
      'repo': did,
      'record': {
        'text': text,
        if (facets != null) 'facets': facets,
        'subject': subject,
        if (focus != null) 'focus': focus, // focus is now a String
        if (replyTo != null) 'replyTo': replyTo,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    };
    appLogger.i('Creating comment: $record');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w('Failed to create comment: \\${response.statusCode} \\${response.body}');
      return null;
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    appLogger.i('Created comment result: $result');
    return result['uri'] as String?;
  }

  Future<String?> createFavorite({required String galleryUri}) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for createFavorite');
      return null;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final did = session.subject;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.createRecord');
    final record = {
      'collection': 'social.grain.favorite',
      'repo': did,
      'record': {'subject': galleryUri, 'createdAt': DateTime.now().toUtc().toIso8601String()},
    };
    appLogger.i('Creating favorite: $record');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w('Failed to create favorite: \\${response.statusCode} \\${response.body}');
      return null;
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    appLogger.i('Created favorite result: $result');
    return result['uri'] as String?;
  }

  Future<String?> createFollow({required String followeeDid}) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for createFollow');
      return null;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final did = session.subject;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.createRecord');
    final record = {
      'collection': 'social.grain.graph.follow',
      'repo': did,
      'record': {'subject': followeeDid, 'createdAt': DateTime.now().toUtc().toIso8601String()},
    };
    appLogger.i('Creating follow: $record');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w('Failed to create follow: \\${response.statusCode} \\${response.body}');
      return null;
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    appLogger.i('Created follow result: $result');
    return result['uri'] as String?;
  }

  /// Deletes a record by its URI using DPoP authentication.
  /// Returns true on success, false on failure.
  Future<bool> deleteRecord(String uri) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for deleteRecord');
      return false;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.deleteRecord');
    final repo = session.subject;
    if (repo.isEmpty) {
      appLogger.w('No repo (DID) available from session for deleteRecord');
      return false;
    }
    String? collection;
    String? rkey;
    try {
      final atUri = AtUri.parse(uri);
      collection = atUri.collection.toString();
      rkey = atUri.rkey;
    } catch (e) {
      appLogger.w('Failed to parse collection from uri: $uri');
    }
    if (collection == null || collection.isEmpty) {
      appLogger.w('No collection found in uri: $uri');
      return false;
    }
    final payload = {'uri': uri, 'repo': repo, 'collection': collection, 'rkey': rkey};
    appLogger.i('Deleting record: $payload');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      appLogger.w('Failed to delete record: \\${response.statusCode} \\${response.body}');
      return false;
    }
    appLogger.i('Deleted record $uri');
    return true;
  }

  /// Updates the current user's profile (displayName, description, avatar).
  /// If avatarFile is provided, uploads it as a blob and sets avatar.
  /// Returns true on success, false on failure.
  Future<bool> updateProfile({
    required String displayName,
    required String description,
    File? avatarFile,
  }) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for updateProfile');
      return false;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final did = session.subject;
    // Fetch the raw profile record from atproto getRecord endpoint
    final getUrl = Uri.parse(
      '$issuer/xrpc/com.atproto.repo.getRecord?repo=$did&collection=social.grain.actor.profile&rkey=self',
    );
    final getResp = await dpopClient.send(
      method: 'GET',
      url: getUrl,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
    );
    if (getResp.statusCode != 200) {
      appLogger.w(
        'Failed to fetch raw profile record for update: \\${getResp.statusCode} \\${getResp.body}',
      );
      return false;
    }
    final recordJson = jsonDecode(getResp.body) as Map<String, dynamic>;
    var avatar = recordJson['value']?['avatar'];
    // If avatarFile is provided, upload it and set avatar
    if (avatarFile != null) {
      try {
        // Resize avatar before upload using photo_manip
        final resizeResult = await resizeImage(file: avatarFile);
        final blobResult = await uploadBlob(resizeResult.file);
        if (blobResult != null && blobResult['blob'] != null) {
          avatar = blobResult['blob'];
        }
      } catch (e) {
        appLogger.w('Failed to upload avatar: $e');
      }
    }
    // Update the profile record
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.putRecord');
    final record = {
      'collection': 'social.grain.actor.profile',
      'repo': did,
      'rkey': 'self',
      'record': {'displayName': displayName, 'description': description, 'avatar': avatar},
    };
    appLogger.i('Updating profile: $record');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w('Failed to update profile: \\${response.statusCode} \\${response.body}');
      return false;
    }
    appLogger.i('Profile updated successfully');
    return true;
  }

  /// Fetch followers for a given actor DID
  Future<FollowersResult> getFollowers({
    required String actor,
    String? cursor,
    int limit = 50,
  }) async {
    final uri = Uri.parse(
      '$_apiUrl/xrpc/social.grain.graph.getFollowers?actor=$actor&limit=$limit${cursor != null ? '&cursor=$cursor' : ''}',
    );
    final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch followers: \\${response.statusCode} \\${response.body}');
    }
    final json = jsonDecode(response.body);
    return FollowersResult.fromJson(json);
  }

  /// Fetch follows for a given actor DID
  Future<FollowsResult> getFollows({required String actor, String? cursor, int limit = 50}) async {
    final uri = Uri.parse(
      '$_apiUrl/xrpc/social.grain.graph.getFollows?actor=$actor&limit=$limit${cursor != null ? '&cursor=$cursor' : ''}',
    );
    final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch follows: \\${response.statusCode} \\${response.body}');
    }
    final json = jsonDecode(response.body);
    return FollowsResult.fromJson(json);
  }

  /// Updates the sort order of gallery items using com.atproto.repo.applyWrites
  /// [galleryUri]: The URI of the gallery (at://did/social.grain.gallery/rkey)
  /// [sortedItemUris]: List of item URIs in the desired order
  /// [itemsMeta]: List of GalleryItem meta objects (must include gallery, item, createdAt, uri)
  /// Returns true on success, false on failure
  Future<bool> updateGallerySortOrder({
    required String galleryUri,
    required List<GalleryItem> orderedItems,
  }) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for updateGallerySortOrder');
      return false;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final did = session.subject;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.applyWrites');

    final updates = <Map<String, dynamic>>[];
    int position = 0;
    for (final item in orderedItems) {
      String rkey = '';
      try {
        rkey = AtUri.parse(item.uri).rkey;
      } catch (_) {}
      updates.add({
        '\$type': 'com.atproto.repo.applyWrites#update',
        'collection': 'social.grain.gallery.item',
        'rkey': rkey,
        'value': {
          'gallery': item.gallery,
          'item': item.item,
          'createdAt': item.createdAt,
          'position': position,
        },
      });
      position++;
    }
    if (updates.isEmpty) {
      appLogger.w('No updates to apply for gallery sort order');
      return false;
    }
    final payload = {'repo': did, 'validate': false, 'writes': updates};
    appLogger.i('Applying gallery sort order updates: $payload');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w(
        'Failed to apply gallery sort order: \\${response.statusCode} \\${response.body}',
      );
      return false;
    }
    appLogger.i('Gallery sort order updated successfully');
    return true;
  }

  /// Updates a gallery's title and description.
  /// Returns true on success, false on failure.
  Future<bool> updateGallery({
    required String galleryUri,
    required String title,
    required String description,
    required String createdAt,
    List<Map<String, dynamic>>? facets,
  }) async {
    final session = await auth.getValidSession();
    if (session == null) {
      appLogger.w('No valid session for updateGallery');
      return false;
    }
    final dpopClient = DpopHttpClient(dpopKey: session.dpopJwk);
    final issuer = session.issuer;
    final did = session.subject;
    final url = Uri.parse('$issuer/xrpc/com.atproto.repo.putRecord');
    // Extract rkey from galleryUri
    String rkey = '';
    try {
      rkey = AtUri.parse(galleryUri).rkey;
    } catch (_) {}
    if (rkey.isEmpty) {
      appLogger.w('No rkey found in galleryUri: $galleryUri');
      return false;
    }
    final record = {
      'collection': 'social.grain.gallery',
      'repo': did,
      'rkey': rkey,
      'record': {
        'title': title,
        'description': description,
        if (facets != null) 'facets': facets,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'createdAt': createdAt,
      },
    };
    appLogger.i('Updating gallery: $record');
    final response = await dpopClient.send(
      method: 'POST',
      url: url,
      accessToken: session.accessToken,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      appLogger.w('Failed to update gallery: ${response.statusCode} ${response.body}');
      return false;
    }
    appLogger.i('Gallery updated successfully');
    return true;
  }
}

final apiService = ApiService();
