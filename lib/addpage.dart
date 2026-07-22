import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:poemlife/API.dart';
import 'package:audioplayers/audioplayers.dart';
import 'translation.dart';
import 'previewpage.dart';

class AddPage extends StatefulWidget {
  final Map<String, dynamic> selectedCategory;
  final String? initialTitle;
  final String? initialContent;
  final int? editPoemId;
  final bool autoPushPreview;

  const AddPage({
    Key? key,
    required this.selectedCategory,
    this.initialTitle,
    this.initialContent,
    this.editPoemId,
    this.autoPushPreview = false,
  }) : super(key: key);

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
  TextAlign _textAlign = TextAlign.left;
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

    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialContent != null) {
      _contentController.text = T.getCleanContent(widget.initialContent!);
      _textAlign = T.getTextAlign(widget.initialContent!);
    }
    
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      _onNextSong();
    });

    _fetchSongsFromApi(catId);

    _undoStack.add(_contentController.text);
    _contentController.addListener(_onContentChanged);

    if (widget.autoPushPreview) {
      _isInitialLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onNextPressed(immediate: true);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _isInitialLoading = false;
          });
        }
      });
    }
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
        if (!widget.autoPushPreview) {
          _playSongAtIndex(0);
        }
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
      if (selection.start > 0 && !text[selection.start - 1].contains(RegExp(r'\s'))) {
        insertion = ' $insertion';
      }
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
      if (text.isNotEmpty && !text.endsWith(' ') && !text.endsWith('\n')) {
        insertion = ' $insertion';
      }
      _contentController.text = text + insertion;
    }
  }

  void _showWordBankBottomSheet() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _WordBankDialog(
          wordBank: _wordBank,
          initialCategory: widget.selectedCategory,
          onAddWords: (selectedWords) {
            if (selectedWords.isNotEmpty) {
              final wordsToInsert = selectedWords.join(' ');
              _insertWord(wordsToInsert);
            }
          },
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

  Future<void> _insertAiText(String word) async {
    final text = _contentController.text;
    final selection = _contentController.selection;
    String insertion = word;

    // Check if we need to add a space at the beginning of the insertion
    if (text.isNotEmpty &&
        !text.endsWith(' ') &&
        !text.endsWith('\n') &&
        !word.startsWith(' ')) {
      insertion = ' ' + word;
    }

    // Determine the base index of where we are inserting
    int insertIndex = selection.start >= 0 ? selection.start : text.length;
    int selectionEnd = selection.end >= 0 ? selection.end : text.length;

    // Set editing mode to read-only during typewriter animation so user does not interrupt it
    setState(() {
      _isReadOnly = true;
    });

    String currentTextBefore = text.substring(0, insertIndex);
    String currentTextAfter = text.substring(selectionEnd);

    // Let's type character by character
    for (int i = 0; i < insertion.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 50)); // typing speed: 50ms per character
      
      final currentInsertion = insertion.substring(0, i + 1);
      final newText = currentTextBefore + currentInsertion + currentTextAfter;
      
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: insertIndex + currentInsertion.length,
        ),
      );
    }

    // Reset read-only mode
    if (mounted) {
      setState(() {
        _isReadOnly = false;
      });
    }
  }

  Future<void> _generateAiPoem() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.lang == 'id' ? 'Silakan tulis sesuatu terlebih dahulu.' : 'Please write something first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show custom loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF993B3B),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    T.lang == 'id' ? 'Menghasilkan puisi...' : 'Generating poem...',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final generated = await ApiService().generatePoem(text);
      
      // Dismiss progress dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (generated != null && generated.isNotEmpty) {
        await _insertAiText(generated);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(T.lang == 'id' ? 'Gagal menghasilkan kelanjutan puisi.' : 'Failed to generate continuation.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop the dialog
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(T.lang == 'id' ? 'Terjadi kesalahan.' : 'An error occurred.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    return await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Save as Draft",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "It's ok if you want to take a break from writing this poem. Do you want to save this poem as draft ?",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
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
                        bool success;
                        if (widget.editPoemId != null) {
                          success = await ApiService().updatePoem(
                            poemId: widget.editPoemId!,
                            title: _titleController.text.isEmpty
                                ? T.s('untitled')
                                : _titleController.text,
                            content:
                                alignPrefix +
                                (_contentController.text.isEmpty
                                    ? T.s('default_poem_content')
                                    : _contentController.text),
                            categoryId:
                                widget.selectedCategory['id'] ?? 1,
                            published: 0,
                          );
                        } else {
                          success = await ApiService().createPoem(
                            title: _titleController.text.isEmpty
                                ? T.s('untitled')
                                : _titleController.text,
                            content:
                                alignPrefix +
                                (_contentController.text.isEmpty
                                    ? T.s('default_poem_content')
                                    : _contentController.text),
                            categoryId:
                                widget.selectedCategory['id'] ?? 1,
                            published: 0,
                          );
                        }
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF993B3B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        "Don't Save",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  void _onNextPressed({bool immediate = false}) async {
    // Stop the audio player
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }

    setState(() {
      _isNextLoading = true;
    });

    if (!immediate) {
      await Future.delayed(const Duration(seconds: 2));
    }

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
            editPoemId: widget.editPoemId,
          ),
        ),
      );

      // When popping back to AddPage, resume the song!
      if (mounted) {
        _playSongAtIndex(_currentSongIndex);
      }

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
                  onPressed: _showLoading ? null : () => _onNextPressed(),
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
            // Button 1: Gemini AI
            IconButton(
              icon: Image.asset(
                'assets/aibutton.png',
                width: 24,
                height: 24,
              ),
              onPressed: _generateAiPoem,
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

class _WordBankDialog extends StatefulWidget {
  final List<dynamic> wordBank;
  final Map<String, dynamic>? initialCategory;
  final Function(List<String> selectedWords) onAddWords;

  const _WordBankDialog({
    super.key,
    required this.wordBank,
    this.initialCategory,
    required this.onAddWords,
  });

  @override
  State<_WordBankDialog> createState() => _WordBankDialogState();
}

class _WordBankDialogState extends State<_WordBankDialog> {
  final Color maroon = const Color(0xFFA33B3B);

  final List<String> _categories = [
    'Healing Words',
    'Hurting Words',
  ];

  late String _selectedCategory;
  List<Map<String, dynamic>> _displayedWords = [];
  final Set<String> _checkedWords = {};

  @override
  void initState() {
    super.initState();
    _initCategory();
    _updateDisplayedWords();
  }

  void _initCategory() {
    String target = 'Hurting Words';
    if (widget.initialCategory != null) {
      final name = widget.initialCategory!['name']?.toString().toLowerCase() ?? '';
      final id = widget.initialCategory!['id'];
      if (id == 1 || name.contains('heal') || name.contains('happy')) {
        target = 'Healing Words';
      } else if (id == 2 || name.contains('hurt') || name.contains('sad')) {
        target = 'Hurting Words';
      }
    }
    _selectedCategory = target;
  }

  List<Map<String, dynamic>> _getFilteredWords() {
    final int targetCatId = _selectedCategory == 'Healing Words' ? 1 : 2;

    final filtered = widget.wordBank.where((raw) {
      if (raw is Map) {
        final catId = raw['category_id'];
        if (catId != null) {
          return int.tryParse(catId.toString()) == targetCatId;
        }
      }
      return true;
    }).map((e) => Map<String, dynamic>.from(e)).toList();

    return filtered;
  }

  void _updateDisplayedWords() {
    final pool = _getFilteredWords();
    pool.shuffle(Random());
    setState(() {
      _displayedWords = pool.take(5).toList();
    });
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
        _checkedWords.clear();
      });
      _updateDisplayedWords();
    }
  }

  void _showExplanationDialog(BuildContext context, Map<String, dynamic> item) {
    final eng = item['word_eng']?.toString() ?? item['word']?.toString() ?? '';
    final ind = item['word_id']?.toString() ?? item['translation']?.toString() ?? '';
    final expEng = item['explain_eng']?.toString() ?? '';
    final expInd = item['explain_id']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title + Close Icon (X)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Word Explanation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5D5454),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // English Section
                Text(
                  eng,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: maroon,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"$expEng"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: Colors.grey[400]),
                const SizedBox(height: 16),
                // Indonesian Section
                Text(
                  ind,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: maroon,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"$expInd"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: Colors.grey[400]),
                const SizedBox(height: 20),
                // Understood Button
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Text(
                        'Understood',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: maroon,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Hard to find the right\nwords ?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.2,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              'Find the right word bellow to express\nyour feeling.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            // Category Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => _onCategorySelected(cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.only(bottom: 4),
                      decoration: isSelected
                          ? BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: maroon,
                                  width: 2.0,
                                ),
                              ),
                            )
                          : null,
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? maroon : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Words List Container (Pink Tinted Box)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _displayedWords.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'No words available for this category',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: List.generate(_displayedWords.length, (index) {
                        final item = _displayedWords[index];
                        final wordEng = item['word_eng']?.toString() ?? item['word']?.toString() ?? '';
                        final isChecked = _checkedWords.contains(wordEng);
                        final isLast = index == _displayedWords.length - 1;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  // Word Title
                                  Text(
                                    wordEng,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Question mark icon button (?)
                                  GestureDetector(
                                    onTap: () => _showExplanationDialog(context, item),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black87,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Checkbox
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: isChecked,
                                      activeColor: maroon,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      side: const BorderSide(
                                        color: Colors.black54,
                                        width: 1.5,
                                      ),
                                      onChanged: (bool? val) {
                                        setState(() {
                                          if (val == true) {
                                            _checkedWords.add(wordEng);
                                          } else {
                                            _checkedWords.remove(wordEng);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Colors.grey[350],
                              ),
                          ],
                        );
                      }),
                    ),
            ),
            const SizedBox(height: 20),
            // Bottom Bar: Refresh Icon (Left) & Cancel/Add Buttons (Right)
            Row(
              children: [
                // Refresh Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.black87,
                    size: 24,
                  ),
                  onPressed: _updateDisplayedWords,
                ),
                const Spacer(),
                // Cancel Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Add Button
                GestureDetector(
                  onTap: () {
                    if (_checkedWords.isNotEmpty) {
                      widget.onAddWords(_checkedWords.toList());
                    } else if (_displayedWords.isNotEmpty) {
                      final firstWord = _displayedWords.first['word_eng']?.toString() ?? '';
                      if (firstWord.isNotEmpty) {
                        widget.onAddWords([firstWord]);
                      }
                    }
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: maroon,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
