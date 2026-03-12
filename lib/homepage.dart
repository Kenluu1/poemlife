import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isInitialLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;


  List<Map<String, String>> _posts = [];

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();


    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreData();
      }
    });
  }


  Future<void> _loadInitialData() async {
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      _isInitialLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(Duration(seconds: 2));
    setState(() => _isRefreshing = false);
  }


  Future<void> _loadMoreData() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(Duration(seconds: 2));
    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isInitialLoading ? _buildSkeleton() : _buildMainContent(),
      ),

      bottomNavigationBar: _buildBottomNav(),
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
          SizedBox(height: 20),


          _posts.isEmpty ? _buildEmptyState() : _buildPostList(),


          if (_isLoadingMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: _buildCustomLoadingDots(),
            ),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hi, Thomas.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          _buildMoodCard("Sadness", Color(0xFF67A3D9), 'assets/Sad.png'),
          _buildMoodCard("Happiness", Color(0xFFF29C38), 'assets/Happy.png'),
          _buildMoodCard("Anger", Color(0xFFE57373), 'assets/anger.png'),
        ],
      ),
    );
  }

  Widget _buildMoodCard(String title, Color color, String imagePath) {
    return GestureDetector(
      onTap: () {
        print("Pindah ke page $title");
      },
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
              child: Image.asset(
                imagePath,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
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
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFF993B3B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Text("For You", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(child: Text("Following", style: TextStyle(color: Colors.black54))),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text("Belum ada postingan", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostList() {
    // post
    return Column(
      children: [
        _buildPostCard("Lauren Jarvis-Gibson", "15 minutes ago", "Your Wounds"),
        SizedBox(height: 15),
        _buildPostCard("Michael Timothy", "20 hours ago", "Your Wounds"),
      ],
    );
  }

  Widget _buildPostCard(String name, String time, String title) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 15, backgroundColor: Colors.grey.shade300),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(time, style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              )
            ],
          ),
          SizedBox(height: 20),
          Text(title, style: TextStyle(fontFamily: 'Serif', fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 15),
          Text(
            "Time doesn't heal wounds\nto make you forget.\n\nIt doesn't heal wounds to\nerase the memories.",
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Serif', color: Colors.black87),
          ),
          SizedBox(height: 15),
          Text("Read More", style: TextStyle(color: Color(0xFF993B3B), fontSize: 12)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInteraction(Icons.language, "394"),
              _buildInteraction(Icons.favorite_border, "394"),
              _buildInteraction(Icons.chat_bubble_outline, "394"),
              Icon(Icons.bookmark_border, color: Colors.grey, size: 18),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInteraction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        SizedBox(width: 5),
        Text(count, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
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

  // ==========================================
  // SKELETON LOADING
  // ==========================================
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
            Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)))),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomNav() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.home_outlined, color: Color(0xFF993B3B)),
          Icon(Icons.search, color: Colors.grey),
          CircleAvatar(
            backgroundColor: Color(0xFF993B3B),
            child: Icon(Icons.add, color: Colors.white),
          ),
          Icon(Icons.notifications_none, color: Colors.grey),
          Icon(Icons.person_outline, color: Colors.grey),
        ],
      ),
    );
  }
}