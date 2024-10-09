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

          if (difference.inDays > 0) {
            // Reset streak number to 1 if more than 1 day has passed
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'streakNumber': 1, // Resetting the streak to 1
              'lastStreakUpdate': Timestamp.fromDate(currentTime),
            });

            if (mounted) {
              setState(() {
                streakNumber = 1; // Resetting streak in UI
              });
            }
          } else {
            // If the user logged in within the same day, increment the streak
            int currentStreak = userData['streakNumber'] ?? 0;

            if (difference.inHours >= 24) {
              currentStreak += 1; // Increment the streak
              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                'streakNumber': currentStreak,
                'lastStreakUpdate': Timestamp.fromDate(currentTime),
              });

              if (mounted) {
                setState(() {
                  streakNumber = currentStreak;
                });
              }
            } else {
              if (mounted) {
                setState(() {
                  streakNumber = currentStreak; // Keep current streak number
                });
              }
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
