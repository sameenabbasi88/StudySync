import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'GroupsDetail.dart'; // Ensure Firebase is initialized

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase here
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
      home: GroupsPage(),
    );
  }
}

class GroupsPage extends StatefulWidget {
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  List<String> addedFriends = [];
  Color selectedColor = Colors.red; // Default selected color for group
  TextEditingController groupNameController = TextEditingController();
  TextEditingController searchController = TextEditingController(); // Controller for search
  String? selectedGroup;
  String searchQuery = ''; // Variable to hold search query

  @override
  void initState() {
    super.initState();
    _fetchAddedFriends();
  }

  // Fetch added friends for the current user
  void _fetchAddedFriends() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail != null) {
      final doc = await FirebaseFirestore.instance.collection('friends').doc(userEmail).get();
      if (doc.exists) {
        setState(() {
          addedFriends = List<String>.from(doc['fname'] ?? []);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
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
                      'Groups and Friends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 16),

                    // Only show the search bar if no group is selected
                    if (selectedGroup == null)
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search groups',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                    SizedBox(height: 16),

                    Expanded(
                      child: selectedGroup == null
                          ? StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('groups').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(child: Text('No groups found'));
                          }

                          final groups = snapshot.data!.docs
                              .where((doc) {
                            final groupName = (doc.data() as Map<String, dynamic>)['groupname'].toString().toLowerCase();
                            return groupName.contains(searchQuery);
                          }).toList();

                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: groups.length + 1, // Add one for the 'New Group' button
                            itemBuilder: (context, index) {
                              if (index < groups.length) {
                                final group = groups[index].data() as Map<String, dynamic>;
                                return _buildGroupCard(
                                  group['groupname'],
                                  Color(group['color']),
                                  group['groupid'], // Pass the groupid here
                                );
                              } else {
                                return _buildAddGroupButton();
                              }
                            },
                          );
                        },
                      )
                          : TaskManagerApp(groupId: selectedGroup!), // Display TaskManagerApp if a group is selected
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            // The Friends list remains the same
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

  Widget _buildGroupCard(String groupName, Color color, String groupId) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGroup = groupId; // Set the selectedGroup to the groupId
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            groupName,
            style: TextStyle(
              color: color == Colors.white ? Colors.black : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddGroupButton() {
    return GestureDetector(
      onTap: () {
        _showNewGroupPopup(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 30),
              Text(
                'New Group',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewGroupPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xff003039),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Group name',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                TextField(
                  controller: groupNameController,
                  style: TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter group name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Group colour',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    _buildColorOption(Colors.red),
                    SizedBox(width: 8),
                    _buildColorOption(Colors.blue),
                    SizedBox(width: 8),
                    _buildColorOption(Colors.black),
                    SizedBox(width: 8),
                    _buildColorOption(Colors.white),
                    SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow, // Custom color button
                      ),
                      onPressed: () {
                        // Handle custom color selection if needed
                      },
                      child: Text('Custom', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  onPressed: () {
                    _addNewGroup(groupNameController.text, selectedColor);
                    Navigator.of(context).pop();
                  },
                  child: Text('Create New Group', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _addNewGroup(String groupName, Color color) async {
    try {
      // Get the current user's ID
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Create a new document reference
      var docRef = FirebaseFirestore.instance.collection('groups').doc();

      // Add the group data including the generated document ID
      await docRef.set({
        'groupid': docRef.id,  // Use Firestore's auto-generated ID
        'groupname': groupName,
        'color': color.value, // Storing the color as an int value
        'tasks': [], // Initialize an empty tasks array
        'owner': userId, // Store the owner user ID
      });
    } catch (e) {
      print('Error adding group: $e');
    }
  }
}

