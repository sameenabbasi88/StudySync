import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/Friend_Provider.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _profilePhotoUrl = 'https://via.placeholder.com/150'; // Placeholder

  // Controllers for the text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _favoriteSubjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _fetchProfileData() async {
    final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      _usernameController.text = data['username'] ?? '';
      _favoriteSubjectController.text = data['favoriteSubject'] ?? '';
    }
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: TextEditingController()..text = DateFormat('yyyy-MM-dd').format(DateTime.now()), // Default to current date
                decoration: InputDecoration(labelText: 'Joined Date'),
                enabled: false,
              ),
              TextField(
                controller: TextEditingController()..text = 'Your Group Names Here', // Example placeholder
                decoration: InputDecoration(labelText: 'Groups'),
                enabled: false,
              ),
              TextField(
                controller: _favoriteSubjectController,
                decoration: InputDecoration(labelText: 'Favorite Subject'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Save changes to Firestore
                final username = _usernameController.text;
                final favoriteSubject = _favoriteSubjectController.text;

                try {
                  await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
                    'username': username,
                    'favoriteSubject': favoriteSubject,
                  });
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error updating profile: $e');
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.bytes != null) {
        final imageData = result.files.single.bytes!;
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_photos/${_auth.currentUser!.uid}.jpg');

        final uploadTask = storageRef.putData(imageData);
        final snapshot = await uploadTask;
        String imageUrl = await snapshot.ref.getDownloadURL();

        await _updateProfilePhotoUrl(imageUrl);

        setState(() {
          _profilePhotoUrl = imageUrl;
        });
      }
    } catch (e) {
      print('Error picking or uploading image: $e');
    }
  }

  Future<void> _updateProfilePhotoUrl(String photoUrl) async {
    try {
      final userDoc = _firestore.collection('users').doc(_auth.currentUser!.uid);
      await userDoc.update({'profilePhotoUrl': photoUrl});
    } catch (e) {
      print('Error updating profile photo URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        final addedFriends = friendProvider.addedFriends;

        return Scaffold(
          appBar: AppBar(
            title: Text('Profile'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xff003039),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: _pickAndUploadImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(_profilePhotoUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData || !snapshot.data!.exists) {
                                    return Center(child: Text('No profile data available'));
                                  }

                                  final userDoc = snapshot.data!;
                                  Timestamp timestamp = userDoc['date'];
                                  DateTime joinedDate = timestamp.toDate();
                                  String formattedDate = DateFormat('yyyy-MM-dd').format(joinedDate);

                                  // Fetch the profile photo URL if it exists, otherwise use a placeholder
                                  String profilePhotoUrl = userDoc['profilePhotoUrl'] ?? 'https://via.placeholder.com/150';

                                  // Fetch the groups from the joinedgroup array, only show 'groupName'
                                  List<dynamic> joinedGroups = userDoc['joinedgroup'] ?? [];
                                  List<String> groupNames = joinedGroups
                                      .map((group) => group['groupName'] as String) // Extract 'groupName'
                                      .toList();
                                  String groupsList = groupNames.join(', '); // Convert to a comma-separated string

                                  return Container(
                                    padding: EdgeInsets.all(16),
                                    color: Colors.grey[300],
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Username: ${userDoc['username'] ?? 'Unknown User'}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Colors.blue),
                                              onPressed: _editProfile,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Joined: $formattedDate', // Joined date
                                          style: TextStyle(fontSize: 16, color: Colors.black87),
                                        ),
                                        Text(
                                          'In Groups: $groupsList', // Groups
                                          style: TextStyle(fontSize: 16, color: Colors.black87),
                                        ),
                                        Text(
                                          'Favorite Subject: ${userDoc['favoriteSubject'] ?? 'Not set'}', // Favorite subject
                                          style: TextStyle(fontSize: 16, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
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
                          'Added Friends (${addedFriends.length})',
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
                              style: TextStyle(fontSize: 16, color: Colors.grey),
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
      },
    );
  }
}

