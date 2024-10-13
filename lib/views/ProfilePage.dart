import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import '../providers/Friend_Provider.dart';
import 'SigninPage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _profilePhotoUrl = 'data:image/jpeg;base64,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'; // Placeholder

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
      _usernameController.text = data['username'] ?? 'Unknown User';
      _favoriteSubjectController.text = data['favoriteSubject'] ?? 'Not set';
      setState(() {
        _profilePhotoUrl = data['profilePhotoUrl'] ?? 'https://via.placeholder.com/150';
      });
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
                controller: TextEditingController()..text = DateFormat('yyyy-MM-dd').format(DateTime.now()),
                decoration: InputDecoration(labelText: 'Joined Date'),
                enabled: false,
              ),
              TextField(
                controller: TextEditingController()..text = 'Your Group Names Here',
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
  Future<void> logout(BuildContext context) async {
    try {
      // Sign out the user
      await FirebaseAuth.instance.signOut();

      // Update online status in Firestore
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isOnline': false,
        });
      }

      // Navigate to login page
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>StudySyncLoginApp()));
    } catch (e) {
      print('Error during logout: $e');
    }
  }


  Future<void> _pickAndUploadImage() async {
    try {
      // For Flutter web, use HTML file input
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final reader = html.FileReader();
        reader.readAsArrayBuffer(files[0]);
        reader.onLoadEnd.listen((e) async {
          final imageData = reader.result as Uint8List;

          // Validate image data (optional)
          if (imageData.length < 8 || imageData[0] != 0xFF || imageData[1] != 0xD8) {
            print('Selected file is not a valid image.');
            return;
          }

          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_photos/${_auth.currentUser!.uid}.jpg');

          final uploadTask = storageRef.putData(imageData);
          final snapshot = await uploadTask;

          // Get the download URL
          String imageUrl = await snapshot.ref.getDownloadURL();

          // Update the profile photo URL in Firestore
          await _updateProfilePhotoUrl(imageUrl);

          // Update the local state
          setState(() {
            _profilePhotoUrl = imageUrl; // This will now show the updated image
          });
        });
      });
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
          body:Padding(
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
                                      ),
                                      child: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: _profilePhotoUrl.isNotEmpty
                                              ? _profilePhotoUrl
                                              : 'https://via.placeholder.com/150',
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              CircularProgressIndicator(),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.error, color: Colors.red),
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

                                  final userDoc = snapshot.data!.data() as Map<String, dynamic>;
                                  Timestamp timestamp = userDoc.containsKey('date') ? userDoc['date'] : Timestamp.now();
                                  DateTime joinedDate = timestamp.toDate();
                                  String formattedDate = DateFormat('yyyy-MM-dd').format(joinedDate);

                                  String profilePhotoUrl = userDoc.containsKey('profilePhotoUrl') ? userDoc['profilePhotoUrl'] : 'https://via.placeholder.com/150';

                                  List<dynamic> joinedGroups = userDoc.containsKey('joinedgroup') ? userDoc['joinedgroup'] : [];
                                  List<String> groupNames = joinedGroups.map((group) {
                                    if (group is Map<String, dynamic> && group.containsKey('groupName')) {
                                      return group['groupName'] as String;
                                    }
                                    return 'Unknown Group';
                                  }).toList();
                                  String groupsList = groupNames.join(', ');

                                  // Fetch the streak number
                                  int streakNumber = userDoc.containsKey('streakNumber') ? userDoc['streakNumber'] : 0; // Default to 0 if not set

                                  return Container(
                                    padding: EdgeInsets.all(8), // Increased padding for better touch targets
                                    color: Colors.grey[300],
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Username: ${userDoc.containsKey('username') ? userDoc['username'] : 'Unknown User'}',
                                                style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 18, // Smaller text for mobile
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis, // Prevent overflow
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Colors.blue),
                                              onPressed: _editProfile,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4), // Space between elements
                                        Text(
                                          'Joined: $formattedDate',
                                          style: TextStyle(fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 16, color: Colors.black87),
                                        ),
                                        Text(
                                          'In Groups: $groupsList',
                                          style: TextStyle(fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 16, color: Colors.black87),
                                        ),
                                        // Display the streak number
                                        Text(
                                          'Streak Number: $streakNumber',
                                          style: TextStyle(fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 16, color: Colors.black87),
                                        ),
                                        Spacer(),
                                        ElevatedButton(
                                          onPressed: () => logout(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF800000), // Maroon background color
                                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Adjust padding
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8), // Rounded corners
                                            ),
                                          ),
                                          child: Text(
                                            'Logout',
                                            style: TextStyle(
                                              color: Colors.white, // White text color
                                              fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16, // Smaller text for mobile
                                              fontWeight: FontWeight.bold, // Bold text
                                            ),
                                          ),
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
                // Only show the added friends section if not on mobile
                if (MediaQuery.of(context).size.width > 600) ...[
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
                          friendProvider.buildAddedFriendsList(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        );
      },
    );
  }
}
