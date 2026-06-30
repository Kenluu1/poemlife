import 'package:flutter/material.dart';

class DetailPreviewPage extends StatelessWidget {
  final String title;
  final String content;
  final String username;
  final List<Map<String, dynamic>> selectedCategories;

  const DetailPreviewPage({
    super.key,
    required this.title,
    required this.content,
    required this.username,
    required this.selectedCategories,
  });

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red[200]!, width: 1.5),
            boxShadow: [
              const BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.02),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.person, size: 20, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title (Centered, Serif font)
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'serif',
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Content (Centered, Serif font)
              Center(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.8,
                    fontFamily: 'serif',
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Category Chip Wrap (aligned to left center like screenshot)
              if (selectedCategories.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedCategories.map((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        category['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Interaction Icon Row (like screenshot)
              Row(
                children: [
                  // Empathy/Reaction icon
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.shade100,
                    ),
                    child: Icon(Icons.emoji_emotions, size: 14, color: Colors.amber.shade800),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "0",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(width: 16),

                  // Favorite/Love icon
                  const Icon(Icons.favorite_border, size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text(
                    "0",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(width: 16),

                  // Comment icon
                  const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text(
                    "0",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Spacer(),

                  // Bookmark icon
                  const Icon(Icons.bookmark_border, size: 20, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
