import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void signOut(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    // Colors based on theme mode
    Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.green[50]!;
    Color cardColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color buttonColor = isDarkMode ? Colors.green[700]! : Colors.green[600]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: buttonColor,
        centerTitle: true,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert), // Three-dot menu
            onSelected: (value) {
              if (value == 1) {
                signOut(context); // Logout action
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 1,
                child: TextButton.icon(
                  onPressed: () => signOut(context),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Logout", style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          // Profile Picture
          CircleAvatar(
            radius: 50,
            backgroundColor: buttonColor,
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 15),

          // User Info Card
          Card(
            color: cardColor,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileDetail("Email", _auth.currentUser?.email ?? "Guest", textColor),
                ],
              ),
            ),
          ),

          const Spacer(), // Pushes elements to the bottom

          // Dark Mode Toggle (No Text)
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Switch(
              value: isDarkMode,
              activeColor: buttonColor,
              onChanged: (value) => themeProvider.toggleTheme(value),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for profile details
  Widget _buildProfileDetail(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
