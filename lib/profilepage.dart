import 'package:flutter/material.dart';
import 'package:poemlife/draftpage.dart';
import 'package:poemlife/favouritepage.dart';
import 'package:poemlife/settingpage.dart';
import 'package:poemlife/detailpage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poemlife/API.dart';
import 'translation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color maroon = const Color(0xFFA33B3B);
  final Color skeletonGrey = Colors.grey.shade200;

  bool _isInitialLoading = true;
  bool _isTabLoading = false;
  int _activeTabIndex = 0;

  int? _userId;
  String _username = 'User';
  String _fullname = '';
  String _nim = '';
  String _bio = 'Two roads diverged in a wood, and I— I took the one less traveled by, And that has made all the difference.';
  String _avatar = '';
  String _banner = '';
  int _followers = 0;
  int _following = 0;
  List<dynamic> _tabPoems = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    ApiService.followEvents.addListener(_onFollowEvent);
  }

  void _onFollowEvent() {
    if (mounted) {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    ApiService.followEvents.removeListener(_onFollowEvent);
    super.dispose();
  }

  Future<void> _fetchTabPoems(int index) async {
    List<dynamic> fetched = [];
    if (index == 0) {
      fetched = await ApiService().getPoems(type: 'user');
    } else if (index == 1) {
      final list = await ApiService().getBookmarks();
      fetched = (list ?? []).map((item) {
        if (item['poem'] != null && item['poem'] is Map) {
          final poemData = Map<String, dynamic>.from(item['poem'] as Map);
          poemData['is_bookmarked'] = 1;
          return poemData;
        }
        return item;
      }).toList();
    }

    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];
    final reportedPoems = prefs.getStringList('reported_poems') ?? [];

    final filtered = fetched.where((p) {
      final String author = p['author'] ?? '';
      final String idStr = (p['id'] ?? '').toString();
      return !blockedUsers.contains(author) && !reportedPoems.contains(idStr);
    }).toList();

    if (mounted) {
      setState(() {
        _tabPoems = filtered;
      });
    }
  }

  int _userPoemsCount = 0;

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getInt('userId');
    _userId = savedUserId;

    if (savedUserId != null) {
      final profile = await ApiService().getUserProfile(savedUserId);
      final userPoems = await ApiService().getPoems(type: 'user');
      await _fetchTabPoems(_activeTabIndex);
      if (profile != null && mounted) {
        setState(() {
          _username = profile['username'] ?? 'User';
          _fullname = profile['fullname'] ?? '';
          _nim = profile['nim'] ?? '';
          _bio = profile['bio'] ?? 'Two roads diverged in a wood, and I— I took the one less traveled by, And that has made all the difference.';
          _userPoemsCount = userPoems.length;
          _avatar = profile['image'] ?? '';
          _banner = profile['banner'] ?? '';
          _followers = profile['followers'] ?? 0;
          _following = profile['following'] ?? 0;
          _isInitialLoading = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  void _onTabTapped(int index) async {
    if (index == _activeTabIndex) return;

    setState(() {
      _isTabLoading = true;
      _activeTabIndex = index;
    });

    await _fetchTabPoems(index);

    if (mounted) {
      setState(() {
        _isTabLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isInitialLoading
          ? _buildPageSkeleton()
          : _buildProfileContent(),
    );
  }


  Widget _buildHeaderAndCover() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 140, //
          width: double.infinity,
          decoration: BoxDecoration(
            color: skeletonGrey,
            image: DecorationImage(
              image: _banner.isNotEmpty
                  ? NetworkImage(_banner) as ImageProvider
                  : const AssetImage("assets/bannerbinus.png") as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),


        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/id/6/6f/Binus_University_Logo.svg.png',
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(width: 80),
                ),


                Row(
                  children: [
                    _buildCircularMenu(),
                  ],
                ),
              ],
            ),
          ),
        ),


        Positioned(
          bottom: -40,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundImage: _avatar.isNotEmpty ? NetworkImage(_avatar) : null,
              backgroundColor: skeletonGrey,
              child: _avatar.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildCircularMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: PopupMenuButton(
        icon: const Icon(Icons.menu, color: Colors.black87, size: 20),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        onSelected: (value) {
          if (value == 'settings') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())).then((_) {
              _loadInitialData();
            });
          } else if (value == 'favourites') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritePage()));
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
           PopupMenuItem(value: 'settings', child: Text(T.s('settings'))),
           PopupMenuItem(value: 'favourites', child: Text(T.s('favourites'))),
         ],
      ),
    );
  }


  Widget _buildProfileContent() {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          _buildHeaderAndCover(),
          _buildUserInfo(),
          const SizedBox(height: 15),
          _buildUserStats(),
          const SizedBox(height: 20),
          _buildTabNavigationBar(),
          const SizedBox(height: 20),
          _buildTabContentArea(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_fullname.isNotEmpty ? _fullname : _username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (_nim.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _nim,
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _bio,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(_followers.toString(), T.s("followers")),
          _buildStatItem(_following.toString(), T.s("following")),
          _buildStatItem(_userPoemsCount.toString(), T.s("poems")),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildTabNavigationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileTabItem(T.s("poems"), 0),
          const SizedBox(width: 15),
          _buildProfileTabItem("Bookmark", 1),
        ],
      ),
    );
  }

  Widget _buildProfileTabItem(String label, int index) {
    bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? maroon : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isActive ? maroon : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContentArea() {
    if (_isTabLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: _buildTabSkeleton(),
      );
    }

    if (_tabPoems.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (_activeTabIndex == 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                border: Border.all(color: maroon.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: const Text("Draft", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: Text("See all", style: TextStyle(color: maroon, fontSize: 12, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DraftPage()));
                },
              ),
            ),
          ],
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tabPoems.length,
            itemBuilder: (context, index) {
              final poem = _tabPoems[index] as Map<String, dynamic>;
              return _buildProfilePoemCard(poem);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePoemCard(Map<String, dynamic> poem) {
    final title = poem['title'] ?? 'Untitled';
    final content = T.getCleanContent(poem['content'] ?? '');
    final author = poem['author'] ?? 'Anonymous';
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

    final cardAuthor = (_activeTabIndex != 0) ? author : _username;
    final String cardAvatar = (_activeTabIndex != 0)
        ? avatarUrl
        : (_avatar.isNotEmpty ? _avatar : 'https://i.pravatar.cc/150?img=10');

    final isBookmarked = poem['is_bookmarked'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!, width: 1.5),
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
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: NetworkImage(cardAvatar),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cardAuthor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'serif', color: Colors.black)),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
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
              _loadInitialData();
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
                  const Text("1k", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                      color: poem['is_liked'] == true ? maroon : Colors.grey,
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
                  color: isBookmarked ? maroon : Colors.grey,
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
                  _loadInitialData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String currentTabLabel = "";
    if (_activeTabIndex == 0) currentTabLabel = T.s("poems");
    if (_activeTabIndex == 1) currentTabLabel = "Bookmark";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (_activeTabIndex == 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                border: Border.all(color: maroon.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(T.s("draft"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                trailing: Text(T.s("see_all"), style: TextStyle(color: maroon, fontSize: 12, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DraftPage()));
                },
              ),
            ),
          ],

          Icon(Icons.description_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(
            "${T.s("upload_empty")}$currentTabLabel",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSkeleton() {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(height: 140, width: double.infinity, color: Colors.white),
                Positioned(
                  bottom: -40,
                  left: 20,
                  child: Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 150, height: 20, color: Colors.white),
                  const SizedBox(height: 10),
                  Container(width: double.infinity, height: 12, color: Colors.white),
                  const SizedBox(height: 5),
                  Container(width: 250, height: 12, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 80, height: 35, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  const SizedBox(width: 15),
                  Container(width: 80, height: 35, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _buildTabSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
