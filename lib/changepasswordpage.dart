import 'dart:async';
import 'package:flutter/material.dart';
import 'package:poemlife/API.dart';
import 'translation.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final Color maroon = const Color(0xFF993B3B);
  final Color orange = const Color(0xFFF29C38);

  bool _isLoading = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Simulate initial loading animation delay (1.5 seconds)
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      T.s('discard'),
                      style: TextStyle(
                        color: maroon,
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

  void _handleChangePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.s("password_guideline_error")),
          backgroundColor: maroon,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.s("passwords_do_not_match")),
          backgroundColor: maroon,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await ApiService().changePassword(newPassword);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.s("password_update_success")),
          backgroundColor: maroon,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(T.s("password_update_fail")),
          backgroundColor: maroon,
        ),
      );
    }
  }

  Widget _buildLoadingView() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: maroon, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: orange, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_newPasswordController.text.isNotEmpty ||
            _confirmPasswordController.text.isNotEmpty) {
          final shouldPop = await _showDiscardChangesDialog();
          if (shouldPop && mounted) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _isLoading
            ? null
            : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () async {
                    if (_newPasswordController.text.isNotEmpty ||
                        _confirmPasswordController.text.isNotEmpty) {
                      final shouldPop = await _showDiscardChangesDialog();
                      if (shouldPop && mounted) {
                        Navigator.pop(context);
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                title: Text(
                  T.s("change_password"),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
              ),
        body: _isLoading
            ? _buildLoadingView()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      T.s("password_guideline"),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Inputs Container
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: maroon.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // New Password
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  T.s("new_password"),
                                  style: TextStyle(
                                    color: maroon,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNew,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 4,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(
                                        () => _obscureNew = !_obscureNew,
                                      ),
                                      child: Icon(
                                        _obscureNew
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1.2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  T.s("confirm_password"),
                                  style: TextStyle(
                                    color: maroon,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 4,
                                    ),
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                      child: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          T.s("change_password"),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
