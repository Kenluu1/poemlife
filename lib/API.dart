import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ValueNotifier<int> followEvents = ValueNotifier<int>(0);

  // Gunakan http://localhost:3005/api jika menggunakan Emulator Android bawaan.
  // Gunakan IP lokal komputer (seperti 10.203.212.49) jika menggunakan HP fisik.
  static const String baseUrl = 'http://localhost:3005/api';

  // Helper untuk mendapatkan header request, menyertakan token jika ada
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> registerUser(String username, String password, String nim, String email) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'nim': nim,
          'email': email,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Register Sukses: $responseData');
        

        if (responseData['data'] != null && responseData['data']['login_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['data']['login_token']);
          if (responseData['data']['user'] != null) {
            final user = responseData['data']['user'];
            await prefs.setInt('userId', user['id']);
            await prefs.setString('username', user['username']);
            await prefs.setString('email', user['email'] ?? '');
          }
        }
        return true;
      } else {
        print('Register Gagal: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error Register: $e');
      return false;
    }
  }

  // Login
  Future<String?> loginUser(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Login Sukses: $responseData');

        if (responseData['data'] != null && responseData['data']['token'] != null) {
          String token = responseData['data']['token'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          
          if (responseData['data']['user'] != null) {
            final user = responseData['data']['user'];
            await prefs.setInt('userId', user['id']);
            await prefs.setString('username', user['username']);
            await prefs.setString('email', user['email'] ?? '');
            await prefs.setString('nim', user['nim'] ?? '');
          }
          return token;
        }
        return null;
      } else {
        print('Login Gagal: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error Login: $e');
      return null;
    }
  }


  Future<List<dynamic>> getPoems({String? type, int? categoryId, String? search, int? targetUserId}) async {
    final Map<String, String> queryParams = {};
    if (type != null) queryParams['t'] = type;
    if (categoryId != null) queryParams['c'] = categoryId.toString();
    if (search != null) queryParams['q'] = search;
    if (targetUserId != null) queryParams['u'] = targetUserId.toString();

    final uri = Uri.parse('$baseUrl/poem/').replace(queryParameters: queryParams);
    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          return responseData['data'] as List<dynamic>;
        }
      }
      print('Gagal mengambil list puisi: ${response.body}');
      return [];
    } catch (e) {
      print('Error getPoems: $e');
      return [];
    }
  }


  Future<Map<String, dynamic>?> getPoemDetail(int poemId) async {
    final url = Uri.parse('$baseUrl/poem/$poemId');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          return responseData['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getPoemDetail: $e');
      return null;
    }
  }


  Future<bool> createPoem({
    required String title,
    required String content,
    required int categoryId,
    int published = 1,
  }) async {
    final url = Uri.parse('$baseUrl/poem/create');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'title': title,
          'content': content,
          'category_id': categoryId,
          'published': published,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Buat puisi sukses');
        return true;
      }
      print('Gagal membuat puisi: ${response.body}');
      return false;
    } catch (e) {
      print('Error createPoem: $e');
      return false;
    }
  }


  Future<bool> toggleBookmark(int poemId, bool currentlyBookmarked) async {
    final url = currentlyBookmarked
        ? Uri.parse('$baseUrl/bookmark/delete/$poemId')
        : Uri.parse('$baseUrl/bookmark/create');
    try {
      final headers = await _getHeaders();
      final http.Response response;
      if (currentlyBookmarked) {
        response = await http.delete(url, headers: headers);
      } else {
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode({'poem_id': poemId}),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error toggleBookmark: $e');
      return false;
    }
  }


  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    final url = Uri.parse('$baseUrl/user/$userId');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          return responseData['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getUserProfile: $e');
      return null;
    }
  }

  Future<bool> followUser(int userId) async {
    final url = Uri.parse('$baseUrl/user/$userId/follow');
    try {
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        followEvents.value++;
        return true;
      }
      return false;
    } catch (e) {
      print('Error followUser: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(int userId) async {
    final url = Uri.parse('$baseUrl/user/$userId/unfollow');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) {
        followEvents.value++;
        return true;
      }
      return false;
    } catch (e) {
      print('Error unfollowUser: $e');
      return false;
    }
  }

  Future<bool> deletePoem(int poemId) async {
    final url = Uri.parse('$baseUrl/poem/delete/$poemId');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        return true;
      }
      print('Gagal menghapus puisi: ${response.body}');
      return false;
    } catch (e) {
      print('Error deletePoem: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getComments(int poemId) async {
    final url = Uri.parse('$baseUrl/comment/$poemId');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          final List<dynamic> list = responseData['data'];
          return list.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return null;
    } catch (e) {
      print('Error getComments: $e');
      return null;
    }
  }

  Future<bool> createComment(int poemId, String commentText, {int? parentCommentId}) async {
    final url = Uri.parse('$baseUrl/comment/create');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'poem_id': poemId,
          'comment': commentText,
          if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error createComment: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getBookmarks() async {
    final url = Uri.parse('$baseUrl/bookmark');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          final List<dynamic> list = responseData['data'];
          return list.map((item) => item as Map<String, dynamic>).toList();
        }
      }
      return null;
    } catch (e) {
      print('Error getBookmarks: $e');
      return null;
    }
  }

  Future<bool> toggleReaction(int poemId, int reactionId) async {
    final url = Uri.parse('$baseUrl/poem/reaction');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'poem_id': poemId,
          'reaction_id': reactionId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error toggleReaction: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required String username,
    required String nim,
    required String email,
    required String bio,
  }) async {
    final url = Uri.parse('$baseUrl/user/update');
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({
          'username': username,
          'nim': nim,
          'email': email,
          'bio': bio,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error updateUserProfile: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getNotifications() async {
    final url = Uri.parse('$baseUrl/notification');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      print('DEBUG getNotifications: status=${response.statusCode}, body=${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          final List<dynamic> list = responseData['data'];
          return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
      return null;
    } catch (e) {
      print('Error getNotifications: $e');
      return null;
    }
  }

  Future<bool> markNotificationsRead() async {
    final url = Uri.parse('$baseUrl/notification/mark-read');
    try {
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error markNotificationsRead: $e');
      return false;
    }
  }
}


class AuthService extends ApiService {}