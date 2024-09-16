import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/Friend_Provider.dart'; // Import your FriendProvider

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _joinedDateController = TextEditingController();
  final TextEditingController _groupsController = TextEditingController();
  final TextEditingController _favoriteSubjectController = TextEditingController();

  String _profilePhotoUrl = 'https://via.placeholder.com/150'; // Placeholder

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser.email)
            .get();

        if (userQuery.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userQuery.docs.first;
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

          setState(() {
            _usernameController.text = userDoc['username'];
            _joinedDateController.text = 'Joined: $formattedDate';
            _profilePhotoUrl = profilePhotoUrl;
            _favoriteSubjectController.text = userDoc['favoriteSubject'] ?? ''; // Fetch the favorite subject
            _groupsController.text = groupsList; // Update the groups field
          });
        }
      }
    } catch (error) {
      print('Error fetching user profile: $error');
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid);

        await userDoc.update({
          'username': _usernameController.text,
          'groups': _groupsController.text,
          'favoriteSubject': _favoriteSubjectController.text,
        });

        // Fetch and update profile photo URL if needed
        // await _updateProfilePhotoUrl(_profilePhotoUrl); // Uncomment if you have a separate profile photo URL update function
      }
    } catch (e) {
      print('Error updating user profile: $e');
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
                controller: _joinedDateController,
                decoration: InputDecoration(labelText: 'Joined Date'),
                enabled: false,
              ),
              TextField(
                controller: _groupsController,
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
              onPressed: () {
                _updateUserProfile(); // Save changes to Firestore
                setState(() {}); // Refresh the state
                Navigator.of(context).pop();
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
            .child('profile_photos/${FirebaseAuth.instance.currentUser!.uid}.jpg');

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
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);
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
                              child: Container(
                                padding: EdgeInsets.all(16),
                                color: Colors.grey[300],
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Username: ${_usernameController.text}',
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
                                      _joinedDateController.text,
                                      style: TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                    Text(
                                      'In Groups: ${_groupsController.text}',
                                      style: TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                    Text(
                                      'Favorite Subject: ${_favoriteSubjectController.text}',
                                      style: TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  ],
                                ),
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
