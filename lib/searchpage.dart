import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum SearchPhase { initial, loadingDots, skeleton, results, notFound }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final Color maroon = const Color(0xFFA33B3B);
  final Color skeletonGrey = Colors.grey.shade200;

  SearchPhase currentPhase = SearchPhase.initial;


  bool _isPageLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isPageLoading = false);
    });
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => currentPhase = SearchPhase.loadingDots);
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    setState(() => currentPhase = SearchPhase.skeleton);
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      if (query.toLowerCase() == 'kosong') {
        currentPhase = SearchPhase.notFound;
      } else {
        currentPhase = SearchPhase.results;
      }
    });
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
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 20.0, top: 16.0, bottom: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              if (currentPhase != SearchPhase.initial) {
                setState(() {
                  currentPhase = SearchPhase.initial;
                  _searchController.clear();
                });
              }
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
                textInputAction: TextInputAction.search,
                onSubmitted: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search',
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

  Widget _buildBodyContent() {
    switch (currentPhase) {
      case SearchPhase.initial:
        return _buildRecentSearches();
      case SearchPhase.loadingDots:
        return _buildLoadingDots();
      case SearchPhase.skeleton:
        return _buildPageSkeleton(); // Menggunakan fungsi skeleton yang sama
      case SearchPhase.results:
        return _buildResultsList();
      case SearchPhase.notFound:
        return _buildNotFound();
    }
  }

  Widget _buildRecentSearches() {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Delete all', style: TextStyle(color: maroon, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        _buildRecentItem(title: 'David Dones', subtitle: '194k followers', isUser: true),
        _buildRecentItem(title: 'Your wounds', isUser: false),
        _buildRecentItem(title: 'sad poems', isUser: false),
      ],
    );
  }

  Widget _buildRecentItem({required String title, String? subtitle, required bool isUser}) {
    return Container(
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
            backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'),
            backgroundColor: skeletonGrey,
          )
              : Icon(Icons.search, color: Colors.grey.shade500),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ]
              ],
            ),
          ),
          Icon(Icons.close, color: Colors.grey.shade600, size: 18),
        ],
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

  Widget _buildSkeletonCard() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(color: skeletonGrey, borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildResultsList() {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
      children: [
        _buildPoetryCard(author: 'Lauren Jarvis-Gibson', timeAgo: '15 minutes ago', avatarUrl: 'https://i.pravatar.cc/150?img=10'),
        const SizedBox(height: 16),
        _buildPoetryCard(author: 'Michael Timothy', timeAgo: '20 hours ago', avatarUrl: 'https://i.pravatar.cc/150?img=14'),
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

  Widget _buildPoetryCard({required String author, required String timeAgo, required String avatarUrl}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: maroon.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatarUrl)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(timeAgo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Your Wounds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("Time doesn't heal wounds\nto make you forget...", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 16),
          Text('Read More', style: TextStyle(color: maroon, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, size: 18, color: maroon),
                  const SizedBox(width: 4),
                  const Text('384', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  const Text('384', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Icon(Icons.bookmark, size: 20, color: maroon),
            ],
          )
        ],
      ),
    );
  }
}