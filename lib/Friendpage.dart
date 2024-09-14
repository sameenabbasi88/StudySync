import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import Firebase Auth

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudySync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FriendsPage(),
    );
  }
}

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _usernameController = TextEditingController();
  String? userEmail;  // Use this to store the user's email
  List<Map<String, dynamic>> friendsList = [];
  List<Map<String, dynamic>> displayedFriendsList = [];
  List<String> addedFriends = [];

  @override
  void initState() {
    super.initState();
    _getUserEmail();
    _fetchFriendsList();
  }

  // Fetch the user's email
  void _getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;  // Get the current user
    if (user != null) {
      setState(() {
        userEmail = user.email;  // Set the user's email
      });
      _fetchAddedFriends();  // Fetch friends once email is set
    }
  }

  // Fetch potential friends (mock data for demo purposes)
  void _fetchFriendsList() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
    final fetchedFriendsList = querySnapshot.docs.map((doc) {
      return {
        'name': doc['username'],
      };
    }).toList();

    setState(() {
      friendsList = fetchedFriendsList;
      displayedFriendsList = List.from(friendsList);
    });
  }

  // Fetch added friends from Firestore for the current user
  void _fetchAddedFriends() async {
    if (userEmail != null) {
      final doc = await FirebaseFirestore.instance.collection('friends').doc(userEmail).get();
      if (doc.exists) {
        setState(() {
          addedFriends = List<String>.from(doc['fname'] ?? []);
        });
      }
    }
  }

  // Add friend to Firestore with validation
  // Add friend to Firestore with validation
  void _addFriendToFirestore(String friendName) async {
    if (userEmail != null) {
      // Fetch the friend's email from the database based on the friend's username
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: friendName)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not found.")),
        );
        return;
      }

      final friendEmail = querySnapshot.docs.first['email'];

      // Prevent the user from adding themselves as a friend based on email
      if (friendEmail == userEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You cannot add yourself as a friend.")),
        );
        return;
      }

      // Check if the friend is already added
      if (addedFriends.contains(friendName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$friendName is already in your friends list.")),
        );
        return;
      }

      // Add the friend to Firestore
      final docRef = FirebaseFirestore.instance.collection('friends').doc(userEmail);
      await docRef.set({
        'fname': FieldValue.arrayUnion([friendName])
      }, SetOptions(merge: true));

      // Refresh the added friends list after adding
      _fetchAddedFriends();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$friendName has been added to your friends list.")),
      );
    }
  }


  void _filterFriends() {
    final query = _usernameController.text.toLowerCase();
    setState(() {
      displayedFriendsList = friendsList
          .where((friend) => friend['name'].toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xff003039),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Friends',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Enter Username',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white54,
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      onChanged: (value) => _filterFriends(),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: displayedFriendsList.length,
                        itemBuilder: (context, index) {
                          final friend = displayedFriendsList[index];
                          final name = friend['name'];

                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                              backgroundColor: Colors.blue,
                            ),
                            title: Text(name, style: TextStyle(color: Colors.white)),
                            trailing: IconButton(
                              icon: Icon(
                                addedFriends.contains(name) ? Icons.check_circle : Icons.add_circle,
                                color: addedFriends.contains(name) ? Colors.blue : Colors.green,
                              ),
                              onPressed: () {
                                if (!addedFriends.contains(name)) {
                                  _addFriendToFirestore(name);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xff003039),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Added Friends (${addedFriends.length})',  // Display number of added friends
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: addedFriends.isEmpty
                          ? Center(
                        child: Text(
                          'No friends added',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: addedFriends.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(Icons.person, color: Colors.white),
                              backgroundColor: Colors.blue,
                            ),
                            title: Text(
                              addedFriends[index],
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
