import 'package:flutter/material.dart';

class AddPage extends StatefulWidget {
  const AddPage({Key? key}) : super(key: key);

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final Color maroon = const Color(0xFFA33B3B);

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulasi loading animasi titik selama 1.5 detik
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          onPressed: () => Navigator.pop(context), // Kembali ke Home (Nav Bar muncul lagi)
        ),
        actions: [
          Icon(Icons.skip_previous_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Icon(Icons.pause_circle_outline, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Icon(Icons.skip_next_outlined, color: Colors.grey.shade600),
          const SizedBox(width: 15),
          TextButton(
            onPressed: () {

            },
            child: const Text(
              "Next",
              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading ? _buildLoading() : _buildEditor(),

      bottomNavigationBar: _isLoading ? null : _buildBottomToolbar(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: maroon, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFF29C38), shape: BoxShape.circle)),
        ],
      ),
    );
  }


  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
      child: Column(
        children: [

          TextField(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: maroon,
              fontFamily: 'Serif',
            ),
            decoration: InputDecoration(
              hintText: "The Tittle",
              hintStyle: TextStyle(color: maroon.withOpacity(0.5)),
              border: InputBorder.none,
            ),
          ),

          const SizedBox(height: 10),


          Expanded(
            child: TextField(
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontFamily: 'Serif',
                height: 1.5, // Jarak antar baris (Line height)
              ),
              decoration: InputDecoration(
                hintText: "Write what you feel.",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.lens_blur, color: Colors.purple.shade300),
            const Icon(Icons.sync, color: Colors.black54),
            const Icon(Icons.format_italic, color: Colors.black54),
            const Icon(Icons.format_align_left, color: Colors.black54),
            const Icon(Icons.format_align_right, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}