import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendProvider with ChangeNotifier {
  List<String> _addedFriends = [];
  List<Map<String, dynamic>> _friendsList = [];
  List<Map<String, dynamic>> _displayedFriendsList = [];
  String? userEmail;
  String? errorMessage;

  List<String> get addedFriends => _addedFriends;
  List<Map<String, dynamic>> get friendsList => _friendsList;
  List<Map<String, dynamic>> get displayedFriendsList => _displayedFriendsList;
  String? get getErrorMessage => errorMessage;

  FriendProvider() {
    _getUserEmail();
    _fetchFriendsList();
  }

  void _getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email;
      _fetchAddedFriends();
    }
  }

  void _fetchFriendsList() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
    _friendsList = querySnapshot.docs.map((doc) {
      return {
        'name': doc['username'],
        'email': doc['email'],
        'isOnline': doc.data().containsKey('isOnline') ? doc['isOnline'] : false, // Default to false if not present
      };
    }).toList();

    _displayedFriendsList = List.from(_friendsList);
    notifyListeners();
  }



  void _fetchAddedFriends() async {
    if (userEmail != null) {
      final doc = await FirebaseFirestore.instance.collection('friends').doc(userEmail).get();
      if (doc.exists) {
        _addedFriends = List<String>.from(doc['fname'] ?? []);
        notifyListeners();
      }
    }
  }

  void addFriend(String friendName) async {
    if (userEmail != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: friendName)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final friendEmail = querySnapshot.docs.first['email'];

      if (friendEmail == userEmail) {
        errorMessage = 'You cannot add yourself as a friend';
        notifyListeners();
        return;
      }

      if (_addedFriends.contains(friendName)) return;

      final docRef = FirebaseFirestore.instance.collection('friends').doc(userEmail);
      await docRef.set({
        'fname': FieldValue.arrayUnion([friendName])
      }, SetOptions(merge: true));

      _fetchAddedFriends();
      notifyListeners();
    }
  }

  void searchFriends(String query) async {
    if (query.isEmpty) {
      _displayedFriendsList = List.from(_friendsList);
      notifyListeners();
      return;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    _displayedFriendsList = querySnapshot.docs.map((doc) {
      return {
        'name': doc['username'],
        'email': doc['email']
      };
    }).toList();

    notifyListeners();
  }

  Widget buildAddedFriendsList(BuildContext context) {
    return Expanded(
      child: _addedFriends.isEmpty
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
        itemCount: _addedFriends.length,
        itemBuilder: (context, index) {
          final friend = _friendsList.firstWhere(
                (f) => f['name'] == _addedFriends[index],
            orElse: () => {'isOnline': false}, // Default to offline
          );

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  child: Icon(Icons.person, color: Colors.white),
                  backgroundColor: Colors.blue,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: friend['isOnline'] ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              _addedFriends[index],
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

