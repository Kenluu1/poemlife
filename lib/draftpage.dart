import 'package:flutter/material.dart';
import 'package:poemlife/API.dart';
import 'package:poemlife/addpage.dart';
import 'translation.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({super.key});

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  bool _isLoading = true;
  List<dynamic> _drafts = [];

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() {
      _isLoading = true;
    });
    final fetchedDrafts = await ApiService().getPoems(type: 'draft');
    if (mounted) {
      setState(() {
        _drafts = fetchedDrafts;
        _isLoading = false;
      });
    }
  }

  void _deleteAll() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF993B3B)),
      ),
    );
    bool allSuccess = true;
    for (var draft in _drafts) {
      final poemId = draft['id'];
      if (poemId != null) {
        bool success = await ApiService().deletePoem(poemId);
        if (!success) {
          allSuccess = false;
        }
      }
    }
    if (!mounted) return;
    Navigator.pop(context); // Hide loading
    if (!allSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.lang == 'id' ? 'Beberapa draf gagal dihapus' : 'Failed to delete some drafts')),
      );
    }
    _loadDrafts();
  }

  void _deleteDraft(int index) async {
    final draft = _drafts[index];
    final poemId = draft['id'];
    if (poemId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF993B3B)),
        ),
      );
      bool success = await ApiService().deletePoem(poemId);
      if (!mounted) return;
      Navigator.pop(context); // Hide loading
      if (success) {
        _loadDrafts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(T.lang == 'id' ? 'Gagal menghapus draf' : 'Failed to delete draft')),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Just now";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return dateStr;
    }
  }

  String _getCategoryName(int? categoryId) {
    switch (categoryId) {
      case 1:
        return 'Sadness';
      case 2:
        return 'Happiness';
      case 3:
        return 'Anger';
      case 4:
        return 'Love';
      case 5:
        return 'Longing';
      case 6:
        return 'Loneliness';
      case 7:
        return 'Memories';
      case 8:
        return 'Disappointment';
      default:
        return 'Sadness';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          T.s("draft"),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _drafts.isEmpty || _isLoading ? null : _deleteAll,
            child: Text(
              T.s("delete_all"),
              style: TextStyle(
                color: _drafts.isEmpty || _isLoading ? Colors.grey : const Color(0xFFB57B7B), // Warna merah pudar sesuai desain
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonList()
          : _drafts.isEmpty
          ? _buildEmptyState()
          : _buildDraftList(),
    );
  }


  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildDraftList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _drafts.length,
      itemBuilder: (context, index) {
        final draft = _drafts[index];
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddPage(
                  selectedCategory: {
                    'id': draft['category_id'] ?? 1,
                    'name': _getCategoryName(draft['category_id']),
                  },
                  initialTitle: draft['title'],
                  initialContent: draft['content'],
                  editPoemId: draft['id'],
                  autoPushPreview: true,
                ),
              ),
            );
            if (result != null && result is Map<String, dynamic> && mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF993B3B)),
                ),
              );
              bool success = await ApiService().updatePoem(
                poemId: result['editPoemId'] ?? draft['id'],
                title: result['title'],
                content: result['content'],
                categoryId: result['categoryId'],
                published: result['published'],
              );
              if (mounted) {
                Navigator.pop(context); // Pop loading
                if (success) {
                  _loadDrafts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(T.lang == 'id' ? 'Gagal menyimpan perubahan' : 'Failed to save changes'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red[200]!, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(draft["date_created"]),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                    GestureDetector(
                      onTap: () => _deleteDraft(index),
                      child: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  draft["title"] ?? "Untitled",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    T.getCleanContent(draft["content"] ?? ""),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            T.s("no_drafts"),
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}