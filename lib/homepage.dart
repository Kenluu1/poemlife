import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poemlife/API.dart';
import 'searchpage.dart';
import 'notificationpage.dart';
import 'profilepage.dart';
import 'addpage.dart';
import 'categorypage.dart';
import 'sadnesspage.dart';
import 'happinesspage.dart';
import 'angrypage.dart';
import 'detailpage.dart';
import 'package:poemlife/otheruserprofile.dart';
import 'translation.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _currentIndex = 0;
  int _searchKey = 0;
  int _notificationKey = 0;
  int _profileKey = 0;
  bool _isInitialLoading = true;
  bool _isRefreshing = false;

  int _activeFeedTab = 0;
  bool _isFeedLoading = false;

  ScrollController _scrollController = ScrollController();

  int? _currentUserId;
  String _currentUsername = 'User';
  List<dynamic> _poems = [];

  bool _showPostingBanner = false;
  String _postingStatus = 'loading';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _startPostingPoem(Map<String, dynamic> payload) async {
    setState(() {
      _showPostingBanner = true;
      _postingStatus = 'loading';
    });

    bool success = await ApiService().createPoem(
      title: payload['title'],
      content: payload['content'],
      categoryId: payload['categoryId'],
      published: payload['published'],
    );

    if (mounted) {
      if (success) {
        setState(() {
          _postingStatus = 'success';
          _isInitialLoading = true;
          _profileKey++; // Force profile page to recreate and fetch fresh data
        });
        _loadInitialData();

        // Auto-dismiss banner after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _showPostingBanner = false;
            });
          }
        });
      } else {
        setState(() {
          _showPostingBanner = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memposting puisi. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<dynamic>> _filterBlockedAndReported(List<dynamic> fetchedPoems) async {
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];
    final reportedPoems = prefs.getStringList('reported_poems') ?? [];

    return fetchedPoems.where((p) {
      final String author = p['author'] ?? '';
      final String idStr = (p['id'] ?? '').toString();
      return !blockedUsers.contains(author) && !reportedPoems.contains(idStr);
    }).toList();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username') ?? 'User';
    _currentUserId = prefs.getInt('userId');
    final fetchedPoems = await ApiService().getPoems(type: _activeFeedTab == 0 ? 'all' : 'popular');
    final filtered = await _filterBlockedAndReported(fetchedPoems);

    if (mounted) {
      setState(() {
        _currentUsername = savedUsername;
        _poems = filtered;
        _isInitialLoading = false;
        _isFeedLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final fetchedPoems = await ApiService().getPoems(type: _activeFeedTab == 0 ? 'all' : 'popular');
    final filtered = await _filterBlockedAndReported(fetchedPoems);
    if (mounted) {
      setState(() {
        _poems = filtered;
        _isRefreshing = false;
      });
    }
  }

  void _onFeedTabTapped(int index) async {
    if (_activeFeedTab == index) return;

    setState(() {
      _activeFeedTab = index;
      _isFeedLoading = true;
    });

    final fetchedPoems = await ApiService().getPoems(type: index == 0 ? 'all' : 'popular');
    final filtered = await _filterBlockedAndReported(fetchedPoems);

    if (mounted) {
      setState(() {
        _poems = filtered;
        _isFeedLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              if (index == 0 && _currentIndex != 0) {
                setState(() { _isInitialLoading = true; });
                _loadInitialData();
              } else if (index == 1 && _currentIndex != 1) {
                setState(() { _searchKey++; });
              } else if (index == 2 && _currentIndex != 2) {
                setState(() { _notificationKey++; });
              } else if (index == 3 && _currentIndex != 3) {
                setState(() { _profileKey++; });
              }

              setState(() {
                _currentIndex = index;
              });
            },
            children: [
              SafeArea(
                child: _isInitialLoading ? _buildSkeleton() : _buildMainContent(),
              ),
              SearchPage(key: ValueKey('search_$_searchKey')),
              NotificationPage(key: ValueKey('notif_$_notificationKey')),
              ProfilePage(key: ValueKey('profile_$_profileKey')),
            ],
          ),
          if (_showPostingBanner)
            Positioned(
              bottom: 95,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF993B3B),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_postingStatus == 'loading') ...[
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF29C38),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Text(
                        T.s("posting"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ] else if (_postingStatus == 'success') ...[
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        T.s("posted"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPostingBanner = false;
                          });
                          _onNavTapped(3); // Switch to Profile Page tab
                        },
                        child: Text(
                          T.s("view"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildInteractiveBottomNav(),
        ),
      ),
    );
  }

  Widget _buildInteractiveBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(icon: Icons.home_outlined, index: 0),
          _buildNavItem(icon: Icons.search, index: 1),

          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryPage()));
              if (result != null && result is Map<String, dynamic>) {
                _startPostingPoem(result);
              }
            },
            child: const CircleAvatar(
              backgroundColor: Color(0xFF993B3B),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),

          _buildNavItem(icon: Icons.notifications_none, index: 2),
          _buildNavItem(icon: Icons.person_outline, index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: Container(
        padding: EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: isSelected ? Color(0xFF993B3B) : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.transparent,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ListView(
        controller: _scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          if (_isRefreshing) _buildCustomLoadingDots(),

          _buildHeader(),
          SizedBox(height: 20),
          _buildMoodCarousel(),
          SizedBox(height: 20),
          _buildTabs(),
          SizedBox(height: 30),
          _buildFeedContent(),

          SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${T.s("hi")}, $_currentUsername.", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(T.s("what_feel"), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMoodCarousel() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMoodCard(T.s("sadness"), Color(0xFF67A3D9), 'assets/Sad.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SadnessPage()));
          }),

          _buildMoodCard(T.s("happiness"), Color(0xFFF29C38), 'assets/Happy.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HappinessPage()));
          }),

          _buildMoodCard(T.s("angry"), Color(0xFFE57373), 'assets/angry.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AngryPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildMoodCard(String title, Color color, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: 15),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 50,
                height: 50,
                color: Colors.white24,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.image, color: Colors.white),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(child: _buildSingleTab(T.s("for_you"), 0)),
        const SizedBox(width: 15),
        Expanded(child: _buildSingleTab(T.s("following"), 1)),
      ],
    );
  }

  Widget _buildSingleTab(String title, int index) {
    bool isActive = _activeFeedTab == index;
    return GestureDetector(
      onTap: () => _onFeedTabTapped(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF993B3B) : Colors.transparent,
          border: Border.all(color: isActive ? Color(0xFF993B3B) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoemCard(Map<String, dynamic> poem) {
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

    final rawContent = T.getCleanContent(poem['content'] ?? '');
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
                  _loadInitialData();
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
                  _loadInitialData();
                } else {
                  setState(() {
                    poem['is_liked'] = result['is_liked'];
                    poem['love_count'] = result['love_count'];
                    poem['is_bookmarked'] = result['is_bookmarked'];
                    poem['comment_count'] = result['comment_count'];
                  });
                }
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

  Widget _buildFeedContent() {
    if (_isFeedLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    } else if (_poems.isEmpty) {
      String tabName = _activeFeedTab == 0 ? T.s("for_you") : T.s("following");
      return Column(
        children: [
          Icon(Icons.feed_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(
            "${T.s("no_posts")}$tabName${T.s("no_posts_suffix")}",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _poems.length,
        itemBuilder: (context, index) {
          final poem = _poems[index] as Map<String, dynamic>;
          return _buildPoemCard(poem);
        },
      );
    }
  }

  Widget _buildCustomLoadingDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(0xFF993B3B), shape: BoxShape.circle)),
          SizedBox(width: 5),
          Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(0xFFF29C38), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 100, height: 20, color: Colors.white),
            SizedBox(height: 5),
            Container(width: 200, height: 25, color: Colors.white),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)))),
                SizedBox(width: 15),
                Expanded(child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)))),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
                SizedBox(width: 15),
                Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
              ],
            ),
            SizedBox(height: 20),
            Expanded(child: Container(height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
          ],
        ),
      ),
    );
  }
}