import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(seconds: 2));
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

    await Future.delayed(const Duration(milliseconds: 1200));

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
            image: const DecorationImage(
              image: AssetImage("assets/bannerbinus.png"),
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
                    _buildCircularIcon(Icons.bookmark_border, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FavouritePage()));
                    }),
                    const SizedBox(width: 10),

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
              backgroundImage: const AssetImage('assets/david_done.png'),
              backgroundColor: skeletonGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularIcon(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(8),
      ),
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
          } else if (value == 'favourites') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FavouritePage()));
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry>[
          const PopupMenuItem(value: 'settings', child: Text('Settings')),
          const PopupMenuItem(value: 'favourites', child: Text('Favourite Page')),
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
          const Text("Kenluu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Two roads diverged in a wood, and I— I took the one less traveled by, And that has made all the difference.",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
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
          _buildStatItem("0", "Followers"),
          _buildStatItem("0", "Following"),
          _buildStatItem("0", "Empathy"),
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildProfileTabItem("Poems", 0),
          _buildProfileTabItem("Privat", 1),
          _buildProfileTabItem("Empathy", 2),
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
    } else {
      return _buildEmptyState();
    }
  }

  Widget _buildEmptyState() {
    String currentTabLabel = "";
    if (_activeTabIndex == 0) currentTabLabel = "Poems";
    if (_activeTabIndex == 1) currentTabLabel = "Privat";
    if (_activeTabIndex == 2) currentTabLabel = "Empathy";

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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => DraftPage()));
                },
              ),
            ),
          ],

          Icon(Icons.description_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(
            "You still not upload anything in $currentTabLabel",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SKELETON LOADING PENUH HALAMAN (RATA KIRI)
  // =========================================================
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 80, height: 35, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                  Container(width: 80, height: 35, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
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

// =========================================================
// HALAMAN-HALAMAN BARU (DRAFT, SETTINGS, FAVOURITE)
// =========================================================

class DraftPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Drafts", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Text(
          "Halaman Draft Masih Kosong",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Text(
          "Halaman Settings",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}

class FavouritePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favourite Page", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Text(
          "Halaman Favourite Masih Kosong",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}