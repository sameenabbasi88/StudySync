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
        'email': doc['email']
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
}
