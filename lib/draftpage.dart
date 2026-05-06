import 'package:flutter/material.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({Key? key}) : super(key: key);

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> {
  bool _isLoading = true;

//prototype
  List<Map<String, String>> _drafts = [
    {
      "time": "2 hours ago",
      "title": "Untitled",
      "content": "Time doesn't heal wounds...",
    },
    {
      "time": "10 Oktober 2025",
      "title": "Your Words",
      "content": "Time doesn't heal wounds to make you...",
    },
    {
      "time": "10 April 2024",
      "title": "Your Words",
      "content": "No poems",
    },
  ];

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


  void _deleteAll() {
    setState(() {
      _drafts.clear();
    });
  }


  void _deleteDraft(int index) {
    setState(() {
      _drafts.removeAt(index);
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
                    draft["time"]!,
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
                draft["title"]!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                draft["content"]!,
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