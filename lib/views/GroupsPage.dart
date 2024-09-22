import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/Friend_Provider.dart';
import 'GroupsDetail.dart';

class GroupsPage extends StatefulWidget {
  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  Color selectedColor = Colors.red; // Default selected color for group
  TextEditingController groupNameController = TextEditingController();
  TextEditingController searchController = TextEditingController(); // Controller for search
  String? selectedGroup;
  String searchQuery = ''; // Variable to hold search query


  @override
  Widget build(BuildContext context) {
    final friendProvider = Provider.of<FriendProvider>(context);
    final isMobile = MediaQuery.of(context).size.width < 600; // Example breakpoint for mobile

    double groupTitleFontSize = isMobile ? 12 : 16; // Smaller font size for mobile
    double friendTitleFontSize = isMobile ? 16 : 18; // Smaller font size for mobile
    double groupCardFontSize = isMobile ? 12 : 18; // Smaller font size for mobile
    double newGroupButtonFontSize = isMobile ? 12 : 16; // Smaller font size for mobile
    double textFieldFontSize = isMobile ? 12 : 16;

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
                        fontSize: groupTitleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (selectedGroup == null)
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value.toLowerCase();
                          });
                        },
                        style: TextStyle(fontSize: textFieldFontSize),
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

                          final groups = snapshot.data?.docs.where((doc) {
                            final groupName = (doc.data() as Map<String, dynamic>)['groupname'].toString().toLowerCase();
                            return groupName.contains(searchQuery);
                          }).toList() ?? [];

                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: groups.length + 1,
                            itemBuilder: (context, index) {
                              if (index < groups.length) {
                                final group = groups[index].data() as Map<String, dynamic>;
                                return _buildGroupCard(
                                  group['groupname'],
                                  Color(group['color']),
                                  group['groupid'],
                                  groupCardFontSize,
                                );
                              } else {
                                return _buildAddGroupButton(newGroupButtonFontSize);
                              }
                            },
                          );
                        },
                      )
                          : TaskManagerApp(groupId: selectedGroup!),
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
                      'Added Friends (${friendProvider.addedFriends.length})',
                      style: TextStyle(
                        fontSize: friendTitleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    friendProvider.buildAddedFriendsList(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(String groupName, Color color, String groupId, double fontSize) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGroup = groupId;
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
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddGroupButton(double fontSize) {
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
              SizedBox(height: 4),
              Flexible(
                child: Text(
                  'New Group',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
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
