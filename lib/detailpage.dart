import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poemlife/API.dart';
import 'package:poemlife/otheruserprofile.dart';
import 'translation.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> poem;

  const DetailPage({
    super.key,
    required this.poem,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final Color maroon = const Color(0xFFA33B3B);
  final TextEditingController _commentController = TextEditingController();

  String _followStatus = 'idle'; // 'idle', 'loading', 'following'
  bool _isLiked = false;
  int _loveCount = 0;
  bool _isBookmarked = false;
  Set<String> _likedCommentIds = {};
  Map<String, dynamic>? _replyingToComment;

  String _currentUsername = "User";
  String _avatarUrl = "https://i.pravatar.cc/150?img=11";
  int? _currentUserId;

  List<Map<String, dynamic>> _comments = [];
  late Map<String, dynamic> _poem;

  @override
  void initState() {
    super.initState();
    _poem = Map<String, dynamic>.from(widget.poem);
    _isLiked = _poem['is_liked'] == true;
    _loveCount = int.tryParse(_poem['love_count']?.toString() ?? '0') ?? 0;
    _isBookmarked = _poem['is_bookmarked'] == 1 || _poem['bookmarked'] == 1;
    _loadUserProfile();
    _loadComments();
    _loadPoemDetail();
    ApiService.followEvents.addListener(_onFollowEvent);
  }

  Future<void> _loadPoemDetail() async {
    final poemId = _poem['id'];
    if (poemId != null) {
      final detail = await ApiService().getPoemDetail(poemId);
      if (detail != null && mounted) {
        setState(() {
          _poem = detail;
          _isLiked = _poem['is_liked'] == true;
          _loveCount = int.tryParse(_poem['love_count']?.toString() ?? '0') ?? 0;
          _isBookmarked = _poem['is_bookmarked'] == 1 || _poem['bookmarked'] == 1;
        });
        _loadFollowStatus();
      }
    }
  }

  void _onFollowEvent() {
    _loadFollowStatus();
  }

  Future<void> _loadComments() async {
    final poemId = _poem['id'];
    if (poemId == null) {
      return;
    }
    final fetched = await ApiService().getComments(poemId);

    if (fetched != null && mounted) {
      setState(() {
        _comments = fetched
            .map((c) {
              final List<dynamic> apiReplies = c['replies'] ?? [];
              final List<dynamic> mappedApiReplies = apiReplies
                  .map((r) {
                    return {
                      'id': r['id'],
                      'author': r['author'] != null && r['author'] is Map ? r['author']['username'] ?? 'Anonymous' : 'Anonymous',
                      'authorId': r['author'] != null && r['author'] is Map ? r['author']['id'] : null,
                      'time': r['date_created'] != null ? "${DateTime.parse(r['date_created']).day}/${DateTime.parse(r['date_created']).month}" : 'Just now',
                      'text': r['comment'] ?? r['text'] ?? '',
                      'avatar': r['author'] != null && r['author'] is Map && r['author']['image'] != null
                          ? r['author']['image'].toString()
                          : 'https://i.pravatar.cc/150?img=32',
                    };
                  })
                  .where((r) => r['author'] != null &&
                      !(r['author'].toString().toLowerCase().contains('anonymous') ||
                        r['author'].toString().toLowerCase().contains('anonymus')))
                  .toList();

              return {
                'id': c['id'],
                'author': c['author'] != null && c['author'] is Map ? c['author']['username'] ?? 'Anonymous' : 'Anonymous',
                'authorId': c['author'] != null && c['author'] is Map ? c['author']['id'] : null,
                'time': c['date_created'] != null ? "${DateTime.parse(c['date_created']).day}/${DateTime.parse(c['date_created']).month}" : 'Just now',
                'text': c['comment'] ?? '',
                'avatar': c['author'] != null && c['author'] is Map && c['author']['image'] != null
                    ? c['author']['image'].toString()
                    : 'https://i.pravatar.cc/150?img=32',
                'replies': mappedApiReplies
              };
            })
            .where((c) => c['author'] != null &&
                !(c['author'].toString().toLowerCase().contains('anonymous') ||
                  c['author'].toString().toLowerCase().contains('anonymus')))
            .toList();
      });
    } else if (mounted) {
      setState(() {
        _comments = [];
      });
    }
  }

  @override
  void dispose() {
    ApiService.followEvents.removeListener(_onFollowEvent);
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getInt('userId');
    if (savedUserId != null) {
      _currentUserId = savedUserId;
      final profile = await ApiService().getUserProfile(savedUserId);
      if (profile != null && mounted) {
        setState(() {
          _currentUsername = profile['username'] ?? 'User';
          _avatarUrl = (profile['image'] != null && profile['image'].toString().isNotEmpty)
              ? profile['image'].toString()
              : 'https://i.pravatar.cc/150?img=11';
        });
      }
    }
    final likedComments = prefs.getStringList('liked_comment_ids') ?? [];
    if (mounted) {
      setState(() {
        _likedCommentIds = likedComments.toSet();
      });
    }
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    final authorId = _poem['authorId'] ??
        ((_poem['author'] != null && _poem['author'] is Map)
            ? _poem['author']['id']
            : null);
    if (authorId != null && authorId != _currentUserId) {
      final authorProfile = await ApiService().getUserProfile(authorId);
      if (authorProfile != null && mounted) {
        setState(() {
          _followStatus = authorProfile['is_following'] == true ? 'following' : 'idle';
        });
      }
    }
  }

  void _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final poemId = _poem['id'];
    if (poemId != null) {
      if (_replyingToComment != null) {
        final parentId = _replyingToComment!['id'];
        final newReply = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'author': _currentUsername,
          'authorId': _currentUserId,
          'time': 'Just now',
          'text': text,
          'avatar': _avatarUrl,
        };

        setState(() {
          for (var comment in _comments) {
            if (comment['id'] == parentId) {
              comment['replies'] = [...(comment['replies'] ?? []), newReply];
              break;
            }
          }
          _commentController.clear();
          _replyingToComment = null;
        });

        final success = await ApiService().createComment(poemId, text, parentCommentId: parentId);
        if (success) {
          _loadComments();
        }
      } else {
        setState(() {
          _comments.add({
            'id': DateTime.now().millisecondsSinceEpoch,
            'author': _currentUsername,
            'authorId': _currentUserId,
            'time': 'Just now',
            'text': text,
            'avatar': _avatarUrl,
          });
          _commentController.clear();
        });

        final success = await ApiService().createComment(poemId, text);
        if (success) {
          _loadComments();
        }
      }
    }
  }

  void _showActionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final String authorUsername = (_poem['author'] != null && _poem['author'] is Map)
                       ? _poem['author']['username'] ?? 'Anonymous'
                       : _poem['author']?.toString() ?? 'Anonymous';
                  
                  final prefs = await SharedPreferences.getInstance();
                  List<String> blocked = prefs.getStringList('blocked_users') ?? [];
                  if (!blocked.contains(authorUsername)) {
                    blocked.add(authorUsername);
                    await prefs.setStringList('blocked_users', blocked);
                  }
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$authorUsername has been blocked"),
                      backgroundColor: maroon,
                    ),
                  );
                  Navigator.pop(context, {'action': 'reload'});
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      T.s("block"),
                      style: const TextStyle(
                        color: Color(0xFF993B3B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF2D1D1)),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final poemId = widget.poem['id'];
                  if (poemId != null) {
                    final prefs = await SharedPreferences.getInstance();
                    List<String> reported = prefs.getStringList('reported_poems') ?? [];
                    final String poemIdStr = poemId.toString();
                    if (!reported.contains(poemIdStr)) {
                      reported.add(poemIdStr);
                      await prefs.setStringList('reported_poems', reported);
                    }
                  }
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Post reported successfully"),
                      backgroundColor: maroon,
                    ),
                  );
                  Navigator.pop(context, {'action': 'reload'});
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      T.s("report"),
                      style: const TextStyle(
                        color: Color(0xFF993B3B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF2D1D1)),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final String authorUsername = (_poem['author'] != null && _poem['author'] is Map)
                       ? _poem['author']['username'] ?? 'Anonymous'
                       : _poem['author']?.toString() ?? 'Anonymous';
                  
                  final prefs = await SharedPreferences.getInstance();
                  List<String> muted = prefs.getStringList('muted_users') ?? [];
                  if (!muted.contains(authorUsername)) {
                    muted.add(authorUsername);
                    await prefs.setStringList('muted_users', muted);
                  }
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Notifications from $authorUsername muted"),
                      backgroundColor: Colors.black87,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      T.s("mute"),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF2D1D1)),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  final poemId = widget.poem['id'];
                  if (poemId != null) {
                    final prefs = await SharedPreferences.getInstance();
                    List<String> sharedJson = prefs.getStringList('shared_empathy_poems') ?? [];
                    
                    bool alreadyShared = false;
                    for (var s in sharedJson) {
                      try {
                        final parsed = jsonDecode(s);
                        if (parsed['id'] == poemId) {
                          alreadyShared = true;
                          break;
                        }
                      } catch (_) {}
                    }
                    
                    if (!alreadyShared) {
                      sharedJson.add(jsonEncode(_poem));
                      await prefs.setStringList('shared_empathy_poems', sharedJson);
                    }
                  }
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("shared to empathy"),
                      backgroundColor: Colors.black87,
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      T.s("share"),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _getCategoryName(int? categoryId) {
    switch (categoryId) {
      case 1:
        return T.s("sadness");
      case 2:
        return T.s("happiness");
      case 3:
        return T.s("angry");
      default:
        return T.s("poem");
    }
  }

  int get _totalCommentsCount {
    int count = 0;
    for (var c in _comments) {
      count++;
      if (c['replies'] != null) {
        count += (c['replies'] as List).length;
      }
    }
    return count;
  }

  Future<void> _toggleFollow() async {
    final authorId = widget.poem['authorId'];
    if (authorId == null || authorId == _currentUserId) return;

    final String originalStatus = _followStatus;
    final String nextStatus = _followStatus == 'following' ? 'idle' : 'following';

    setState(() {
      _followStatus = nextStatus;
    });

    bool success = false;
    if (nextStatus == 'following') {
      success = await ApiService().followUser(authorId);
    } else {
      success = await ApiService().unfollowUser(authorId);
    }

    if (mounted && !success) {
      setState(() {
        _followStatus = originalStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update follow status')),
      );
    }
  }

  Widget _buildFollowButton() {
    final authorId = widget.poem['authorId'];
    if (authorId == null || authorId == _currentUserId) {
      return const SizedBox.shrink();
    }

    if (_followStatus == 'following') {
      return GestureDetector(
        onTap: _toggleFollow,
        child: Container(
          width: 80,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              "Following",
              style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: _toggleFollow,
        child: Container(
          width: 80,
          height: 32,
          decoration: BoxDecoration(
            color: maroon,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              "Follow",
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildReactionsRow() {
    return Row(
      children: [
        Icon(Icons.language, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        const Text("394", style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 16),

        GestureDetector(
          onTap: () async {
            final bool currentlyLiked = _isLiked;
            setState(() {
              _isLiked = !currentlyLiked;
              if (_isLiked) {
                _loveCount++;
              } else {
                _loveCount--;
              }
            });
            bool success = await ApiService().toggleReaction(_poem['id'], 1);
            if (!success) {
              setState(() {
                _isLiked = currentlyLiked;
                if (_isLiked) {
                  _loveCount++;
                } else {
                  _loveCount--;
                }
              });
            }
          },
          child: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: _isLiked ? maroon : Colors.grey,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _loveCount.toString(),
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(width: 16),

        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          _totalCommentsCount.toString(),
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const Spacer(),

        GestureDetector(
          onTap: () async {
            final previousState = _isBookmarked;
            final nextState = !previousState;
            setState(() {
              _isBookmarked = nextState;
            });

            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  nextState ? T.s("added_to_bookmark") : T.s("removed_from_bookmark"),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                backgroundColor: const Color(0xFFA33B3B),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );

            bool success = await ApiService().toggleBookmark(_poem['id'], previousState);
            if (!success) {
              setState(() {
                _isBookmarked = previousState;
              });
            }
          },
          child: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            size: 20,
            color: _isBookmarked ? maroon : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> item, {required int parentCommentId}) {
    final author = item['author'] ?? '';
    final time = item['time'] ?? '';
    final text = item['text'] ?? '';
    final avatar = item['avatar'] ?? '';
    final String commentIdStr = (item['id'] ?? '').toString();
    final bool isCommentLiked = _likedCommentIds.contains(commentIdStr);
    final int? poemAuthorId = (_poem['authorId'] != null)
        ? int.tryParse(_poem['authorId'].toString())
        : ((_poem['author'] != null && _poem['author'] is Map && _poem['author']['id'] != null)
            ? int.tryParse(_poem['author']['id'].toString())
            : null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final authorId = item['authorId'];
            if (authorId != null && authorId != _currentUserId) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherUserProfile(
                    userId: authorId,
                    username: author,
                  ),
                ),
              );
            }
          },
          child: CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(avatar),
            backgroundColor: Colors.grey[200],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final authorId = item['authorId'];
                      if (authorId != null && authorId != _currentUserId) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherUserProfile(
                              userId: authorId,
                              username: author,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      author,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.language, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  const Text("1k", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        if (_likedCommentIds.contains(commentIdStr)) {
                          _likedCommentIds.remove(commentIdStr);
                        } else {
                          _likedCommentIds.add(commentIdStr);
                        }
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList('liked_comment_ids', _likedCommentIds.toList());
                    },
                    child: Row(
                      children: [
                        Icon(
                          isCommentLiked ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: isCommentLiked ? maroon : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCommentLiked ? "1" : "0",
                          style: TextStyle(
                            fontSize: 11,
                            color: isCommentLiked ? maroon : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (poemAuthorId != null && poemAuthorId == _currentUserId) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToComment = {
                            'id': parentCommentId,
                            'author': author,
                          };
                        });
                      },
                      child: Text(
                        "Reply",
                        style: TextStyle(color: maroon, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommentItem(comment, parentCommentId: comment['id']),
            if (comment['replies'] != null)
              ...((comment['replies'] as List).map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(left: 36.0, top: 12.0),
                  child: _buildCommentItem(reply as Map<String, dynamic>, parentCommentId: comment['id']),
                );
              })),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildCommentInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(_avatarUrl),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.red.shade100, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: _replyingToComment != null
                            ? "${T.s("reply_to")}${_replyingToComment!['author']}..."
                            : T.s("comment_hint"),
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addComment,
                    child: const Icon(
                      Icons.send,
                      color: Color(0xFF993B3B),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _poem['title'] ?? 'Untitled';
    final content = _poem['content'] ?? '';
    final username = (_poem['author'] != null && _poem['author'] is Map)
        ? _poem['author']['username'] ?? 'Anonymous'
        : _poem['author']?.toString() ?? 'Anonymous';
    final avatarUrl = _poem['authorImage'] ??
        ((_poem['author'] != null && _poem['author'] is Map)
            ? _poem['author']['image']
            : null);
    final categoryId = (_poem['category_id'] ?? _poem['categoryId']) as int?;
    final int? poemAuthorId = (_poem['authorId'] != null)
        ? int.tryParse(_poem['authorId'].toString())
        : ((_poem['author'] != null && _poem['author'] is Map && _poem['author']['id'] != null)
            ? int.tryParse(_poem['author']['id'].toString())
            : null);

    List<dynamic> categoriesList = [];
    if (_poem['categories'] != null) {
      categoriesList = _poem['categories'] as List<dynamic>;
    } else {
      categoriesList = [
        {'name': _getCategoryName(categoryId)}
      ];
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, {
          'is_liked': _isLiked,
          'love_count': _loveCount,
          'is_bookmarked': _isBookmarked ? 1 : 0,
          'comment_count': _totalCommentsCount,
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context, {
              'is_liked': _isLiked,
              'love_count': _loveCount,
              'is_bookmarked': _isBookmarked ? 1 : 0,
              'comment_count': _totalCommentsCount,
            }),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black87),
              onPressed: _showActionsMenu,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red[200]!, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final authorId = _poem['authorId'] ??
                                      ((_poem['author'] != null && _poem['author'] is Map)
                                          ? _poem['author']['id']
                                          : null);
                                  if (authorId != null && authorId != _currentUserId) {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OtherUserProfile(
                                          userId: authorId,
                                          username: username,
                                        ),
                                      ),
                                    );
                                    if (result == 'reload') {
                                      Navigator.pop(context, {'action': 'reload'});
                                    }
                                  }
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                      backgroundColor: Colors.grey[200],
                                      child: avatarUrl == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const Text(
                                          "15 hours ago",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _buildFollowButton(),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Center(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'serif',
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Container(
                            width: double.infinity,
                            child: Text(
                              T.getCleanContent(content),
                              textAlign: T.getTextAlign(content),
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.8,
                                  fontFamily: 'serif',
                                  color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 30),

                          if (categoriesList.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: categoriesList.map((category) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    category['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          _buildReactionsRow(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      T.s("comment"),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    _buildCommentList(),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReplyingBanner(),
                _buildCommentInputBar(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyingBanner() {
    if (_replyingToComment == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Text(
            "${T.s("reply_to")}${_replyingToComment!['author']}",
            style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _replyingToComment = null;
              });
            },
            child: const Icon(Icons.close, size: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
