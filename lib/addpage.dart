import 'package:flutter/material.dart';
import 'previewpage.dart';

class AddPage extends StatefulWidget {
  const AddPage({Key? key}) : super(key: key);

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final Color maroon = const Color(0xFFA33B3B);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _isInitialLoading = true;
  bool _isNextLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }


  Future<bool> _onWillPop() async {
    return await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 16.0, left: 16.0, right: 16.0),
              child: Column(
                children: const [
                  Text(
                    "Save a draft ?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "If you don't save now, all changes\nwill be lost.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  Navigator.pop(context);
                },
                child: const Text("Save", style: TextStyle(color: Colors.black, fontSize: 16)),
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  Navigator.pop(context);
                },
                child: const Text("Don't Save", style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    ) ?? false;
  }


  void _onNextPressed() async {
    setState(() {
      _isNextLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isNextLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            title: _titleController.text.isEmpty ? "Your Wounds" : _titleController.text,
            content: _contentController.text.isEmpty
                ? "Time doesn't heal wounds\nto make you forget.\n\nIt doesn't heal wounds to\nerase the memories."
                : _contentController.text,
          ),
        ),
      );
    }
  }

  bool get _showLoading => _isInitialLoading || _isNextLoading;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => _onWillPop(),
          ),
          actions: [
            Icon(Icons.skip_previous_outlined, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Icon(Icons.pause_circle_outline, color: Colors.grey.shade600),
            const SizedBox(width: 10),
            Icon(Icons.skip_next_outlined, color: Colors.grey.shade600),
            const SizedBox(width: 15),
            TextButton(
              onPressed: _showLoading ? null : _onNextPressed,
              child: Text(
                "Next",
                style: TextStyle(
                    color: _showLoading ? Colors.grey : Colors.black54,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: _showLoading ? _buildLoading() : _buildEditor(),
        bottomNavigationBar: _showLoading ? null : _buildBottomToolbar(),
      ),
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
            controller: _titleController,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: maroon,
              fontFamily: 'Serif',
            ),
            decoration: InputDecoration(
              hintText: "The Title",
              hintStyle: TextStyle(color: maroon.withOpacity(0.5)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontFamily: 'Serif',
                height: 1.5,
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