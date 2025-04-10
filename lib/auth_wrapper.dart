import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'chat_list_page.dart';
import 'login_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _saveTokenToFirestore(user);
      }
    });
  }

  Future<void> _saveTokenToFirestore(User user) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      DocumentReference userDoc =
      FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userDoc.set({'fcmToken': token}, SetOptions(merge: true));
      print("FCM Token saved to Firestore: $token");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return snapshot.hasData ? ChatListPage() : LoginPage();
      },
    );
  }
}
