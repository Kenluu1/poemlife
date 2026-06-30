import 'package:flutter/material.dart';

class AddCategoriesPage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialCategories;

  const AddCategoriesPage({
    super.key,
    this.initialCategories,
  });

  @override
  State<AddCategoriesPage> createState() => _AddCategoriesPageState();
}

class _AddCategoriesPageState extends State<AddCategoriesPage> {
  final List<Map<String, dynamic>> _allCategories = [
    {'id': 1, 'name': 'Sadness'},
    {'id': 2, 'name': 'Happiness'},
    {'id': 3, 'name': 'Anger'},
    {'id': 4, 'name': 'Love'},
    {'id': 5, 'name': 'Longing'},
    {'id': 6, 'name': 'Loneliness'},
    {'id': 7, 'name': 'Memories'},
    {'id': 8, 'name': 'Disappointment'},
  ];

  final List<Map<String, dynamic>> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategories != null) {
      for (var initial in widget.initialCategories!) {
        try {
          var matched = _allCategories.firstWhere(
            (c) => c['id'] == initial['id'] || c['name'] == initial['name']
          );
          _selectedCategories.add(matched);
        } catch (_) {
          _selectedCategories.add(initial);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter out all selected categories from the bottom wrap container options
    final unselectedCategories = _allCategories.where((category) {
      return !_selectedCategories.any((selected) => selected['id'] == category['id']);
    }).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pop(context, _selectedCategories);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context, _selectedCategories);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add categories",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Add or change categories so readers know what your feeling is about.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Selected Categories Area (displays list of selected chips or "No categories")
              Align(
                alignment: Alignment.centerLeft,
                child: _selectedCategories.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300, width: 1.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "No categories",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _selectedCategories.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300, width: 1.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category['name'],
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategories.removeWhere((c) => c['id'] == category['id']);
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 32),

              // Category Options
              const Text(
                "Category",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[200]!, width: 1.5),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: unselectedCategories.map((category) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategories.add(category);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300, width: 1.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category['name'],
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
