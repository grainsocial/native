import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'gallery.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  String? _accessToken;
  Profile? currentUser;
  List<Gallery> galleries = [];

  String get _apiUrl => dotenv.env['API_URL'] ?? 'http://localhost:8080';

  void setToken(String token) {
    _accessToken = token;
  }

  Future<void> fetchProfile({required String did}) async {
    if (_accessToken == null) return;
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.actor.getProfile?actor=$did'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      currentUser = Profile.fromJson(data);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  Future<List<Gallery>> fetchActorGalleries({required String did}) async {
    if (_accessToken == null) return [];
    final response = await http.get(
      Uri.parse(
        '$_apiUrl/xrpc/social.grain.gallery.getActorGalleries?actor=$did',
      ),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List<dynamic>?;
      if (items != null) {
        galleries = items.map((item) => Gallery.fromJson(item)).toList();
      } else {
        galleries = [];
      }
      return galleries;
    } else {
      throw Exception('Failed to load galleries: ${response.statusCode}');
    }
  }

  Future<void> fetchCurrentUser() async {
    if (_accessToken == null) return;
    final response = await http.get(
      Uri.parse('$_apiUrl/oauth/session'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      currentUser = Profile.fromJson(data);
    } else {
      throw Exception('Failed to fetch current user: \\${response.statusCode}');
    }
  }

  Future<List<Gallery>> getTimeline() async {
    if (_accessToken == null) return [];
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.feed.getTimeline'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['feed'] as List<dynamic>?;
      if (items != null) {
        return items
            .map((item) => Gallery.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to load timeline: ${response.statusCode}');
    }
  }

  Future<Gallery?> getGallery({required String uri}) async {
    if (_accessToken == null) return null;
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.gallery.getGallery?uri=$uri'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Gallery.fromJson(data);
    } else {
      throw Exception('Failed to load gallery: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getGalleryThread({required String uri}) async {
    if (_accessToken == null) throw Exception('No access token');
    final response = await http.get(
      Uri.parse('$_apiUrl/xrpc/social.grain.gallery.getGalleryThread?uri=$uri'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load gallery thread: ${response.statusCode}');
    }
  }
}

final apiService = ApiService();
