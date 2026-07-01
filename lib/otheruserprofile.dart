import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poemlife/API.dart';
import 'package:poemlife/detailpage.dart';
import 'translation.dart';

class OtherUserProfile extends StatefulWidget {
  final int userId;
  final String username;

  const OtherUserProfile({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<OtherUserProfile> createState() => _OtherUserProfileState();
}

class _OtherUserProfileState extends State<OtherUserProfile> {
  final Color maroon = const Color(0xFFA33B3B);
  final Color skeletonGrey = Colors.grey.shade200;

  bool _isInitialLoading = true;
  bool _isTabLoading = false;
  int _activeTabIndex = 0; // 0 = Poems, 1 = Empathy

  Map<String, dynamic>? _profileData;
  List<dynamic> _tabPoems = [];

  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;
  int _empathyCount = 0;
  bool _isFollowTransitioning = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
    });

    final startTime = DateTime.now();

    // Fetch user details from API
    final profile = await ApiService().getUserProfile(widget.userId);
    if (profile != null) {
      _profileData = profile;
      _followersCount = profile['followers'] ?? 0;
      _followingCount = profile['following'] ?? 0;
      _empathyCount = profile['empathy'] ?? 0;
      _isFollowing = profile['is_following'] == true;
    }

    // Fetch poems list based on current active tab
    await _fetchTabPoems();

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remaining = 2000 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _fetchTabPoems() async {
    List<dynamic> fetched = [];
    if (_activeTabIndex == 0) {
      fetched = await ApiService().getPoems(
        type: 'user',
        targetUserId: widget.userId,
      );
    } else {
      fetched = await ApiService().getPoems(
        type: 'empathy',
        targetUserId: widget.userId,
      );
    }

    // Local filters for blocked/reported content
    final prefs = await SharedPreferences.getInstance();
    final blockedUsers = prefs.getStringList('blocked_users') ?? [];
    final reportedPoems = prefs.getStringList('reported_poems') ?? [];

    final filtered = fetched.where((p) {
      final String author = p['author'] ?? '';
      final String idStr = (p['id'] ?? '').toString();
      return !blockedUsers.contains(author) && !reportedPoems.contains(idStr);
    }).toList();

    print('--- _fetchTabPoems debug ---');
    print('Target User ID: ${widget.userId}');
    print('Active Tab Index: $_activeTabIndex');
    print('Fetched raw count: ${fetched.length}');
    print('Blocked Users list: $blockedUsers');
    print('Filtered count: ${filtered.length}');

    if (mounted) {
      setState(() {
        _tabPoems = filtered;
      });
    }
  }

  Future<void> _onTabTapped(int index) async {
    if (index == _activeTabIndex) return;

    setState(() {
      _isTabLoading = true;
      _activeTabIndex = index;
    });

    final startTime = DateTime.now();

    await _fetchTabPoems();

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remaining = 2000 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (mounted) {
      setState(() {
        _isTabLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowTransitioning) return;

    final bool originalFollowing = _isFollowing;
    final int originalFollowers = _followersCount;

    setState(() {
      _isFollowTransitioning = true;
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _followersCount++;
      } else {
        _followersCount--;
      }
    });

    bool success = false;
    if (_isFollowing) {
      success = await ApiService().followUser(widget.userId);
    } else {
      success = await ApiService().unfollowUser(widget.userId);
    }

    if (mounted) {
      setState(() {
        _isFollowTransitioning = false;
        if (!success) {
          _isFollowing = originalFollowing;
          _followersCount = originalFollowers;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update follow status')),
          );
        }
      });
    }
  }

  void _showActionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final authorUsername = _profileData?['username'] ?? widget.username;
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
                  final prefs = await SharedPreferences.getInstance();
                  List<String> blocked =
                      prefs.getStringList('blocked_users') ?? [];
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
                  Navigator.pop(context, 'reload');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      T.s("block"),
                      style: TextStyle(
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
                  if (_tabPoems.isNotEmpty) {
                    final poemId = _tabPoems.first['id'];
                    if (poemId != null) {
                      final prefs = await SharedPreferences.getInstance();
                      List<String> reported =
                          prefs.getStringList('reported_poems') ?? [];
                      final String poemIdStr = poemId.toString();
                      if (!reported.contains(poemIdStr)) {
                        reported.add(poemIdStr);
                        await prefs.setStringList('reported_poems', reported);
                      }
                    }
                  }

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Post reported successfully"),
                      backgroundColor: maroon,
                    ),
                  );
                  Navigator.pop(context, 'reload');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      T.s("report"),
                      style: TextStyle(
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
                      style: TextStyle(
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
                  if (_tabPoems.isNotEmpty) {
                    final poem = _tabPoems.first;
                    final poemId = poem['id'];
                    if (poemId != null) {
                      final prefs = await SharedPreferences.getInstance();
                      List<String> sharedJson =
                          prefs.getStringList('shared_empathy_poems') ?? [];

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
                        sharedJson.add(jsonEncode(poem));
                        await prefs.setStringList(
                          'shared_empathy_poems',
                          sharedJson,
                        );
                        // Persist share reaction to backend database
                        await ApiService().toggleReaction(poemId, 2);
                      }
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
                      style: TextStyle(
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

  Widget _buildFollowButton() {
    if (_isFollowing) {
      return GestureDetector(
        onTap: _toggleFollow,
        child: Container(
          width: 100,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: maroon, width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              T.s("following"),
              style: TextStyle(
                color: maroon,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: _toggleFollow,
        child: Container(
          width: 100,
          height: 36,
          decoration: BoxDecoration(
            color: maroon,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              T.s("follow"),
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final profileData = _profileData;
    final avatar = profileData?['image'] ?? '';
    final fullname = profileData?['fullname'] ?? widget.username;
    final bio =
        profileData?['bio'] ??
        'Two roads diverged in a wood, and I— I took the one less traveled by, And that has made all the difference.';
    final nim = profileData?['nim']?.toString() ?? '';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Cover and Header Stack
        Stack(
          clipBehavior: Clip.none,
          children: [
            const SizedBox(height: 180, width: double.infinity),
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: skeletonGrey,
                image: const DecorationImage(
                  image: AssetImage("assets/bannerbinus.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 55,
              child: Text(
                "i remember it all too well\n          - t. s",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'serif',
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showActionsMenu,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : null,
                  backgroundColor: skeletonGrey,
                  child: avatar.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
              ),
            ),
            Positioned(bottom: 10, right: 20, child: _buildFollowButton()),
          ],
        ),
        const SizedBox(height: 10),

        // User Identity
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullname,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (nim.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  nim,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                bio,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Stats Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(_followersCount, "Followers"),
              _buildStatItem(_followingCount, "Following"),
              _buildStatItem(_empathyCount, "Empathy"),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Custom Tab Selectors
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _activeTabIndex == 0 ? maroon : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: maroon, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        "Poems",
                        style: TextStyle(
                          color: _activeTabIndex == 0 ? Colors.white : maroon,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _activeTabIndex == 1 ? maroon : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: maroon, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        "Empathy",
                        style: TextStyle(
                          color: _activeTabIndex == 1 ? Colors.white : maroon,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tab Content
        _isTabLoading ? _buildSkeletonLoader() : _buildTabListContent(),
      ],
    );
  }

  Widget _buildStatItem(int count, String label) {
    String countStr = count.toString();
    if (count >= 1000000) {
      double mil = count / 1000000.0;
      countStr = "${mil.toStringAsFixed(mil % 1 == 0 ? 0 : 1)}M";
    } else if (count >= 1000) {
      double k = count / 1000.0;
      countStr = "${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}K";
    }

    return Column(
      children: [
        Text(
          countStr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTabListContent() {
    if (_tabPoems.isEmpty) {
      final String emptyText = _activeTabIndex == 0
          ? "This user hasn't posted anything yet"
          : "this user doesn't have any empathy";
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            emptyText,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: _tabPoems.length,
      itemBuilder: (context, index) {
        final poem = _tabPoems[index] as Map<String, dynamic>;
        return _buildPoemCard(poem);
      },
    );
  }

  Widget _buildPoemCard(Map<String, dynamic> poem) {
    final title = poem['title'] ?? 'Untitled';
    final author = poem['author'] ?? 'Anonymous';
    final isBookmarked = poem['is_bookmarked'] == 1;
    final String avatarUrl =
        (poem['authorImage'] != null &&
            poem['authorImage'].toString().isNotEmpty)
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
        border: Border.all(color: Colors.red[200]!, width: 1.5),
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
                backgroundColor: Colors.grey.shade200,
                onBackgroundImageError: (_, __) {},
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'serif',
              color: Colors.black,
            ),
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
                MaterialPageRoute(builder: (context) => DetailPage(poem: poem)),
              );
              if (result != null && result is Map<String, dynamic> && mounted) {
                if (result['action'] == 'reload') {
                  _fetchTabPoems();
                } else {
                  setState(() {
                    poem['is_liked'] = result['is_liked'];
                    poem['love_count'] = result['love_count'];
                    poem['is_bookmarked'] = result['is_bookmarked'];
                    poem['comment_count'] = result['comment_count'];
                  });
                }
              } else {
                _fetchTabPoems();
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
                  const Text(
                    "394",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () async {
                      final bool currentlyLiked = poem['is_liked'] == true;
                      setState(() {
                        poem['is_liked'] = !currentlyLiked;
                        int currentCount =
                            int.tryParse(
                              poem['love_count']?.toString() ?? '0',
                            ) ??
                            0;
                        if (poem['is_liked']) {
                          poem['love_count'] = currentCount + 1;
                        } else {
                          poem['love_count'] = currentCount - 1;
                        }
                      });
                      bool success = await ApiService().toggleReaction(
                        poem['id'],
                        1,
                      );
                      if (!success) {
                        setState(() {
                          poem['is_liked'] = currentlyLiked;
                          int currentCount =
                              int.tryParse(
                                poem['love_count']?.toString() ?? '0',
                              ) ??
                              0;
                          if (poem['is_liked']) {
                            poem['love_count'] = currentCount + 1;
                          } else {
                            poem['love_count'] = currentCount - 1;
                          }
                        });
                      }
                    },
                    child: Icon(
                      poem['is_liked'] == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 18,
                      color: poem['is_liked'] == true
                          ? const Color(0xFF993B3B)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (poem['love_count'] ?? '0').toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Colors.grey[600],
                  ),
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
                        nextState
                            ? "added to favourite page"
                            : "remove from favourite",
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );

                  bool success = await ApiService().toggleBookmark(
                    poem['id'],
                    isBookmarked,
                  );
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

  Widget _buildSkeletonPageContent() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Cover and Header Stack Placeholder
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.grey.shade300,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: 20,
              child: Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              right: 20,
              child: Container(
                width: 100,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 50),

        // Identity Placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 180, height: 22, color: Colors.white),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 14,
                color: Colors.white,
              ),
              const SizedBox(height: 6),
              Container(width: 250, height: 14, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Stats Placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Container(width: 40, height: 18, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(width: 60, height: 12, color: Colors.white),
                ],
              ),
              Column(
                children: [
                  Container(width: 40, height: 18, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(width: 60, height: 12, color: Colors.white),
                ],
              ),
              Column(
                children: [
                  Container(width: 40, height: 18, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(width: 60, height: 12, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Custom Tab Selectors Placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSkeletonLoader(),
      ],
    );
  }

  Widget _buildSkeletonPage() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: _buildSkeletonPageContent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isInitialLoading ? _buildSkeletonPage() : _buildProfileContent(),
    );
  }
}
