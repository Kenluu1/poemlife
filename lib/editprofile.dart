import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryMaroon = Color(0xFF8B2B32);
  static const Color accentOranye = Color(0xFFE4A25A);
  static const Color accentMerah = Color(0xFFD4314E);
  static const Color disabledAbu = Color(0xFFE2E2E2);
  static const Color disabledTeksAbu = Color(0xFFAFAFAF);
  static const Color inputBorderWarna = Color(0xFFC39395);
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool _isLoadingInitialPage = true;
  bool _hasChanges = false;
  bool _isSavingLoading = false;


  final String _defaultUsername = "Kenluu";
  final String _defaultNIM = "2702273510";
  final String _defaultEmail = "kenluu@gmail.com";
  final String _defaultBio = "Two roads diverged in a wood, and I— I took the one less traveled by, And that has made all the difference.";


  late TextEditingController _usernameController;
  late TextEditingController _nimController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: _defaultUsername);
    _nimController = TextEditingController(text: _defaultNIM);
    _emailController = TextEditingController(text: _defaultEmail);
    _bioController = TextEditingController(text: _defaultBio);

    _usernameController.addListener(_checkChanges);
    _nimController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);
    _bioController.addListener(_checkChanges);

    _startInitialLoad();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _startInitialLoad() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isLoadingInitialPage = false;
      });
    }
  }

  void _checkChanges() {
    setState(() {
      _hasChanges = _usernameController.text != _defaultUsername ||
          _nimController.text != _defaultNIM ||
          _emailController.text != _defaultEmail ||
          _bioController.text != _defaultBio;
    });
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      bool discard = await _showDiscardChangesDialog();
      return discard;
    }
    return true;
  }

  Future<bool> _showDiscardChangesDialog() async {
    bool discard = false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  discard = true;
                  Navigator.pop(context);
                },
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Discard',
                      style: TextStyle(
                        color: AppColors.accentMerah,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.grey),
              InkWell(
                onTap: () {
                  discard = false;
                  Navigator.pop(context);
                },
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
    return discard;
  }

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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _isLoadingInitialPage
            ? null
            : AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              _onWillPop().then((discard) {
                if (discard) Navigator.pop(context);
              });
            },
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoadingInitialPage
            ? _buildLoadingInitialPage()
            : Stack(
          children: [
            _buildEditProfileForm(),
            if (_hasChanges && ModalRoute.of(context)?.isCurrent == false)
              Container(
                color: Colors.black.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingInitialPage() {
    return Center(
      child: _buildDotLoadingWidget(),
    );
  }

  Widget _buildEditProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 24),
          _buildFormInputs(),
          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return LayoutBuilder(builder: (context, constraints) {
      final double coverHeight = constraints.maxWidth * 0.45;
      final double avatarRadius = constraints.maxWidth * 0.15;

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: constraints.maxWidth,
                height: coverHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                  /*
                  image: const DecorationImage(
                    image: AssetImage('assets/cover_placeholder.png'),
                    fit: BoxFit.cover,
                  ),
                  */
                ),
                child: const Center(child: Text("Cover Image")), // Hapus ini kalau pakai gambar asli
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: _buildCameraButtonWidget(),
              ),
            ],
          ),
          Positioned(
            bottom: -avatarRadius / 2,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: constraints.maxWidth * 0.15 - 4,
                    backgroundColor: Colors.grey[400],
                    /*
                    backgroundImage: const AssetImage('assets/profile_placeholder.png'),
                    */
                    child: const Icon(Icons.person, color: Colors.white, size: 40), // Hapus ini kalau pakai gambar asli
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: _buildCameraButtonWidget(),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCameraButtonWidget() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.camera_alt_outlined, color: Colors.black87, size: 16),
    );
  }

  Widget _buildFormInputs() {
    return Column(
      children: [
        _buildCustomInputField(controller: _usernameController, label: 'Username', hint: 'David Done'),
        const SizedBox(height: 16),
        _buildCustomInputField(controller: _nimController, label: 'NIM', hint: '1600878967'),
        const SizedBox(height: 16),
        _buildCustomInputField(
            controller: _emailController, label: 'Email', hint: 'anonim@gmail.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildCustomInputField(controller: _bioController, label: 'Bio', hint: 'Two roads diverged...', maxLines: 5),
      ],
    );
  }

  Widget _buildCustomInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.accentMerah,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorderWarna, width: 0.8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.inputBorderWarna, width: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: (_hasChanges && !_isSavingLoading) ? _onSavePressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _hasChanges ? AppColors.primaryMaroon : AppColors.disabledAbu,
        disabledBackgroundColor: AppColors.disabledAbu,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: _hasChanges ? 2 : 0,
      ),
      child: _isSavingLoading
          ? _buildDotLoadingWidget(forButton: true)
          : Text(
        'Save',
        style: TextStyle(
          color: _hasChanges ? Colors.white : AppColors.disabledTeksAbu,
          fontSize: 16,
          fontWeight: FontWeight.bold,
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
          decoration: const BoxDecoration(
            color: AppColors.accentOranye,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: forButton ? 6 : 8),
        Container(
          width: forButton ? 8 : 12,
          height: forButton ? 8 : 12,
          decoration: const BoxDecoration(
            color: AppColors.accentMerah,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}