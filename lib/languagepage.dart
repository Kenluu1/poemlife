import 'package:flutter/material.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final Color maroon = const Color(0xFF993B3B);
  final Color orange = const Color(0xFFF29C38);
  final Color disabledAbu = const Color(0xFFE2E2E2);
  final Color disabledTeksAbu = const Color(0xFFAFAFAF);

  bool _isLoadingInitial = true;
  bool _isSavingLoading = false;

  // Data bahasa
  final String _currentLanguage = "English";
  String _selectedLanguage = "English";

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
    });
  }


  bool get _hasChanges => _selectedLanguage != _currentLanguage;

  void _onSavePressed() async {
    setState(() {
      _isSavingLoading = true;
    });


    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSavingLoading = false;
      });



      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isLoadingInitial
          ? null
          : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Language",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingInitial ? _buildLoadingView() : _buildContentView(),
      bottomNavigationBar: _isLoadingInitial
          ? null
          : Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), // Padding untuk letak tombol
        child: _buildSaveButton(),
      ),
    );
  }


  Widget _buildLoadingView() {
    return Center(
      child: _buildDotLoadingWidget(),
    );
  }


  Widget _buildContentView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Choose your preferred language. Please select\nyour language.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),


          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: maroon.withOpacity(0.5), width: 1.2),
            ),
            child: Column(
              children: [
                _buildLanguageOption("English"),
                const SizedBox(height: 16),
                _buildLanguageOption("Bahasa Indonesia"),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLanguageOption(String languageCode) {
    bool isSelected = _selectedLanguage == languageCode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = languageCode;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              languageCode,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),

            Container(
              width: 20,
              height: 20,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? maroon : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Container(
                decoration: BoxDecoration(
                  color: maroon,
                  shape: BoxShape.circle,
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_hasChanges && !_isSavingLoading) ? _onSavePressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasChanges ? maroon : disabledAbu,
          disabledBackgroundColor: disabledAbu,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isSavingLoading
            ? _buildDotLoadingWidget(forButton: true)
            : Text(
          'Save',
          style: TextStyle(
            color: _hasChanges ? Colors.white : disabledTeksAbu,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


  Widget _buildDotLoadingWidget({bool forButton = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: forButton ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Container(
          width: forButton ? 8 : 12,
          height: forButton ? 8 : 12,
          decoration: BoxDecoration(
            color: orange,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: forButton ? 6 : 8),
        Container(
          width: forButton ? 8 : 12,
          height: forButton ? 8 : 12,
          decoration: BoxDecoration(
            color: maroon,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}