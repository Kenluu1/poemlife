import 'dart:async';
import 'package:flutter/material.dart';
import 'package:poemlife/API.dart';
import 'package:audioplayers/audioplayers.dart';
import 'translation.dart';
import 'previewpage.dart';

class AddPage extends StatefulWidget {
  final Map<String, dynamic> selectedCategory;
  const AddPage({Key? key, required this.selectedCategory}) : super(key: key);

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

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  List<dynamic> _songs = [];
  int _currentSongIndex = 0;
  StreamSubscription? _playerCompleteSubscription;

  @override
  void initState() {
    super.initState();
    final int catId = widget.selectedCategory['id'] ?? 1;
    _songs = [];
    _currentSongIndex = 0;
    
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      _onNextSong();
    });

    _fetchSongsFromApi(catId);

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

  Future<void> _fetchSongsFromApi(int catId) async {
    try {
      final apiSongs = await ApiService().getSongs(categoryId: catId);
      final filteredSongs = apiSongs.where((song) {
        final songCatId = song['category_id'];
        if (songCatId == null) return false;
        return int.tryParse(songCatId.toString()) == catId;
      }).toList();

      if (filteredSongs.isNotEmpty && mounted) {
        setState(() {
          _songs = filteredSongs;
        });
        _playSongAtIndex(0);
      }
    } catch (e) {
      debugPrint('Error fetching songs from API: $e');
    }
  }

  String _sanitizeDropboxUrl(String url) {
    if (url.contains('dropbox.com')) {
      return url
          .replaceAll('www.dropbox.com', 'dl.dropboxusercontent.com')
          .replaceAll('?dl=1', '')
          .replaceAll('?dl=0', '');
    }
    return url;
  }

  Future<void> _playSongAtIndex(int index) async {
    if (_songs.isEmpty || index < 0 || index >= _songs.length) return;
    final song = _songs[index];
    String url = song['url'] ?? '';
    if (url.isEmpty) return;
    url = _sanitizeDropboxUrl(url);
    try {
      await _audioPlayer.play(UrlSource(url));
      if (mounted) {
        setState(() {
          _currentSongIndex = index;
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _onNextSong() {
    if (_songs.isEmpty) return;
    int nextIndex = (_currentSongIndex + 1) % _songs.length;
    _playSongAtIndex(nextIndex);
  }

  void _onPreviousSong() {
    if (_songs.isEmpty) return;
    int prevIndex = (_currentSongIndex - 1 + _songs.length) % _songs.length;
    _playSongAtIndex(prevIndex);
  }

  void _togglePlayPause() async {
    if (_songs.isEmpty) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      final song = _songs[_currentSongIndex];
      String url = song['url'] ?? '';
      if (url.isNotEmpty) {
        url = _sanitizeDropboxUrl(url);
        try {
          await _audioPlayer.play(UrlSource(url));
          if (mounted) {
            setState(() {
              _isPlaying = true;
            });
          }
        } catch (e) {
          debugPrint('Error playing audio: $e');
        }
      }
    }
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
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        insertion,
      );
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + insertion.length,
        ),
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
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = Map<String, dynamic>.from(
                            _wordBank[index],
                          );
                          final eng = item['word_eng'] ?? '';
                          final ind = item['word_id'] ?? '';
                          final exp =
                              item['explain_eng'] ?? item['explain_id'] ?? '';

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
        _contentController.selection = TextSelection.collapsed(
          offset: previous.length,
        );
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
        _contentController.selection = TextSelection.collapsed(
          offset: next.length,
        );
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
          _isReadOnly
              ? T.s('editing_paused')
              : T.s('editing_resumed'),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                    bottom: 16.0,
                    left: 16.0,
                    right: 16.0,
                  ),
                  child: Column(
                    children: [
                      Text(
                        T.s('save_draft_question'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        T.s('draft_dialog_desc'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
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
                          child: CircularProgressIndicator(
                            color: Color(0xFF993B3B),
                          ),
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
                        title: _titleController.text.isEmpty
                            ? T.s('untitled')
                            : _titleController.text,
                        content:
                            alignPrefix +
                            (_contentController.text.isEmpty
                                ? T.s('default_poem_content')
                                : _contentController.text),
                        categoryId:
                            widget.selectedCategory['id'] ??
                            1, // Selected category
                        published: 0, // 0 = draft
                      );
                      if (context.mounted) {
                        Navigator.pop(context); // Pop loading
                        Navigator.pop(context); // Pop AddPage
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? T.s('draft_save_success')
                                  : T.s('draft_save_fail'),
                            ),
                            backgroundColor: success
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(
                      T.s('save'),
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                    ),
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
                    child: Text(
                      T.s('dont_save'),
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Colors.grey),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      T.s('cancel'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        false;
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
            title: _titleController.text.isEmpty
                ? T.s('default_poem_title')
                : _titleController.text,
            content:
                alignPrefix +
                (_contentController.text.isEmpty
                    ? T.s('default_poem_content')
                    : _contentController.text),
            selectedCategory: widget.selectedCategory,
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
    return ValueListenableBuilder<String>(
      valueListenable: T.languageNotifier,
      builder: (context, lang, child) {
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
                  icon: const Icon(
                    Icons.skip_previous_outlined,
                    color: Colors.black54,
                  ),
                  onPressed: _onPreviousSong,
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: maroon,
                  ),
                  onPressed: _togglePlayPause,
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.skip_next_outlined, color: Colors.black54),
                  onPressed: _onNextSong,
                ),
                const SizedBox(width: 15),
                TextButton(
                  onPressed: _showLoading ? null : _onNextPressed,
                  child: Text(
                    T.s('next'),
                    style: TextStyle(
                      color: _showLoading ? Colors.grey : Colors.black54,
                      fontWeight: FontWeight.bold,
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
      },
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: maroon, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFFF29C38),
              shape: BoxShape.circle,
            ),
          ),
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
              hintText: T.s('title_hint'),
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
                hintText: T.s('write_hint'),
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
            // Button 1: Gemini AI (placeholder)
            IconButton(
              icon: Image.asset(
                'assets/aibutton.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(T.s('gemini_coming_soon')),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
            // Button 2: Word Bank
            IconButton(
              icon: Image.asset(
                'assets/wordbankbutton.png',
                width: 24,
                height: 24,
              ),
              onPressed: _showWordBankBottomSheet,
            ),
            // Button 3: Italic
            IconButton(
              icon: Image.asset(
                'assets/italicbutton.png',
                width: 24,
                height: 24,
                color: _isItalic ? maroon : Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  _isItalic = !_isItalic;
                });
              },
            ),
            // Button 4: Text Left
            IconButton(
              icon: Image.asset(
                'assets/textleftbutton.png',
                width: 24,
                height: 24,
                color: _textAlign == TextAlign.left ? maroon : Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  _textAlign = TextAlign.left;
                });
              },
            ),
            // Button 5: Text Center
            IconButton(
              icon: Image.asset(
                'assets/textcenterbutton.png',
                width: 24,
                height: 24,
                color: _textAlign == TextAlign.center ? maroon : Colors.black54,
              ),
              onPressed: () {
                setState(() {
                  _textAlign = TextAlign.center;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
