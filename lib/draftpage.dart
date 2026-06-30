import 'package:flutter/material.dart';
import 'package:poemlife/API.dart';

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
        const SnackBar(content: Text('Beberapa draft gagal dihapus')),
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
          const SnackBar(content: Text('Gagal menghapus draft')),
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
        title: const Text(
          "Draft",
          style: TextStyle(
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
              "Delete all",
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
        return Container(
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
              Text(
                draft["content"] ?? "",
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No Drafts",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}