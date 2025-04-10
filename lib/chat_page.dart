import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:companio/services/firebase_cm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;

  ChatPage({
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? currentUserId;

  late String receiverToken;

  var senderName;

  @override
  void initState() {
    super.initState();
    _getReceiverToken();
    User? user = _auth.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    } else {
      _auth.authStateChanges().listen((User? user) {
        if (user != null) {
          setState(() {
            currentUserId = user.uid;
          });
        }
      });
    }
  }
  Future<String> _getSenderName() async {
    try {
      // Assuming the user's name is stored in the 'users' collection under their UID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)  // Use the current user's UID
          .get();

      if (userDoc.exists) {
        // Cast the data() result to Map<String, dynamic> to safely access the 'name' field
        var userData = userDoc.data() as Map<String, dynamic>;
        return userData['name'] ?? 'Unknown';
      } else {
        return 'Unknown';  // Return 'Unknown' if the user document doesn't exist
      }
    } catch (e) {
      print("Error fetching sender's name: $e");
      return 'Unknown';  // Return 'Unknown' in case of any errors
    }
  }


  void _getReceiverToken() async {
    try {
      var userDoc = await _firestore.collection('users').doc(widget.receiverId).get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          receiverToken = userDoc['fcmToken'];  // Assuming FCM token is stored in the 'fcmToken' field
        });
      } else {
        print("Receiver token not found!");
      }
    } catch (e) {
      print("Error fetching receiver token: $e");
    }
  }

  void sendMessage() async {
    if (currentUserId == null) {
      print("Error: User is not authenticated.");
      return;
    }

    String messageText = messageController.text.trim();
    if (messageText.isNotEmpty) {
      try {
        DateTime now = DateTime.now();
        Timestamp timestamp = Timestamp.fromDate(now);

        // Get the sender's name
        String senderName = await _getSenderName();  // Fetch the sender's name

        Map<String, dynamic> messageData = {
          'senderId': currentUserId,
          'receiverId': widget.receiverId,
          'text': messageText,
          'timestamp': timestamp,
        };

        // Send the notification with the correct arguments
        await FirebaseCM.sendTokenNotification(
            receiverToken,
            "Message from $senderName",   // Title: "Message from [senderName]"
            messageText,                   // Message content
            senderName                     // The sender's name
        );

        // Store message in Firestore
        await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .add(messageData);

        // Update last message in chat document
        await _firestore.collection('chats').doc(widget.chatId).set({
          'lastMessage': messageText,
          'timestamp': timestamp,
        }, SetOptions(merge: true));

        messageController.clear();
      } catch (e) {
        print("Error sending message: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var messageData = snapshot.data!.docs[index];
                    bool isMe = messageData['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: isMe ? Radius.circular(12) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageData['text'],
                              style: TextStyle(color: isMe ? Colors.white : Colors.black),
                            ),
                            SizedBox(height: 5),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                _formatTimestamp(messageData['timestamp']),
                                style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    DateTime date = timestamp.toDate();
    return "${date.hour}:${date.minute < 10 ? '0' : ''}${date.minute}";
  }
}
