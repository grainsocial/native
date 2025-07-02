import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:grain/api.dart';
import 'package:grain/app_logger.dart';
import 'package:grain/main.dart';
import 'package:grain/models/atproto_session.dart';

class Auth {
  static const _storage = FlutterSecureStorage();
  Auth();

  Future<void> login(String handle) async {
    final apiUrl = AppConfig.apiUrl;
    final redirectedUrl = await FlutterWebAuth2.authenticate(
      url: '$apiUrl/oauth/login?client=native&handle=${Uri.encodeComponent(handle)}',
      callbackUrlScheme: 'grainflutter',
    );
    final uri = Uri.parse(redirectedUrl);
    final token = uri.queryParameters['token'];

    appLogger.i('Redirected URL: $redirectedUrl');
    appLogger.i('User signed in with handle: $handle');

    apiService.setToken(token);

    final session = await apiService.fetchSession();
    if (session == null) {
      throw Exception('Failed to fetch session after login');
    }

    await _saveSession(session);
  }

  Future<void> _saveSession(AtprotoSession session) async {
    final sessionJson = jsonEncode(session.toJson());
    await _storage.write(key: 'atproto_session', value: sessionJson);
  }

  Future<AtprotoSession?> _loadSession() async {
    final jsonString = await _storage.read(key: 'atproto_session');
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString);
      return AtprotoSession.fromJson(json);
    } catch (e) {
      // Optionally log or clear storage if corrupted
      return null;
    }
  }

  bool isSessionExpired(
    AtprotoSession session, {
    Duration tolerance = const Duration(seconds: 30),
  }) {
    final now = DateTime.now().toUtc();
    return session.expiresAt.subtract(tolerance).isBefore(now);
  }

  Future<AtprotoSession?> getValidSession() async {
    var session = await _loadSession();
    if (session == null || isSessionExpired(session)) {
      appLogger.w('Session is expired or not found, attempting refresh');
      // Try to refresh session by calling fetchSession
      try {
        final refreshed = await apiService.fetchSession();
        if (refreshed != null && !isSessionExpired(refreshed)) {
          await _saveSession(refreshed);
          appLogger.i('Session refreshed and saved');
          return refreshed;
        } else {
          appLogger.w('Session refresh failed or still expired');
          return null;
        }
      } catch (e) {
        appLogger.e('Error refreshing session: $e');
        return null;
      }
    }
    return session;
  }
}

final auth = Auth();
