import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:poemlife/API.dart';
import 'package:poemlife/otheruserprofile.dart';
import 'translation.dart';

class TopWritersPage extends StatefulWidget {
  const TopWritersPage({super.key});

  @override
  State<TopWritersPage> createState() => _TopWritersPageState();
}

class _TopWritersPageState extends State<TopWritersPage> {
  final Color maroon = const Color(0xFFA33B3B);
  bool _isLoading = true;
  List<dynamic> _writers = [];
  String _selectedFilter = 'all'; // 'week', 'month', 'year', 'all'
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadWriters();
  }

  Future<void> _loadWriters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService().getTopWriters(
        filter: _activeFilter == 'all' ? null : _activeFilter,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _writers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading top writers: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatFollowersCount(int count) {
    if (count >= 1000000) {
      final double m = count / 1000000.0;
      return m == m.toInt() ? '${m.toInt()}M' : '${m.toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      final double k = count / 1000.0;
      return k == k.toInt() ? '${k.toInt()}K' : '${k.toStringAsFixed(1)}K';
    }
    return '$count';
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      T.s('filter'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterRadioOption(T.s('past_week'), 'week', setModalState),
                  _buildFilterRadioOption(T.s('past_month'), 'month', setModalState),
                  _buildFilterRadioOption(T.s('past_year'), 'year', setModalState),
                  _buildFilterRadioOption(T.s('all_time'), 'all', setModalState),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: maroon),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            setModalState(() {
                              _selectedFilter = 'all';
                            });
                          },
                          child: Text(
                            T.s('reset'),
                            style: TextStyle(
                              color: maroon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: maroon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              _activeFilter = _selectedFilter;
                            });
                            Navigator.pop(context);
                            _loadWriters();
                          },
                          child: Text(
                            T.s('apply'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterRadioOption(String label, String value, StateSetter setModalState) {
    final bool isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setModalState(() {
          _selectedFilter = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? maroon : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: maroon,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
          T.s('top_writers'),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: maroon),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _writers.isEmpty
              ? Center(
                  child: Text(
                    T.s('no_results'),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWriters,
                  color: maroon,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _writers.length,
                    itemBuilder: (context, index) {
                      final writer = Map<String, dynamic>.from(_writers[index]);
                      final String username = writer['fullname'] ?? writer['username'] ?? 'User';
                      final String avatarUrl = (writer['image'] != null && writer['image'].toString().isNotEmpty)
                          ? writer['image'].toString()
                          : 'https://i.pravatar.cc/150?img=${index + 10}';
                      final followersCount = writer['followers_count'] ?? 0;
                      final poemsCount = writer['poems_count'] ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OtherUserProfile(
                                userId: writer['id'],
                                username: writer['username'] ?? '',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: maroon.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: NetworkImage(avatarUrl),
                                onBackgroundImageError: (_, __) {},
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_formatFollowersCount(followersCount)} Followers',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 70,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$poemsCount',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: maroon,
                                      ),
                                    ),
                                    Text(
                                      T.s('poems'),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
