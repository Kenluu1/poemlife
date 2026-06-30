import 'package:flutter/material.dart';
import 'package:poemlife/API.dart';
import 'package:poemlife/detailpage.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final Color maroon = const Color(0xFFA33B3B);
  final Color orange = const Color(0xFFF29C38);

  bool _isLoading = true;
  List<Map<String, dynamic>> _favoritePoems = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });
    final list = await ApiService().getBookmarks();
    if (mounted) {
      setState(() {
        _favoritePoems = (list ?? []).map((item) {
          if (item['poem'] != null && item['poem'] is Map) {
            final poemData = Map<String, dynamic>.from(item['poem'] as Map);
            // Also preserve the bookmark status
            poemData['is_bookmarked'] = 1;
            return poemData;
          }
          return item;
        }).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(int poemId) async {
    setState(() {
      _favoritePoems.removeWhere((p) => p['id'] == poemId);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "remove from favourite",
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        backgroundColor: maroon,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    await ApiService().toggleBookmark(poemId, true);
  }

  Widget _buildLoadingView() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: maroon, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: orange, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/empty.png',
            height: 200,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "No Favorite Poem",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Come back here to see your favorite poems",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _favoritePoems.length,
      itemBuilder: (context, index) {
        final poem = _favoritePoems[index];
        final title = poem['title'] ?? 'Untitled';
        final authorName = (poem['author'] != null && poem['author'] is Map)
            ? poem['author']['username'] ?? 'Anonymous'
            : poem['author']?.toString() ?? 'Anonymous';
        final loveCount = poem['love_count']?.toString() ?? '0';
        final commentCount = poem['comment_count']?.toString() ?? '0';
        final String avatarUrl = (poem['authorImage'] != null && poem['authorImage'].toString().isNotEmpty)
            ? poem['authorImage'].toString()
            : ((poem['author'] != null && poem['author'] is Map && poem['author']['image'] != null)
                ? poem['author']['image'].toString()
                : 'https://i.pravatar.cc/150?img=10');

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
            border: Border.all(color: Colors.red.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: Colors.grey[200],
                    onBackgroundImageError: (_, __) {},
                    child: const Icon(Icons.person, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
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
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(
                        poem: poem,
                      ),
                    ),
                  );
                  _loadFavorites();
                },
                child: Text(
                  "Read More",
                  style: TextStyle(
                    color: maroon,
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
                      Icon(Icons.favorite, size: 18, color: maroon),
                      const SizedBox(width: 4),
                      Text(loveCount, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 16),
                      Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(commentCount, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.bookmark,
                      size: 20,
                      color: maroon,
                    ),
                    onPressed: () => _removeBookmark(poem['id']),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = _buildLoadingView();
    } else if (_favoritePoems.isEmpty) {
      body = _buildEmptyStateView();
    } else {
      body = _buildFavoritesList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Favorite",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }
}