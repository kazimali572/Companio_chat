import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_page.dart';

class DirectMessagesPage extends StatefulWidget {
  @override
  _DirectMessagesPageState createState() => _DirectMessagesPageState();
}

class _DirectMessagesPageState extends State<DirectMessagesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String currentUserId;
  Map<String, String> userCache = {}; // Cache for user names

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid ?? "";
  }

  /// Fetch user data once and cache it
  Future<String> _getUserName(String userId) async {
    if (userCache.containsKey(userId)) return userCache[userId]!;
    try {
      var userDoc = await _firestore.collection('users').doc(userId).get();
      String name = userDoc.exists ? userDoc['name'] ?? "Unknown User" : "Unknown User";
      userCache[userId] = name;
      return name;
    } catch (e) {
      print("Error fetching user name: $e");
      return "Unknown User";
    }
  }

  /// Start a new chat by selecting a user
  void _startNewChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select a User to Chat"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              var users = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();
              if (users.isEmpty) return Center(child: Text("No users available"));

              return ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  var user = users[index].data() as Map<String, dynamic>;
                  String userId = users[index].id;
                  String userName = user['name'] ?? "Unknown";

                  return ListTile(
                    title: Text(userName),
                    onTap: () async {
                      Navigator.pop(context);
                      _navigateToChat(userId, userName);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Get or create a chat and navigate to chat page
  void _navigateToChat(String receiverId, String receiverName) async {
    String chatId = await _getOrCreateChat(receiverId);
    if (chatId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            receiverId: receiverId,
            receiverName: receiverName,
            chatId: chatId,
          ),
        ),
      );
    } else {
      print("Error: Chat ID is empty!");
    }
  }

  /// Get or create a chat between two users
  Future<String> _getOrCreateChat(String receiverId) async {
    try {
      var chatQuery = await _firestore
          .collection('chats')
          .where('users', arrayContains: currentUserId)
          .get();

      for (var doc in chatQuery.docs) {
        var users = List<String>.from(doc['users']);
        if (users.contains(receiverId)) {
          return doc.id; // Return existing chat ID
        }
      }

      // Create a new chat if it doesn't exist
      var newChatRef = await _firestore.collection('chats').add({
        'users': [currentUserId, receiverId],
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessage': "Chat started",
      });

      return newChatRef.id;
    } catch (e) {
      print("Error creating or fetching chat: $e");
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Direct Messages")),
      body: StreamBuilder(
        stream: _firestore
            .collection('chats')
            .where('users', arrayContains: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No previous chats available"));
          }

          var chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              var chatData = chatDocs[index].data() as Map<String, dynamic>;
              var users = chatData['users'] as List<dynamic>;
              var lastMessage = chatData['lastMessage'] ?? "No messages yet";

              if (!users.contains(currentUserId) || users.length < 2) {
                return SizedBox.shrink();
              }

              var chatPartnerId = users.firstWhere((id) => id != currentUserId, orElse: () => "");
              if (chatPartnerId.isEmpty) {
                return SizedBox.shrink();
              }

              return FutureBuilder(
                future: _getUserName(chatPartnerId),
                builder: (context, AsyncSnapshot<String> userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return ListTile(title: Text("Loading..."));
                  }
                  var userName = userSnapshot.data!;

                  return ListTile(
                    title: Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(lastMessage, style: TextStyle(color: Colors.grey)),
                    leading: CircleAvatar(child: Text(userName[0])),
                    onTap: () {
                      _navigateToChat(chatPartnerId, userName);
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        child: Icon(Icons.add),
      ),
    );
  }
}
