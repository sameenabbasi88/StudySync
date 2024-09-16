import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class TimerProvider with ChangeNotifier {
  final ValueNotifier<Duration> sessionDurationNotifier = ValueNotifier(Duration.zero);
  Timer? _timer;
  DateTime? _startTime;

  TimerProvider() {
    _startTimer();
  }

  void _startTimer() async {
    if (_timer?.isActive ?? false) return;

    _startTime = DateTime.now();

    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      try {
        DocumentSnapshot sessionDoc = await FirebaseFirestore.instance
            .collection('sessionLogs')
            .doc(userId)
            .get();

        if (sessionDoc.exists && sessionDoc.data() != null) {
          Map<String, dynamic> sessionData = sessionDoc.data() as Map<String, dynamic>;
          String previousDurationStr = sessionData['duration'] ?? '0:0:0';
          Duration previousDuration = _parseDuration(previousDurationStr);

          sessionDurationNotifier.value = previousDuration;
        }
      } catch (e) {
        print('Error fetching previous session time: $e');
      }
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      sessionDurationNotifier.value += Duration(seconds: 1);
      _updateSessionTime();
    });
  }

  Future<void> _updateSessionTime() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('sessionLogs')
            .doc(userId)
            .set({
          'userId': userId,
          'startTime': Timestamp.fromDate(_startTime!),
          'duration': '${sessionDurationNotifier.value.inHours}:${sessionDurationNotifier.value.inMinutes % 60}:${sessionDurationNotifier.value.inSeconds % 60}',
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error updating session time: $e');
      }
    }
  }

  void startTimer() {
    _startTimer();
  }

  void stopTimer() {
    _stopTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    _saveSessionTime();
  }

  Future<void> _saveSessionTime() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty && _startTime != null) {
      DateTime endTime = DateTime.now();
      try {
        await FirebaseFirestore.instance.collection('sessionLogs').doc(userId).update({
          'endTime': Timestamp.fromDate(endTime),
        });
        sessionDurationNotifier.value = Duration.zero;
      } catch (e) {
        print('Error saving session time: $e');
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    sessionDurationNotifier.dispose();
    super.dispose();
  }

  Duration _parseDuration(String durationStr) {
    List<String> parts = durationStr.split(':');
    if (parts.length != 3) return Duration.zero;

    int hours = int.tryParse(parts[0]) ?? 0;
    int minutes = int.tryParse(parts[1]) ?? 0;
    int seconds = int.tryParse(parts[2]) ?? 0;

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }
}
