import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'community_chat_page.dart';
import 'profile_page.dart';
import 'DirectMessagesPage.dart';

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = "User";
  bool isSearchOpen = false;
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchUserName();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
  }

  void fetchUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      var userData = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        userName = userData.data()?['name'] ?? 'User';
      });
    }
  }

  void toggleSearch() {
    setState(() {
      isSearchOpen = !isSearchOpen;
      if (!isSearchOpen) {
        searchController.clear();
      }
    });
  }

  void addCommunity() async {
    TextEditingController communityController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create Community"),
        content: TextField(
          controller: communityController,
          decoration: InputDecoration(hintText: "Enter community name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (communityController.text.isNotEmpty) {
                try {
                  await _firestore.collection('communities').add({
                    'name': communityController.text,
                    'createdBy': userName,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error adding community: ${e.toString()}")),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Community name cannot be empty")),
                );
              }
            },
            child: Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    Color cardColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color buttonColor = isDarkMode ? Colors.green[700]! : Colors.green[600]!;
    Color iconColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: isSearchOpen
            ? TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: "Search communities...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
        )
            : Text("Welcome back, $userName 👋"),
        backgroundColor: buttonColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isSearchOpen ? Icons.close : Icons.search, color: iconColor),
            onPressed: toggleSearch,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Communities",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: _firestore.collection('communities').snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var communities = snapshot.data!.docs.where((doc) {
                      var communityName = (doc['name'] ?? '').toString().toLowerCase();
                      return communityName.contains(searchQuery);
                    }).toList();

                    return ListView.builder(
                      itemCount: communities.length,
                      itemBuilder: (context, index) {
                        var community = communities[index];
                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(
                              community['name'] ?? 'No Name',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            subtitle: Text(
                              "Created by: ${(community.data() as Map<String, dynamic>).containsKey('createdBy') ? community['createdBy'] : 'Unknown'}",
                              style: TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                            trailing: Icon(Icons.arrow_forward, color: iconColor),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommunityChatPage(
                                    communityId: community.id,
                                    communityName: community['name'],
                                    userName: userName,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: addCommunity,
              backgroundColor: buttonColor,
              child: Icon(Icons.add, color: Colors.white, size: 36),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: buttonColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        items: [

          BottomNavigationBarItem(icon: Icon(Icons.message, size: 32, color: iconColor), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 32, color: iconColor), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle, size: 32, color: iconColor), label: "Profile"),
        ],
          onTap: (index) {
            if (index == 1) toggleSearch();
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DirectMessagesPage()),
              );
            }
            if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            }
          }

      ),
    );
  }
}
