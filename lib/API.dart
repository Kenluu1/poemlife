import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ValueNotifier<int> followEvents = ValueNotifier<int>(0);
  static final ValueNotifier<Map<String, dynamic>?> reactionEvents = ValueNotifier<Map<String, dynamic>?>(null);
  static final ValueNotifier<String?> currentUserAvatar = ValueNotifier<String?>(null);
  static final ValueNotifier<int> currentUserAvatarVersion = ValueNotifier<int>(0);

  static void notifyReaction(Map<String, dynamic> data) {
    reactionEvents.value = {
      ...data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
  // static const String baseUrl = 'http://localhost:3005/api';
  static const String baseUrl = 'http://103.230.81.76:3005/api';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static String sanitizeImageUrl(String url) {
    if (!url.startsWith('http') && !url.startsWith('/assets/')) {
      return url;
    }
    if (url.contains('localhost:3005')) {
      if (url.contains('/assets/avatars/')) {
        int idx = url.indexOf('/assets/avatars/');
        return 'http://103.230.81.76:3005' + url.substring(idx);
      }
      if (url.contains('/assets/banners/')) {
        int idx = url.indexOf('/assets/banners/');
        return 'http://103.230.81.76:3005' + url.substring(idx);
      }
      if (url.contains('/assets/images/')) {
        int idx = url.indexOf('/assets/images/');
        return 'http://103.230.81.76:3005' + url.substring(idx);
      }
      return url.replaceAll('http://localhost:3005', 'http://103.230.81.76:3005');
    }
    if (url.startsWith('/assets/')) {
      return 'http://103.230.81.76:3005' + url;
    }
    return url;
  }

  static dynamic _sanitizeJson(dynamic json) {
    if (json is Map) {
      final Map<String, dynamic> sanitizedMap = {};
      json.forEach((key, value) {
        final String stringKey = key.toString();
        if (value is String) {
          sanitizedMap[stringKey] = sanitizeImageUrl(value);
        } else if (value is Map || value is List) {
          sanitizedMap[stringKey] = _sanitizeJson(value);
        } else {
          sanitizedMap[stringKey] = value;
        }
      });
      return sanitizedMap;
    } else if (json is List) {
      return json.map((item) => _sanitizeJson(item)).toList();
    } else if (json is String) {
      return sanitizeImageUrl(json);
    }
    return json;
  }

  static dynamic _decodeAndSanitize(String body) {
    try {
      final decoded = jsonDecode(body);
      return _sanitizeJson(decoded);
    } catch (_) {
      return jsonDecode(body);
    }
  }

  Future<String?> registerUser(
    String username,
    String password,
    String nim,
    String email,
  ) async {
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

      final responseData = _decodeAndSanitize(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Register Sukses: $responseData');

        if (responseData['data'] != null &&
            responseData['data']['login_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', responseData['data']['login_token']);
          if (responseData['data']['user'] != null) {
            final user = responseData['data']['user'];
            await prefs.setInt('userId', user['id']);
            await prefs.setString('username', user['username']);
            await prefs.setString('email', user['email'] ?? '');
          }
        }
        return null;
      } else {
        print('Register Gagal: ${response.body}');
        return responseData['message'] ?? 'Registrasi gagal. Coba lagi.';
      }
    } catch (e) {
      print('Error Register: $e');
      return 'Terjadi kesalahan koneksi.';
    }
  }

  // Login
  Future<String?> loginUser(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = _decodeAndSanitize(response.body);
        print('Login Sukses: $responseData');

        if (responseData['data'] != null &&
            responseData['data']['token'] != null) {
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

  Future<List<dynamic>> getPoems({
    String? type,
    int? categoryId,
    String? search,
    int? targetUserId,
  }) async {
    final Map<String, String> queryParams = {};
    if (type != null) queryParams['t'] = type;
    if (categoryId != null) queryParams['c'] = categoryId.toString();
    if (search != null) queryParams['q'] = search;
    if (targetUserId != null) queryParams['u'] = targetUserId.toString();

    final uri = Uri.parse(
      '$baseUrl/poem/',
    ).replace(queryParameters: queryParams);
    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = _decodeAndSanitize(response.body);
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
        final responseData = _decodeAndSanitize(response.body);
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
        final responseData = _decodeAndSanitize(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          final profileData = responseData['data'] as Map<String, dynamic>;
          final avatar = profileData['image']?.toString();
          final prefs = await SharedPreferences.getInstance();
          final currentUserId = prefs.getInt('userId');
          if (userId == currentUserId) {
            if (avatar != null && avatar.isNotEmpty) {
              currentUserAvatar.value = avatar;
            } else {
              currentUserAvatar.value = null;
            }
          }
          return profileData;
        }
      }
      return null;
    } catch (e) {
      print('Error getUserProfile: $e');
      return null;
    }
  }

  Future<List<dynamic>> getTopWriters({String? filter, int? limit}) async {
    final Map<String, String> queryParams = {};
    if (filter != null) queryParams['filter'] = filter;
    if (limit != null) queryParams['limit'] = limit.toString();

    final url = Uri.parse(
      '$baseUrl/user/top-writers',
    ).replace(queryParameters: queryParams);
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = _decodeAndSanitize(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          return responseData['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Error getTopWriters: $e');
      return [];
    }
  }

  Future<List<dynamic>> getWordBank() async {
    final url = Uri.parse('$baseUrl/misc/word_bank');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = _decodeAndSanitize(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          return responseData['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Error getWordBank: $e');
      return [];
    }
  }

  Future<List<dynamic>> getSongs({int? categoryId}) async {
    final queryParams = categoryId != null ? '?category_id=$categoryId' : '';
    final url = Uri.parse('$baseUrl/misc/songs$queryParams');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = _decodeAndSanitize(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          return responseData['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Error getSongs: $e');
      return [];
    }
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final url = Uri.parse(
      '$baseUrl/user/search/query?q=${Uri.encodeComponent(query)}',
    );
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = _decodeAndSanitize(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          return responseData['data'] as List<dynamic>;
        }
      }
      return [];
    } catch (e) {
      print('Error searchUsers: $e');
      return [];
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
        final responseData = _decodeAndSanitize(response.body);
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

  Future<bool> createComment(
    int poemId,
    String commentText, {
    int? parentCommentId,
  }) async {
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
        final responseData = _decodeAndSanitize(response.body);
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
        body: jsonEncode({'poem_id': poemId, 'reaction_id': reactionId}),
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

  Future<bool> changePassword(String newPassword) async {
    final url = Uri.parse('$baseUrl/user/change-password');
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({'password': newPassword}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print('Error changePassword: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required String username,
    required String nim,
    required String email,
    required String bio,
    String? image,
    String? banner,
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
          if (image != null) 'image': image,
          if (banner != null) 'banner': banner,
        }),
      );

      print('UpdateProfile Response status: ${response.statusCode}');
      print('UpdateProfile Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = _decodeAndSanitize(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          final profileData = responseData['data'] as Map<String, dynamic>;
          final avatar = profileData['image']?.toString();
          if (avatar != null && avatar.isNotEmpty) {
            currentUserAvatar.value = avatar;
            currentUserAvatarVersion.value++;
          } else {
            currentUserAvatar.value = null;
            currentUserAvatarVersion.value++;
          }
        }
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
      print(
        'DEBUG getNotifications: status=${response.statusCode}, body=${response.body}',
      );

      if (response.statusCode == 200) {
        final responseData = _decodeAndSanitize(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          final List<dynamic> list = responseData['data'];
          return list
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
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

  Future<String?> generatePoem(String poem) async {
    final url = Uri.parse('$baseUrl/poem/generate');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'poem': poem}),
      );

      if (response.statusCode == 200) {
        final responseData = _decodeAndSanitize(response.body);
        if (responseData['error'] == false && responseData['data'] != null) {
          return responseData['data']['generated'] as String?;
        }
      }
      print('Gagal generate puisi: ${response.body}');
      return null;
    } catch (e) {
      print('Error generatePoem: $e');
      return null;
    }
  }

  Future<bool> updatePoem({
    required int poemId,
    required String title,
    required String content,
    required int categoryId,
    required int published,
  }) async {
    final url = Uri.parse('$baseUrl/poem/update');
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({
          'poem_id': poemId,
          'title': title,
          'content': content,
          'category_id': categoryId,
          'is_published': published,
        }),
      );

      if (response.statusCode == 200) {
        print('Update puisi sukses');
        return true;
      }
      print('Gagal mengupdate puisi: ${response.body}');
      return false;
    } catch (e) {
      print('Error updatePoem: $e');
      return false;
    }
  }
}

class AuthService extends ApiService {}

class EmpathyIcon extends StatefulWidget {
  final bool isEmpathized;
  final double size;
  final VoidCallback? onTap;

  const EmpathyIcon({
    super.key,
    required this.isEmpathized,
    this.size = 20.0,
    this.onTap,
  });

  @override
  State<EmpathyIcon> createState() => _EmpathyIconState();
}

class _EmpathyIconState extends State<EmpathyIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant EmpathyIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEmpathized != widget.isEmpathized && widget.isEmpathized) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0.0);
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String assetPath = widget.isEmpathized ? 'assets/poelikes.png' : 'assets/poelike.png';

    Widget iconWidget = Image.asset(
      assetPath,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _EmpathyPainter(isEmpathized: widget.isEmpathized),
        );
      },
    );

    return GestureDetector(
      onTap: widget.onTap != null ? _handleTap : null,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: iconWidget,
      ),
    );
  }
}

class _EmpathyPainter extends CustomPainter {
  final bool isEmpathized;

  _EmpathyPainter({required this.isEmpathized});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius - 1);

    if (isEmpathized) {
      final Paint leftPaint = Paint()
        ..color = const Color(0xFF7583A8)
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, 1.5708, 3.14159, true, leftPaint);

      final Paint rightPaint = Paint()
        ..color = const Color(0xFFCC3333)
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, -1.5708, 3.14159, true, rightPaint);
    }

    final Paint linePaint = Paint()
      ..color = const Color(0xFF4A4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 1, linePaint);

    canvas.drawLine(
      Offset(radius, 1),
      Offset(radius, size.height - 1),
      linePaint,
    );

    final double topY = size.height * 0.35;
    canvas.drawLine(
      Offset(size.width * 0.15, topY),
      Offset(size.width * 0.85, topY),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.70, topY - size.height * 0.12),
      Offset(size.width * 0.85, topY),
      linePaint,
    );

    final double botY = size.height * 0.65;
    canvas.drawLine(
      Offset(size.width * 0.15, botY),
      Offset(size.width * 0.85, botY),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.30, botY + size.height * 0.12),
      Offset(size.width * 0.15, botY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _EmpathyPainter oldDelegate) {
    return oldDelegate.isEmpathized != isEmpathized;
  }
}
