import 'package:flutter/material.dart';
import 'translation.dart';
import 'addpage.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: T.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  T.s('feel_right_now_title'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  T.s('feel_right_now_desc'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                _buildCategoryCard(
                  context,
                  title: T.s('sadness'),
                  color: const Color(0xFF67A3D9),
                  imagePath: 'assets/Sad.png',
                  categoryData: {'id': 1, 'name': 'Sadness'},
                ),
                const SizedBox(height: 20),
                _buildCategoryCard(
                  context,
                  title: T.s('happiness'),
                  color: const Color(0xFFF29C38),
                  imagePath: 'assets/Happy.png',
                  categoryData: {'id': 2, 'name': 'Happiness'},
                ),
                const SizedBox(height: 20),
                _buildCategoryCard(
                  context,
                  title: T.s('angry'),
                  color: const Color(0xFFE57373),
                  imagePath: 'assets/angry.png',
                  categoryData: {'id': 3, 'name': 'Anger'},
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required Color color,
    required String imagePath,
    required Map<String, dynamic> categoryData,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPage(
              selectedCategory: categoryData,
            ),
          ),
        );
        if (result != null && context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 15,
              bottom: 0,
              top: 0,
              child: Image.asset(
                imagePath,
                width: 90,
                fit: BoxFit.contain,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 80.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
