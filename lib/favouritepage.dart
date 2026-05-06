import 'package:flutter/material.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final Color maroon = const Color(0xFFA33B3B);
  final Color orange = const Color(0xFFF29C38);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isLoading
          ? null
          : AppBar(
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
      body: _isLoading ? _buildLoadingView() : _buildEmptyStateView(),
    );
  }


  Widget _buildLoadingView() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: maroon, shape: BoxShape.circle)
          ),
          const SizedBox(width: 8),
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: orange, shape: BoxShape.circle)
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
}