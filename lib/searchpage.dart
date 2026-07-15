import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poemlife/API.dart';
import 'package:poemlife/otheruserprofile.dart';
import 'package:poemlife/topwriterspage.dart';
import 'package:poemlife/popularpoemspage.dart';
import 'detailpage.dart';
import 'translation.dart';

enum SearchPhase { initial, loadingDots, skeleton, results, notFound }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Color maroon = const Color(0xFFA33B3B);
  final Color skeletonGrey = Colors.grey.shade200;

  SearchPhase currentPhase = SearchPhase.initial;
  Timer? _debounce;
  bool _isPageLoading = true;
  bool _isFocused = false;

  List<dynamic> _topWriters = [];
  List<dynamic> _popularPoems = [];
  int? _currentUserId;

  // Search results
  List<dynamic> _searchResultsPoems = [];
  List<dynamic> _searchResultsUsers = [];

  // Recent searches local history
  List<Map<String, dynamic>> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadLandingData();
    _loadRecentSearches();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isFocused = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchTextChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isEmpty) {
        setState(() {
          currentPhase = SearchPhase.initial;
          _searchResultsPoems = [];
          _searchResultsUsers = [];
        });
        return;
      }
      _performSearchSilent(query.trim());
    });
  }

  void _performSearchSilent(String query) async {
    try {
      final results = await Future.wait([
        ApiService().getPoems(search: query),
        ApiService().searchUsers(query),
      ]);

      final poems = results[0];
      final users = results[1];

      if (!mounted) return;

      setState(() {
        _searchResultsPoems = poems;
        _searchResultsUsers = users;

        if (poems.isEmpty && users.isEmpty) {
          currentPhase = SearchPhase.notFound;
        } else {
          currentPhase = SearchPhase.results;
        }
      });
    } catch (e) {
      print('Error performing silent search: $e');
    }
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getInt('userId');
      });
    }
  }

  Future<void> _loadLandingData() async {
    if (!mounted) return;
    setState(() {
      _isPageLoading = true;
    });

    try {
      final writers = await ApiService().getTopWriters();
      final poems = await ApiService().getPoems(type: 'popular_search');

      if (mounted) {
        setState(() {
          _topWriters = writers;
          _popularPoems = poems;
          _isPageLoading = false;
        });
      }
    } catch (e) {
      print('Error loading landing data: $e');
      if (mounted) {
        setState(() {
          _isPageLoading = false;
        });
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');
    final String key = userId != null ? 'recent_searches_$userId' : 'recent_searches_guest';

    // One-time clear of existing history to make it look empty as requested
    final bool cleared = prefs.getBool('history_cleared_v2') ?? false;
    if (!cleared) {
      await prefs.remove(key);
      await prefs.setBool('history_cleared_v2', true);
    }

    final jsonStr = prefs.getString(key);
    if (jsonStr != null) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          if (mounted) {
            setState(() {
              _recentSearches = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
            });
          }
        }
      } catch (e) {
        print('Error parsing recent searches: $e');
      }
    } else {
      if (mounted) {
        setState(() {
          _recentSearches = [];
        });
      }
    }
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('userId');
    final String key = userId != null ? 'recent_searches_$userId' : 'recent_searches_guest';
    await prefs.setString(key, jsonEncode(_recentSearches));
  }

  void _addRecentSearch(Map<String, dynamic> item) {
    setState(() {
      _recentSearches.removeWhere((element) {
        if (item['type'] == 'user' && element['type'] == 'user') {
          return element['id'] == item['id'];
        } else if (item['type'] == 'query' && element['type'] == 'query') {
          return element['query'].toString().toLowerCase() == item['query'].toString().toLowerCase();
        }
        return false;
      });
      _recentSearches.insert(0, item);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }
    });
    _saveRecentSearches();
  }

  void _deleteRecentSearch(int index) {
    setState(() {
      _recentSearches.removeAt(index);
    });
    _saveRecentSearches();
  }

  void _deleteAllRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
    _saveRecentSearches();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    _addRecentSearch({
      'type': 'query',
      'query': query.trim(),
    });

    _searchController.text = query;
    _focusNode.unfocus();
    setState(() {
      _isFocused = false;
      currentPhase = SearchPhase.loadingDots;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() => currentPhase = SearchPhase.skeleton);

    try {
      final results = await Future.wait([
        ApiService().getPoems(search: query),
        ApiService().searchUsers(query),
      ]);

      final poems = results[0];
      final users = results[1];

      if (!mounted) return;

      setState(() {
        _searchResultsPoems = poems;
        _searchResultsUsers = users;

        if (poems.isEmpty && users.isEmpty) {
          currentPhase = SearchPhase.notFound;
        } else {
          currentPhase = SearchPhase.results;
        }
      });
    } catch (e) {
      print('Error performing search: $e');
      if (mounted) {
        setState(() {
          currentPhase = SearchPhase.notFound;
        });
      }
    }
  }

  void _onUserTapped(dynamic user) {
    final Map<String, dynamic> userMap = Map<String, dynamic>.from(user);
    _addRecentSearch({
      'type': 'user',
      'id': userMap['id'],
      'username': userMap['username'],
      'fullname': userMap['fullname'],
      'image': userMap['image'],
      'followers_count': userMap['followers_count'],
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfile(
          userId: userMap['id'],
          username: userMap['username'] ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isPageLoading ? _buildPageSkeleton() : _buildBodyContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final bool showBackBtn = _isFocused || currentPhase != SearchPhase.initial;
    return Padding(
      padding: EdgeInsets.only(
        left: showBackBtn ? 8.0 : 20.0,
        right: 20.0,
        top: 16.0,
        bottom: 16.0,
      ),
      child: Row(
        children: [
          if (showBackBtn)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () {
                _focusNode.unfocus();
                setState(() {
                  _isFocused = false;
                  currentPhase = SearchPhase.initial;
                  _searchController.clear();
                });
              },
            ),
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: maroon.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                onChanged: _onSearchTextChanged,
                decoration: InputDecoration(
                  hintText: T.s('search_hint'),
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 100),
        children: [
          _buildSkeletonCard(),
          const SizedBox(height: 16),
          _buildSkeletonCard(),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: skeletonGrey,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isFocused && _searchController.text.trim().isEmpty) {
      return _buildRecentSearches();
    }

    switch (currentPhase) {
      case SearchPhase.initial:
        return _buildDefaultLanding();
      case SearchPhase.loadingDots:
        return _buildLoadingDots();
      case SearchPhase.skeleton:
        return _buildPageSkeleton();
      case SearchPhase.results:
        return _buildSearchResults();
      case SearchPhase.notFound:
        return _buildNotFound();
    }
  }

  Widget _buildDefaultLanding() {
    return RefreshIndicator(
      onRefresh: _loadLandingData,
      color: maroon,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 100),
        children: [
          _buildTopWritersSection(),
          const SizedBox(height: 24),
          _buildPopularsSection(),
        ],
      ),
    );
  }

  Widget _buildTopWritersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              T.s('top_writers'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TopWritersPage()),
                );
              },
              child: Text(
                T.s('see_all'),
                style: TextStyle(color: maroon, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _topWriters.isEmpty
            ? SizedBox(
                height: 95,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey.shade100,
                            child: Icon(Icons.person, size: 30, color: Colors.grey.shade300),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 50,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            : SizedBox(
                height: 95,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _topWriters.length,
                  itemBuilder: (context, index) {
                    final writer = _topWriters[index];
                    final String username = writer['fullname'] ?? writer['username'] ?? 'User';
                    final displayShortName = _getShortName(username);
                    final String avatarUrl = (writer['image'] != null && writer['image'].toString().isNotEmpty)
                        ? writer['image'].toString()
                        : 'https://i.pravatar.cc/150?img=${index + 10}';

                    return GestureDetector(
                      onTap: () => _onUserTapped(writer),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: NetworkImage(avatarUrl),
                              onBackgroundImageError: (_, __) {},
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayShortName,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  String _getShortName(String name) {
    final parts = name.split(' ');
    if (parts.length > 1) {
      final first = parts[0];
      final lastInitial = parts[1].isNotEmpty ? '${parts[1][0]}.' : '';
      return '$first $lastInitial';
    }
    return name;
  }

  Widget _buildPopularsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              T.s('popular'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PopularPoemsPage()),
                );
              },
              child: Text(
                T.s('see_all'),
                style: TextStyle(color: maroon, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _popularPoems.isEmpty
            ? Column(
                children: List.generate(2, (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Center(
                      child: Text(
                        'No popular poems yet',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      ),
                    ),
                  ),
                )),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _popularPoems.length,
                itemBuilder: (context, index) {
                  final poem = _popularPoems[index];
                  return _buildPopularPoemCard(Map<String, dynamic>.from(poem));
                },
              ),
      ],
    );
  }

  Widget _buildPopularPoemCard(Map<String, dynamic> poem) {
    final title = poem['title'] ?? 'Untitled';
    final author = poem['author'] ?? 'Anonymous';
    final isBookmarked = poem['is_bookmarked'] == 1;
    final String avatarUrl = (poem['authorImage'] != null && poem['authorImage'].toString().isNotEmpty)
        ? poem['authorImage'].toString()
        : 'https://i.pravatar.cc/150?img=12';

    String dateStr = 'Just now';
    if (poem['date_created'] != null) {
      try {
        final date = DateTime.parse(poem['date_created']).toLocal();
        final diff = DateTime.now().difference(date);
        if (diff.inDays >= 7) {
          dateStr = "${date.day}/${date.month}/${date.year}";
        } else if (diff.inDays >= 1) {
          dateStr = diff.inDays == 1 ? "1 day ago" : "${diff.inDays} days ago";
        } else if (diff.inHours >= 1) {
          dateStr = diff.inHours == 1 ? "1 hour ago" : "${diff.inHours} hours ago";
        } else if (diff.inMinutes >= 1) {
          dateStr = diff.inMinutes == 1 ? "1 minute ago" : "${diff.inMinutes} minutes ago";
        } else {
          dateStr = 'Just now';
        }
      } catch (_) {}
    }

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
              if (poem['authorId'] != null && poem['authorId'] != _currentUserId) {
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
                CircleAvatar(
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
                        nextState ? T.s("added_to_bookmark") : T.s("removed_from_bookmark"),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: const Color(0xFF993B3B),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );

                  bool success = await ApiService().toggleBookmark(poem['id'], !nextState);
                  if (!success && mounted) {
                    setState(() {
                      poem['is_bookmarked'] = nextState ? 0 : 1;
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

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(T.s('search_history'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            GestureDetector(
              onTap: _deleteAllRecentSearches,
              child: Text(T.s('clear_all'), style: TextStyle(color: maroon, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentSearches.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Text(
                T.s('no_results'),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ),
          )
        else
          ...List.generate(_recentSearches.length, (index) {
            final item = _recentSearches[index];
            final bool isUser = item['type'] == 'user';
            return _buildRecentItem(
              index: index,
              title: isUser ? item['fullname'] ?? item['username'] ?? 'User' : item['query'] ?? '',
              subtitle: isUser ? '${_formatFollowers(item['followers_count'])} ${T.s("followers").toLowerCase()}' : null,
              isUser: isUser,
              avatarUrl: isUser ? item['image'] : null,
              item: item,
            );
          }),
      ],
    );
  }

  String _formatFollowers(dynamic count) {
    final int val = int.tryParse(count?.toString() ?? '0') ?? 0;
    if (val >= 1000) {
      final double rb = val / 1000.0;
      if (rb == rb.toInt()) {
        return '${rb.toInt()}rb';
      } else {
        return '${rb.toStringAsFixed(1)}rb';
      }
    }
    return '$val';
  }

  Widget _buildRecentItem({
    required int index,
    required String title,
    String? subtitle,
    required bool isUser,
    String? avatarUrl,
    required Map<String, dynamic> item,
  }) {
    return GestureDetector(
      onTap: () {
        if (isUser) {
          _onUserTapped(item);
        } else {
          _performSearch(item['query']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: maroon.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            isUser
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    backgroundColor: Colors.grey.shade200,
                    onBackgroundImageError: (_, __) {},
                    child: avatarUrl == null || avatarUrl.isEmpty ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                  )
                : Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(Icons.search, color: Colors.grey.shade500, size: 16),
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ]
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _deleteRecentSearch(index),
              child: Icon(Icons.close, color: Colors.grey.shade600, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: maroon, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
      children: [
        if (_searchResultsUsers.isNotEmpty) ...[
          const Text(
            'Users',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResultsUsers.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> user = Map<String, dynamic>.from(_searchResultsUsers[index]);
              final String username = user['fullname'] ?? user['username'] ?? 'User';
              final String avatarUrl = (user['image'] != null && user['image'].toString().isNotEmpty)
                  ? user['image'].toString()
                  : 'https://i.pravatar.cc/150?img=${index + 5}';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: maroon.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: NetworkImage(avatarUrl),
                      onBackgroundImageError: (_, __) {},
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                          Text('${_formatFollowers(user['followers_count'])} ${T.s("followers").toLowerCase()}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maroon,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        minimumSize: const Size(60, 30),
                        elevation: 0,
                      ),
                      onPressed: () => _onUserTapped(user),
                      child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        if (_searchResultsPoems.isNotEmpty) ...[
          const Text(
            'Poems',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResultsPoems.length,
            itemBuilder: (context, index) {
              final poem = _searchResultsPoems[index];
              return _buildPopularPoemCard(Map<String, dynamic>.from(poem));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Not Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('We couldn\'t find any results for "${_searchController.text}".', style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}