import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'searchpage.dart';
import 'notificationpage.dart';
import 'profilepage.dart';
import 'addpage.dart';
import 'sadnesspage.dart';
import 'happinesspage.dart';
import 'angrypage.dart';

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

  Future<void> _loadInitialData() async {
    await Future.delayed(Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(Duration(seconds: 2));
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _onFeedTabTapped(int index) async {
    if (_activeFeedTab == index) return;

    setState(() {
      _activeFeedTab = index;
      _isFeedLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isFeedLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: PageView(
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
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(icon: Icons.home_outlined, index: 0),
          _buildNavItem(icon: Icons.search, index: 1),

          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPage()));
            },
            child: CircleAvatar(
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
        Text("Hi, Kenluu.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Text("What do you feel today ?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMoodCarousel() {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMoodCard("Sadness", Color(0xFF67A3D9), 'assets/Sad.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SadnessPage()));
          }),

          _buildMoodCard("Happiness", Color(0xFFF29C38), 'assets/Happy.png', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const HappinessPage()));
          }),

          _buildMoodCard("Angry", Color(0xFFE57373), 'assets/angry.png', () {
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
        Expanded(child: _buildSingleTab("For You", 0)),
        SizedBox(width: 15),
        Expanded(child: _buildSingleTab("Following", 1)),
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

  Widget _buildFeedContent() {
    if (_isFeedLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    } else {
      String tabName = _activeFeedTab == 0 ? "For You" : "Following";
      return Column(
        children: [
          Icon(Icons.feed_outlined, size: 60, color: Colors.grey.shade300),
          SizedBox(height: 15),
          Text(
            "There are no posts in $tabName yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
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