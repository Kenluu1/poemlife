import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poemlife/API.dart';
import 'package:poemlife/otheruserprofile.dart';
import 'translation.dart';
import 'detailpage.dart';

class PopularPoemsPage extends StatefulWidget {
  const PopularPoemsPage({super.key});

  @override
  State<PopularPoemsPage> createState() => _PopularPoemsPageState();
}

class _PopularPoemsPageState extends State<PopularPoemsPage> {
  final Color maroon = const Color(0xFFA33B3B);
  bool _isLoading = true;
  List<dynamic> _poems = [];
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadPopularPoems();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getInt('userId');
      });
    }
  }

  Future<void> _loadPopularPoems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService().getPoems(type: 'popular_search');
      if (mounted) {
        setState(() {
          _poems = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading popular poems: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getRelativeDate(String? dateStr) {
    if (dateStr == null) return 'Just now';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inDays >= 7) {
        return "${date.day}/${date.month}/${date.year}";
      } else if (diff.inDays >= 1) {
        return diff.inDays == 1 ? "1 day ago" : "${diff.inDays} days ago";
      } else if (diff.inHours >= 1) {
        return diff.inHours == 1 ? "1 hour ago" : "${diff.inHours} hours ago";
      } else if (diff.inMinutes >= 1) {
        return diff.inMinutes == 1 ? "1 minute ago" : "${diff.inMinutes} minutes ago";
      } else {
        return 'Just now';
      }
    } catch (_) {
      return 'Just now';
    }
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularPoemCard(Map<String, dynamic> poem, int index) {
    final title = poem['title'] ?? 'Untitled';
    final author = poem['author'] ?? 'Anonymous';
    final isBookmarked = poem['is_bookmarked'] == 1;
    final String avatarUrl = (poem['authorImage'] != null && poem['authorImage'].toString().isNotEmpty)
        ? poem['authorImage'].toString()
        : 'https://i.pravatar.cc/150?img=${index + 12}';

    final String dateStr = _getRelativeDate(poem['date_created']);
    final rawContent = T.getCleanContent(poem['content'] ?? '');
    final lines = rawContent.split('\n');
    final contentSnippet = lines.take(3).join('\n');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100, width: 1.5),
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
              if (poem['authorId'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherUserProfile(
                      userId: poem['authorId'],
                      username: author,
                    ),
                  ),
                );
              }
            },
            child: Row(
              children: [
                poem['authorId'] == _currentUserId
                    ? ValueListenableBuilder<String?>(
                        valueListenable: ApiService.currentUserAvatar,
                        builder: (context, currentAvatar, _) {
                          final baseAvatar = (currentAvatar != null && currentAvatar.isNotEmpty)
                              ? currentAvatar
                              : avatarUrl;
                          final displayUrl = baseAvatar.contains('?')
                              ? '$baseAvatar&v=${ApiService.currentUserAvatarVersion.value}'
                              : '$baseAvatar?v=${ApiService.currentUserAvatarVersion.value}';
                          return CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: NetworkImage(displayUrl),
                            onBackgroundImageError: (_, __) {},
                          );
                        },
                      )
                    : CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: NetworkImage(avatarUrl),
                        onBackgroundImageError: (_, __) {},
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
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'serif', color: Colors.black),
          ),
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
                setState(() {
                  poem['is_liked'] = result['is_liked'];
                  poem['love_count'] = result['love_count'];
                  poem['is_empathized'] = result['is_empathized'];
                  poem['has_empathy_reaction'] = result['has_empathy_reaction'];
                  poem['empathy_count'] = result['empathy_count'];
                  poem['is_bookmarked'] = result['is_bookmarked'];
                  poem['comment_count'] = result['comment_count'];
                });
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
                  EmpathyIcon(
                    isEmpathized: poem['is_empathized'] == true || poem['has_empathy_reaction'] == true || poem['has_empathy_reaction'] == 1,
                    size: 18,
                    onTap: () async {
                      final bool currentlyEmpathized = poem['is_empathized'] == true || poem['has_empathy_reaction'] == true || poem['has_empathy_reaction'] == 1;
                      final int currentCount = int.tryParse((poem['empathy_count'] ?? poem['empathies'] ?? 0).toString()) ?? 0;
                      final nextState = !currentlyEmpathized;
                      final nextCount = nextState ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0);
                      setState(() {
                        poem['is_empathized'] = nextState;
                        poem['has_empathy_reaction'] = nextState;
                        poem['empathy_count'] = nextCount;
                      });
                      ApiService.notifyReaction({
                        'poem_id': poem['id'],
                        'is_empathized': nextState,
                        'has_empathy_reaction': nextState,
                        'empathy_count': nextCount,
                      });
                      bool success = await ApiService().toggleReaction(poem['id'], 2);
                      if (!success) {
                        setState(() {
                          poem['is_empathized'] = currentlyEmpathized;
                          poem['has_empathy_reaction'] = currentlyEmpathized;
                          poem['empathy_count'] = currentCount;
                        });
                        ApiService.notifyReaction({
                          'poem_id': poem['id'],
                          'is_empathized': currentlyEmpathized,
                          'has_empathy_reaction': currentlyEmpathized,
                          'empathy_count': currentCount,
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (poem['empathy_count'] ?? poem['empathies'] ?? 0).toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                  bool success = await ApiService().toggleBookmark(poem['id'], !nextState);
                  if (!success) {
                    setState(() {
                      poem['is_bookmarked'] = isBookmarked ? 1 : 0;
                    });
                  }
                },
              ),
            ],
          ),
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
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          T.s('popular_poems'),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _poems.isEmpty
              ? Center(
                  child: Text(
                    T.s('no_results'),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPopularPoems,
                  color: maroon,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _poems.length,
                    itemBuilder: (context, index) {
                      final poem = Map<String, dynamic>.from(_poems[index]);
                      return _buildPopularPoemCard(poem, index);
                    },
                  ),
                ),
    );
  }
}
