import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:grain/api.dart';
import 'package:grain/app_logger.dart';
import 'package:grain/main.dart';
import 'package:grain/models/atproto_session.dart';
import 'package:grain/models/session.dart';

class Auth {
  static const _storage = FlutterSecureStorage();
  Auth();

  Future<bool> hasToken() async {
    final session = await _loadSession();
    return session != null && session.token.isNotEmpty && !isSessionExpired(session.session);
  }

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

    final session = await apiService.fetchSession(token);
    if (session == null) {
      throw Exception('Failed to fetch session after login');
    }
    await _saveSession(session);
  }

  Future<void> _saveSession(Session session) async {
    final sessionJson = jsonEncode(session.toJson());
    await _storage.write(key: 'session', value: sessionJson);
  }

  Future<Session?> _loadSession() async {
    final sessionJsonString = await _storage.read(key: 'session');
    if (sessionJsonString == null) return null;

    try {
      final sessionJson = jsonDecode(sessionJsonString);
      return Session.fromJson(sessionJson);
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

  Future<Session?> getValidSession() async {
    final session = await _loadSession();
    if (session == null) {
      // No session at all, do not attempt refresh
      return null;
    }
    if (isSessionExpired(session.session)) {
      appLogger.w('Session is expired, attempting refresh');
      try {
        final refreshed = await apiService.fetchSession();
        if (refreshed != null && !isSessionExpired(refreshed.session)) {
          await _saveSession(refreshed);
          appLogger.i('Session refreshed and saved');
          return refreshed;
        } else {
          appLogger.w('Session refresh failed or still expired, clearing session');
          await clearSession();
          return null;
        }
      } catch (e) {
        appLogger.e('Error refreshing session: $e');
        await clearSession();
        return null;
      }
    }
    return session;
  }

  Future<void> clearSession() async {
    // Revoke session on the server
    await apiService.revokeSession();
    // Remove session from secure storage
    await _storage.delete(key: 'session');
    // Clear any in-memory session/user data
    apiService.currentUser = null;
  }
}

final auth = Auth();
