import 'package:flutter/material.dart';
import 'translation.dart';

class PublicationPage extends StatefulWidget {
  final String initialPublication;

  const PublicationPage({
    super.key,
    required this.initialPublication,
  });

  @override
  State<PublicationPage> createState() => _PublicationPageState();
}

class _PublicationPageState extends State<PublicationPage> {
  late String _selectedPublication;

  @override
  void initState() {
    super.initState();
    _selectedPublication = widget.initialPublication;
  }

  Widget _buildOption(String value) {
    bool isSelected = _selectedPublication == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPublication = value;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              T.s(value.toLowerCase().replaceAll(' ', '_')),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF993B3B) : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF993B3B),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        Navigator.pop(context, _selectedPublication);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context, _selectedPublication);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                T.s("select_publication"),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                T.s("select_publication_desc"),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red[200]!, width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildOption("Everyone"),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildOption("Following"),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildOption("Only me"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
