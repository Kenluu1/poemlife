import 'package:shared_preferences/shared_preferences.dart';
import 'package:poemlife/detailpage.dart';
import 'package:flutter/material.dart';
import 'package:poemlife/API.dart';
import 'package:poemlife/otheruserprofile.dart';

class AngryPage extends StatefulWidget {
  const AngryPage({super.key});

  @override
  State<AngryPage> createState() => _AngryPageState();
}

class _AngryPageState extends State<AngryPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<dynamic> _poems = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadPoems();
  }

  Future<void> _loadPoems() async {
    final fetchedPoems = await ApiService().getPoems(categoryId: 3);
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId');
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];
    final reportedPoems = prefs.getStringList('reported_poems') ?? [];

    final filtered = fetchedPoems.where((p) {
      final String author = p['author'] ?? '';
      final String idStr = (p['id'] ?? '').toString();
      return !blockedUsers.contains(author) && !reportedPoems.contains(idStr);
    }).toList();

    if (mounted) {
      setState(() {
        _poems = filtered;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadPoems();
    setState(() => _isRefreshing = false);
  }

  Widget _buildCustomLoadingDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF993B3B), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFF29C38), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Angry Poems',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading ? _buildSkeletonView() : _buildContentView(),
    );
  }

  Widget _buildSkeletonView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSkeletonBox(height: 180),
        const SizedBox(height: 20),
        _buildSkeletonBox(height: 280),
      ],
    );
  }

  Widget _buildSkeletonBox({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildContentView() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.transparent,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          if (_isRefreshing) _buildCustomLoadingDots(),
          // Header Image Angry
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFADBD8),
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage('assets/3.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_poems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Text(
                  "No poems found in this category",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            ..._poems.map((poem) => _buildPoemCard(poem as Map<String, dynamic>, Colors.red[800]!)),
        ],
      ),
    );
  }

  Widget _buildPoemCard(Map<String, dynamic> poem, Color borderColor) {
    final title = poem['title'] ?? 'Untitled';
    final author = poem['author'] ?? 'Anonymous';
    final isBookmarked = poem['is_bookmarked'] == 1;
    final String avatarUrl = (poem['authorImage'] != null && poem['authorImage'].toString().isNotEmpty)
        ? poem['authorImage'].toString()
        : 'https://i.pravatar.cc/150?img=10';
    
    String dateStr = 'Just now';
    if (poem['date_created'] != null) {
      try {
        final date = DateTime.parse(poem['date_created']);
        dateStr = "${date.day}/${date.month}/${date.year}";
      } catch (_) {}
    }

    final rawContent = poem['content'] ?? '';
    final lines = rawContent.split('\n');
    final contentSnippet = lines.take(4).join('\n');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              if (poem['authorId'] != null && poem['authorId'] != _currentUserId) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherUserProfile(
                      userId: poem['authorId'],
                      username: author,
                    ),
                  ),
                );
                if (result == 'reload') {
                  _loadPoems();
                }
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(avatarUrl),
                  backgroundColor: Colors.grey.shade200,
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(author, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'serif', color: Colors.black)),
          const SizedBox(height: 12),
          Text(
            contentSnippet,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(
                    poem: poem,
                  ),
                ),
              );
              if (result != null && result is Map<String, dynamic> && mounted) {
                if (result['action'] == 'reload') {
                  _loadPoems();
                } else {
                  setState(() {
                    poem['is_liked'] = result['is_liked'];
                    poem['love_count'] = result['love_count'];
                    poem['is_bookmarked'] = result['is_bookmarked'];
                    poem['comment_count'] = result['comment_count'];
                  });
                }
              } else {
                _loadPoems();
              }
            },
            child: const Text(
              "Read More",
              style: TextStyle(
                color: Color(0xFF993B3B),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.language, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  const Text("394", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () async {
                      final bool currentlyLiked = poem['is_liked'] == true;
                      setState(() {
                        poem['is_liked'] = !currentlyLiked;
                        int currentCount = int.tryParse(poem['love_count']?.toString() ?? '0') ?? 0;
                        if (poem['is_liked']) {
                          poem['love_count'] = currentCount + 1;
                        } else {
                          poem['love_count'] = currentCount - 1;
                        }
                      });
                      bool success = await ApiService().toggleReaction(poem['id'], 1);
                      if (!success) {
                        setState(() {
                          poem['is_liked'] = currentlyLiked;
                          int currentCount = int.tryParse(poem['love_count']?.toString() ?? '0') ?? 0;
                          if (poem['is_liked']) {
                            poem['love_count'] = currentCount + 1;
                          } else {
                            poem['love_count'] = currentCount - 1;
                          }
                        });
                      }
                    },
                    child: Icon(
                      poem['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: poem['is_liked'] == true ? const Color(0xFF993B3B) : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (poem['love_count'] ?? '0').toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    (poem['comment_count'] ?? '0').toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                  color: isBookmarked ? const Color(0xFF993B3B) : Colors.grey,
                ),
                onPressed: () async {
                  final bool nextState = !isBookmarked;
                  setState(() {
                    poem['is_bookmarked'] = nextState ? 1 : 0;
                  });

                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        nextState ? "added to favourite page" : "remove from favourite",
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );

                  bool success = await ApiService().toggleBookmark(poem['id'], isBookmarked);
                  if (!success) {
                    setState(() {
                      poem['is_bookmarked'] = isBookmarked ? 1 : 0;
                    });
                  }
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}