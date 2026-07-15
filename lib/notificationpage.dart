import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poemlife/API.dart';
import 'package:poemlife/detailpage.dart';
import 'package:poemlife/otheruserprofile.dart';
import 'translation.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});
  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  final Color maroon = const Color(0xFFA33B3B);
  int? _currentUserId;

  List<Map<String, dynamic>> todayNotifications = [];
  List<Map<String, dynamic>> thisWeekNotifications = [];
  List<Map<String, dynamic>> earlierNotifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId');
    final list = await ApiService().getNotifications();
    print('NotificationPage DEBUG: fetched list count = ${list?.length}');
    if (mounted) {
      setState(() {
        _notifications = list ?? [];
        _groupNotifications();
        _isLoading = false;
      });
      // Mark all as read after fetching successfully
      if (_notifications.any((n) => n['is_read'] == false || n['is_read'] == 0)) {
        await ApiService().markNotificationsRead();
      }
    }
  }

  void _groupNotifications() {
    todayNotifications.clear();
    thisWeekNotifications.clear();
    earlierNotifications.clear();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 7));

    for (var n in _notifications) {
      if (n['date_created'] == null) {
        todayNotifications.add(n);
        continue;
      }
      try {
        final date = DateTime.parse(n['date_created']).toLocal();
        if (date.isAfter(todayStart)) {
          todayNotifications.add(n);
        } else if (date.isAfter(weekStart)) {
          thisWeekNotifications.add(n);
        } else {
          earlierNotifications.add(n);
        }
      } catch (_) {
        todayNotifications.add(n);
      }
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> notification) async {
    final sender = notification['sender'] as Map<String, dynamic>?;
    if (sender == null) return;
    
    final senderId = sender['id'];
    final bool currentFollowing = sender['is_following'] == true;

    setState(() {
      for (var n in _notifications) {
        final s = n['sender'] as Map<String, dynamic>?;
        if (s != null && s['id'] == senderId) {
          s['is_following'] = !currentFollowing;
        }
      }
      _groupNotifications();
    });

    bool success = false;
    if (!currentFollowing) {
      success = await ApiService().followUser(senderId);
    } else {
      success = await ApiService().unfollowUser(senderId);
    }

    if (!success && mounted) {
      setState(() {
        for (var n in _notifications) {
          final s = n['sender'] as Map<String, dynamic>?;
          if (s != null && s['id'] == senderId) {
            s['is_following'] = currentFollowing;
          }
        }
        _groupNotifications();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update follow status')),
      );
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'Just now';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Just now';
    }
  }

  Widget _buildNotificationText(Map<String, dynamic> notification) {
    final sender = notification['sender'] as Map<String, dynamic>?;
    final senderName = sender != null ? sender['username'] ?? 'Someone' : 'Someone';
    final poem = notification['poem'] as Map<String, dynamic>?;
    final poemTitle = poem != null ? poem['title'] ?? 'your poem' : 'your poem';
    final int? poemAuthorId = poem != null ? poem['user_id'] as int? : null;

    final List<TextSpan> spans = [];

    // Username is bold
    spans.add(
      TextSpan(
        text: senderName,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );

    switch (notification['type']) {
      case 'like':
        spans.add(TextSpan(text: T.s('notif_like')));
        spans.add(
          TextSpan(
            text: '"$poemTitle"',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        );
        spans.add(const TextSpan(text: '.'));
        break;
      case 'comment':
        if (poemAuthorId != null && _currentUserId != null && poemAuthorId != _currentUserId) {
          spans.add(TextSpan(text: T.s('notif_reply')));
        } else {
          spans.add(TextSpan(text: T.s('notif_comment')));
        }
        spans.add(
          TextSpan(
            text: '"$poemTitle"',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        );
        spans.add(const TextSpan(text: '.'));
        break;
      case 'reply':
        spans.add(TextSpan(text: T.s('notif_reply')));
        spans.add(
          TextSpan(
            text: '"$poemTitle"',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        );
        spans.add(const TextSpan(text: '.'));
        break;
      case 'follow':
        spans.add(TextSpan(text: T.s('notif_follow')));
        break;
      default:
        spans.add(TextSpan(text: T.s('notif_default')));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.35, fontFamily: 'serif'),
        children: spans,
      ),
    );
  }

  Widget _buildNotificationRow(Map<String, dynamic> notification) {
    final sender = notification['sender'] as Map<String, dynamic>?;
    final avatar = sender != null && sender['image'] != null
        ? sender['image'].toString()
        : 'https://i.pravatar.cc/150?img=10';
    final isUnread = notification['is_read'] == false || notification['is_read'] == 0;
    final type = notification['type'];
    final bool isFollowing = sender != null && sender['is_following'] == true;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Unread Maroon Dot
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(left: 8, right: 8),
                decoration: BoxDecoration(
                  color: isUnread ? maroon : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              // Circular Avatar (Clean, no badges)
              GestureDetector(
                onTap: () {
                  if (sender != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OtherUserProfile(
                          userId: sender['id'],
                          username: sender['username'] ?? 'User',
                        ),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(avatar),
                  backgroundColor: Colors.grey[200],
                ),
              ),
              const SizedBox(width: 12),
              // Message Text & Time ago
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (type == 'follow' && sender != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherUserProfile(
                            userId: sender['id'],
                            username: sender['username'] ?? 'User',
                          ),
                        ),
                      );
                    } else if ((type == 'like' || type == 'comment') && notification['poem_id'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            poem: {
                              'id': notification['poem_id'],
                              'title': notification['poem'] != null ? notification['poem']['title'] : 'Poem',
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationText(notification),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(notification['date_created']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Action Button on the far right
              if (type == 'follow') ...[
                // Follow Back / Following Button
                ElevatedButton(
                  onPressed: () => _toggleFollow(notification),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: isFollowing ? Colors.grey.shade200 : maroon,
                    foregroundColor: isFollowing ? Colors.grey.shade700 : Colors.white,
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow back',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ] else if (type == 'comment') ...[
                // Reply Button
                OutlinedButton(
                  onPressed: () {
                    if (notification['poem_id'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            poem: {
                              'id': notification['poem_id'],
                              'title': notification['poem'] != null ? notification['poem']['title'] : 'Poem',
                            },
                          ),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: maroon.withOpacity(0.4)),
                    minimumSize: const Size(64, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Reply',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: maroon),
                  ),
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFFDE8E8)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    final List<Widget> children = [];

    if (todayNotifications.isNotEmpty) {
      children.add(_buildSectionHeader('Today'));
      children.addAll(todayNotifications.map((n) => _buildNotificationRow(n)));
    }

    if (thisWeekNotifications.isNotEmpty) {
      children.add(_buildSectionHeader('This Week'));
      children.addAll(thisWeekNotifications.map((n) => _buildNotificationRow(n)));
    }

    if (earlierNotifications.isNotEmpty) {
      children.add(_buildSectionHeader('Earlier'));
      children.addAll(earlierNotifications.map((n) => _buildNotificationRow(n)));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Premium Header
          Padding(
            padding: const EdgeInsets.only(top: 24.0, bottom: 16.0, left: 24.0, right: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  T.s("notification"),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    color: Colors.black87,
                  ),
                ),
                if (_notifications.isNotEmpty)
                  GestureDetector(
                    onTap: _fetchNotifications,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.refresh, color: Colors.grey.shade700, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF2D1D1)),
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: maroon, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: Color(0xFFF29C38), shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/notificationerror.png',
            width: 250,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.notifications_off_outlined,
              size: 100,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            T.s("no_notif"),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              T.s("no_notif_desc"),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.5),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}