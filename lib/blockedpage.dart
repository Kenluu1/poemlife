import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translation.dart';

class BlockedPage extends StatefulWidget {
  const BlockedPage({Key? key}) : super(key: key);

  @override
  State<BlockedPage> createState() => _BlockedPageState();
}

class _BlockedPageState extends State<BlockedPage> {
  final Color maroon = const Color(0xFF993B3B);
  final Color orange = const Color(0xFFF29C38);

  bool _isLoading = true;
  List<String> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _blockedUsers = prefs.getStringList('blocked_users') ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList('blocked_users') ?? [];
    list.remove(username);
    await prefs.setStringList('blocked_users', list);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$username${T.s('unblocked_success')}"),
          backgroundColor: maroon,
        ),
      );
      _loadBlockedUsers();
    }
  }

  Widget _buildLoadingView() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: maroon, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: orange, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/notfound.png',
              height: 180,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
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
            const SizedBox(height: 32),
            Text(
              T.lang == 'id' ? 'Tidak ada akun yang diblokir' : 'No accounts are blocked',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              T.s("no_blocked_desc"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final blockedUser = _blockedUsers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.shade100, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                child: const Icon(Icons.person, color: Colors.grey, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  blockedUser,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              OutlinedButton(
                onPressed: () => _unblockUser(blockedUser),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: maroon, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  T.s("unblock"),
                  style: TextStyle(color: maroon, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = _buildLoadingView();
    } else if (_blockedUsers.isEmpty) {
      body = _buildEmptyStateView();
    } else {
      body = _buildBlockedList();
    }

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
          T.s("blocked"),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }
}