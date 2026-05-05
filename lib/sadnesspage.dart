import 'package:flutter/material.dart';

class SadnessPage extends StatefulWidget {
  const SadnessPage({Key? key}) : super(key: key);

  @override
  State<SadnessPage> createState() => _SadnessPageState();
}

class _SadnessPageState extends State<SadnessPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sad Poems',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading ? _buildSkeletonView() : _buildContentView(),
    );
  }

  Widget _buildSkeletonView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _skeletonBox(height: 180),
        const SizedBox(height: 20),
        _skeletonBox(height: 280),
      ],
    );
  }

  Widget _skeletonBox({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildContentView() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Header Image Sadness
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage('assets/sadness_image.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Text('Sadness', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),

        // Prototype Post
        _buildPrototypePost(),
      ],
    );
  }

  Widget _buildPrototypePost() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[400],
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Lauren Jarvis-Gibson", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("15 minutes ago", style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          const Text("Your Wounds", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'serif')),
          const SizedBox(height: 12),
          const Text(
            "Time doesn't heal wounds\nto make you forget.\n\nIt doesn't heal wounds to\nerase the memories.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text("Read More", style: TextStyle(color: Colors.red[300], fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}