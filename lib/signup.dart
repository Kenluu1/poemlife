import 'package:flutter/material.dart';
import 'package:poemlife/signin.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final Color maroon = const Color(0xFF993B3B);
  final Color labelColor = const Color(0xFFB57B7B);

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/logoo.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.history_edu,
                    size: 100,
                    color: Color(0xFF0D5C53),
                  ),
                ),
              ),

              const SizedBox(height: 30),


              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 25),
                      padding: const EdgeInsets.fromLTRB(20, 30, 20, 50),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: maroon.withOpacity(0.6), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 30),

                          _buildCustomTextField(
                            label: "Username",
                            hint: "Name",
                          ),
                          _buildCustomTextField(
                            label: "Email",
                            hint: "email@gmail.com",
                          ),
                          _buildCustomTextField(
                            label: "Student ID",
                            hint: "2702273510",
                          ),
                          _buildCustomTextField(
                            label: "password",
                            hint: "a",
                            isPassword: true,
                          ),
                        ],
                      ),
                    ),


                    Positioned(
                      bottom: 0,
                      child: SizedBox(
                        width: 180,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            //signup
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: maroon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

             
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: labelColor, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInPage()));
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: maroon,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCustomTextField({
    required String label,
    required String hint,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        obscureText: isPassword && _obscurePassword,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: labelColor, fontSize: 14),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.black87.withOpacity(0.7), fontSize: 15),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: maroon.withOpacity(0.5), width: 1.5),
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,
        ),
      ),
    );
  }
}