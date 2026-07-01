import 'package:flutter/material.dart';
import 'package:poemlife/API.dart';
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

  bool _isItalic = false;
  TextAlign _textAlign = TextAlign.center;
  List<dynamic> _wordBank = [];

  bool _isReadOnly = false;
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isUndoRedoAction = false;

  @override
  void initState() {
    super.initState();
    _undoStack.add(_contentController.text);
    _contentController.addListener(_onContentChanged);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    });
    _loadWordBank();
  }

  void _onContentChanged() {
    if (_isUndoRedoAction) return;
    final text = _contentController.text;
    if (_undoStack.isEmpty || _undoStack.last != text) {
      if (_undoStack.length > 50) {
        _undoStack.removeAt(0);
      }
      _undoStack.add(text);
      _redoStack.clear();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadWordBank() async {
    try {
      final words = await ApiService().getWordBank();
      if (mounted) {
        setState(() {
          _wordBank = words;
        });
      }
    } catch (_) {}
  }

  void _insertWord(String word) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    String insertion = word;
    
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, insertion);
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + insertion.length),
      );
    } else {
      _contentController.text = text + insertion;
    }
  }

  void _showWordBankBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  'Word Bank / Kosakata',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _wordBank.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: const Center(
                        child: Text(
                          'No words in word bank yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 250,
                      child: ListView.separated(
                        itemCount: _wordBank.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = Map<String, dynamic>.from(_wordBank[index]);
                          final eng = item['word_eng'] ?? '';
                          final ind = item['word_id'] ?? '';
                          final exp = item['explain_eng'] ?? item['explain_id'] ?? '';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '$eng ($ind)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: maroon,
                              ),
                            ),
                            subtitle: exp.isNotEmpty
                                ? Text(
                                    exp,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            onTap: () {
                              _insertWord(eng);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _toggleTranslations() {
    String text = _contentController.text;
    if (text.isEmpty || _wordBank.isEmpty) return;

    for (var rawItem in _wordBank) {
      final item = Map<String, dynamic>.from(rawItem);
      final eng = item['word_eng']?.toString() ?? '';
      final ind = item['word_id']?.toString() ?? '';
      if (eng.isNotEmpty && ind.isNotEmpty) {
        final regEng = RegExp('\\b$eng\\b', caseSensitive: false);
        final regInd = RegExp('\\b$ind\\b', caseSensitive: false);
        
        if (text.toLowerCase().contains(eng.toLowerCase())) {
          text = text.replaceAll(regEng, ind);
        } else if (text.toLowerCase().contains(ind.toLowerCase())) {
          text = text.replaceAll(regInd, eng);
        }
      }
    }
    setState(() {
      _contentController.text = text;
    });
  }

  void _undo() {
    if (_undoStack.length > 1) {
      setState(() {
        _isUndoRedoAction = true;
        final current = _undoStack.removeLast();
        _redoStack.add(current);
        final previous = _undoStack.last;
        _contentController.text = previous;
        _contentController.selection = TextSelection.collapsed(offset: previous.length);
        _isUndoRedoAction = false;
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _isUndoRedoAction = true;
        final next = _redoStack.removeLast();
        _undoStack.add(next);
        _contentController.text = next;
        _contentController.selection = TextSelection.collapsed(offset: next.length);
        _isUndoRedoAction = false;
      });
    }
  }

  void _toggleReadOnly() {
    setState(() {
      _isReadOnly = !_isReadOnly;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isReadOnly ? "Editing paused (Read-only mode)" : "Editing resumed (Edit mode)",
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
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
                onPressed: () async {
                  Navigator.pop(context, true); // Pop dialog
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(color: Color(0xFF993B3B)),
                    ),
                  );
                  String alignPrefix = '';
                  if (_textAlign == TextAlign.left) {
                    alignPrefix = '[align:left]';
                  } else if (_textAlign == TextAlign.right) {
                    alignPrefix = '[align:right]';
                  } else {
                    alignPrefix = '[align:center]';
                  }
                  bool success = await ApiService().createPoem(
                    title: _titleController.text.isEmpty ? "Untitled" : _titleController.text,
                    content: alignPrefix + (_contentController.text.isEmpty
                        ? "Time doesn't heal wounds..."
                        : _contentController.text),
                    categoryId: 1, // Default category
                    published: 0, // 0 = draft
                  );
                  if (context.mounted) {
                    Navigator.pop(context); // Pop loading
                    Navigator.pop(context); // Pop AddPage
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Puisi disimpan sebagai draft!' : 'Gagal menyimpan draft.'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
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

      String alignPrefix = '';
      if (_textAlign == TextAlign.left) {
        alignPrefix = '[align:left]';
      } else if (_textAlign == TextAlign.right) {
        alignPrefix = '[align:right]';
      } else {
        alignPrefix = '[align:center]';
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            title: _titleController.text.isEmpty ? "Your Wounds" : _titleController.text,
            content: alignPrefix + (_contentController.text.isEmpty
                ? "Time doesn't heal wounds\nto make you forget.\n\nIt doesn't heal wounds to\nerase the memories."
                : _contentController.text),
          ),
        ),
      );
      if (result != null && result is Map<String, dynamic> && mounted) {
        Navigator.pop(context, result);
      }
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
            IconButton(
              icon: Icon(
                Icons.skip_previous_outlined,
                color: _undoStack.length > 1 ? maroon : Colors.grey.shade400,
              ),
              onPressed: _undoStack.length > 1 ? _undo : null,
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                _isReadOnly ? Icons.play_circle_outline : Icons.pause_circle_outline,
                color: _isReadOnly ? maroon : Colors.grey.shade600,
              ),
              onPressed: _toggleReadOnly,
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                Icons.skip_next_outlined,
                color: _redoStack.isNotEmpty ? maroon : Colors.grey.shade400,
              ),
              onPressed: _redoStack.isNotEmpty ? _redo : null,
            ),
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
            readOnly: _isReadOnly,
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
              readOnly: _isReadOnly,
              textAlign: _textAlign,
              keyboardType: TextInputType.multiline,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontFamily: 'Serif',
                height: 1.5,
                fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
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
            IconButton(
              icon: Icon(Icons.lens_blur, color: Colors.purple.shade300),
              onPressed: _showWordBankBottomSheet,
            ),
            IconButton(
              icon: const Icon(Icons.sync, color: Colors.black54),
              onPressed: _toggleTranslations,
            ),
            IconButton(
              icon: Icon(
                Icons.format_italic,
                color: _isItalic ? maroon : Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  _isItalic = !_isItalic;
                });
              },
            ),
            IconButton(
              icon: Icon(
                Icons.format_align_left,
                color: _textAlign == TextAlign.left ? maroon : Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  _textAlign = TextAlign.left;
                });
              },
            ),
            IconButton(
              icon: Icon(
                _textAlign == TextAlign.right
                    ? Icons.format_align_right
                    : (_textAlign == TextAlign.center ? Icons.format_align_center : Icons.format_align_justify),
                color: (_textAlign == TextAlign.right || _textAlign == TextAlign.center) ? maroon : Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  if (_textAlign == TextAlign.center) {
                    _textAlign = TextAlign.right;
                  } else {
                    _textAlign = TextAlign.center;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}