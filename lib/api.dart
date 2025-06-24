import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile.dart';
import 'gallery.dart';

class ApiService {
  String? _accessToken;
  Profile? currentUser;
  List<Gallery> galleries = [];

  void setToken(String token) {
    _accessToken = token;
  }

  Future<void> fetchProfile() async {
    if (_accessToken == null) return;
    final response = await http.get(
      Uri.parse('http://localhost:8080/xrpc/social.grain.actor.getProfile'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      currentUser = Profile.fromJson(data);
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  Future<List<Gallery>> fetchActorGalleries() async {
    if (_accessToken == null) return [];
    final response = await http.get(
      Uri.parse(
        'http://localhost:8080/xrpc/social.grain.gallery.getActorGalleries',
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
      throw Exception('Failed to load galleries: \\${response.statusCode}');
    }
  }
}

final apiService = ApiService();
