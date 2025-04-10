import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() => _errorMessage = '');

    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'email': _emailController.text.trim(),
        'uid': userCredential.user!.uid,
      });

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginPage()));
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? "Signup failed. Try again.");
    } catch (e) {
      setState(() => _errorMessage = "An unexpected error occurred.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3F1DF), // Light green background
      appBar: AppBar(
        title: const Text("Signup"),
        backgroundColor: const Color(0xFF5A6C57), // Dark green AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_nameController, "Name"),
                const SizedBox(height: 12),
                _buildTextField(_ageController, "Age", isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(_emailController, "Email"),
                const SizedBox(height: 12),
                _buildTextField(_passwordController, "Password",
                    isPassword: true),
                const SizedBox(height: 12),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A6C57), // Dark green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 5, // Adds a shadow effect
                  ),
                  child: const Text(
                    "Signup",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF5A6C57)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5A6C57), // Dark green text
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF5A6C57)), // Dark green
        filled: true,
        fillColor: const Color(0xFF85A98F), // Soft green background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none, // Remove default border
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF5A6C57), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: _getIcon(label), // Adds an icon based on the field
      ),
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    );
  }

  Icon _getIcon(String label) {
    switch (label) {
      case "Name":
        return const Icon(Icons.person, color: Color(0xFF5A6C57));
      case "Age":
        return const Icon(Icons.cake, color: Color(0xFF5A6C57));
      case "Email":
        return const Icon(Icons.email, color: Color(0xFF5A6C57));
      case "Password":
        return const Icon(Icons.lock, color: Color(0xFF5A6C57));
      default:
        return const Icon(Icons.text_fields, color: Color(0xFF5A6C57));
    }
  }
}
