import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poemlife/addcategoriespage.dart';
import 'package:poemlife/publicationpage.dart';
import 'package:poemlife/detailpreviewpage.dart';

class PreviewPage extends StatefulWidget {
  final String title;
  final String content;

  const PreviewPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  List<Map<String, dynamic>> _selectedCategories = [];
  String _selectedPublication = "Everyone";
  String _username = "Kenluu";

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username');
    if (savedUsername != null && mounted) {
      setState(() {
        _username = savedUsername;
      });
    }
  }

  void _submitPoem(BuildContext context, {required int published}) {
    // If they click Posting (published == 1) but selected "Only me", send 0 (private/draft)
    int finalPublished = published;
    if (published == 1 && _selectedPublication == "Only me") {
      finalPublished = 0;
    }

    final payload = {
      'title': widget.title,
      'content': widget.content,
      'categoryId': _selectedCategories.isNotEmpty ? _selectedCategories.first['id'] : 1,
      'published': finalPublished,
    };
    Navigator.pop(context, payload);
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Preview",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "This is how your poem will be shown to readers. You can edit your poem or choose category of your poem before submitting.",
              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 30),

            // Prototype Card Poem
            Container(
              padding: const EdgeInsets.all(20),
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
                        radius: 14,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _username,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'serif'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.content,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPreviewPage(
                            title: widget.title,
                            content: widget.content,
                            username: _username,
                            selectedCategories: _selectedCategories,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "Read More",
                      style: TextStyle(color: Colors.red[300], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),


            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[200]!, width: 1.5),
              ),
              child: Column(
                children: [
                  _buildSettingRow(
                    "Category",
                    _selectedCategories.isEmpty
                        ? "Add category"
                        : _selectedCategories.map((c) => c['name']).join(', '),
                    "See all",
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddCategoriesPage(
                            initialCategories: _selectedCategories,
                          ),
                        ),
                      );
                      if (result != null && result is List<Map<String, dynamic>>) {
                        setState(() {
                          _selectedCategories = result;
                        });
                      }
                    },
                  ),
                  Divider(height: 1, color: Colors.red[100]),
                  _buildSettingRow(
                    "Publication",
                    _selectedPublication,
                    "See all",
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PublicationPage(
                            initialPublication: _selectedPublication,
                          ),
                        ),
                      );
                      if (result != null && result is String) {
                        setState(() {
                          _selectedPublication = result;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Buttons (Draft & Posting)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submitPoem(context, published: 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.red[200]!, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.insert_drive_file_outlined, color: Colors.black54, size: 20),
                      SizedBox(width: 8),
                      Text("Draft", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submitPoem(context, published: 1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF993B3B), // Warna marun
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.send_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text("Posting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSettingRow(String title, String subtitle, String actionText, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            Text(actionText, style: const TextStyle(color: Color(0xFF993B3B), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}