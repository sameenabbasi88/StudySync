import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DailyStreakSection extends StatefulWidget {
  @override
  _DailyStreakSectionState createState() => _DailyStreakSectionState();
}

class _DailyStreakSectionState extends State<DailyStreakSection> {
  int streakNumber = 0;

  @override
  void initState() {
    super.initState();
    _fetchStreakNumber();
  }
  Future<void> _fetchStreakNumber() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      try {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

        if (userSnapshot.exists && userSnapshot.data() != null) {
          Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

          DateTime lastStreakUpdate = userData['lastStreakUpdate'] != null
              ? (userData['lastStreakUpdate'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          DateTime currentTime = DateTime.now();
          Duration difference = currentTime.difference(lastStreakUpdate);

          if (difference.inHours >= 24) {
            int newStreakNumber = (userData['streakNumber'] ?? 0) + 1;

            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'streakNumber': newStreakNumber,
              'lastStreakUpdate': Timestamp.fromDate(currentTime),
            });

            if (mounted) {
              setState(() {
                streakNumber = newStreakNumber;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                streakNumber = userData['streakNumber'] ?? 0;
              });
            }
          }
        }
      } catch (e) {
        print('Error fetching streak: $e');
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY STREAK: $streakNumber 🔥',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          '* Streak counter: Increases with consecutive daily logins. Resets if a day is missed.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}