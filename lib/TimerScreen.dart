import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled/studysyncmain.dart';

import 'Friendpage.dart';
import 'GroupsPage.dart';
import 'ProfilePage.dart'; // Import the file containing HeaderSection

class TimerScreen extends StatefulWidget {
  final String taskTitle;
  final DateTime taskDate;

  TimerScreen({required this.taskTitle, required this.taskDate});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late Timer _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCompleted = false; // New state variable

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    final monthName = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][now.month - 1];

    return 'Today, $day $monthName $year';
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _isCompleted = false; // Reset completion status when starting the timer
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      _timer.cancel();
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
    _startTimer();
  }

  void _completeTask() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _timer.cancel();
      _isCompleted = true; // Set task as completed
    });
  }

  void _handleLinkPress(String link) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          switch (link) {
            case 'studysync':
              return StudySyncDashboard(userId: ''); // Pass the userId or modify as needed
            case 'friends':
              return FriendsPage();
            case 'groups':
              return GroupsPage();
            case 'profile':
              return ProfilePage();
            default:
              return TimerScreen(taskTitle: '', taskDate: DateTime.now()); // Fallback screen
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HeaderSection(onLinkPressed: _handleLinkPress), // Use HeaderSection here
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getFormattedDate(),
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Timer Section
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xff003039),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_seconds),
                              style: TextStyle(fontSize: 50, color: Colors.white),
                            ),
                            SizedBox(height: 20),
                            if (!_isRunning)
                              ElevatedButton(
                                onPressed: _startTimer,
                                child: Text("START"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            if (_isRunning && !_isPaused)
                              ElevatedButton(
                                onPressed: _pauseTimer,
                                child: Text("PAUSE"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            if (_isPaused)
                              ElevatedButton(
                                onPressed: _resumeTimer,
                                child: Text("RESUME"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            SizedBox(height: 10),
                            if (_isRunning)
                              ElevatedButton(
                                onPressed: _completeTask,
                                child: Text("FINISH"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            SizedBox(height: 10),
                            Text(
                              "Timer is default",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _seconds = 0; // Reset seconds
                                });
                                _startTimer();
                              },
                              child: Text(
                                "TIMER | STOPWATCH | POMODORO",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Tasks Section
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xff003039),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TASK FOR THIS SESSION",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                _isCompleted ? Icons.check_circle : Icons.circle_outlined, // Conditional icon
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Text(
                                widget.taskTitle,
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            DateFormat('EEE, d MMM').format(widget.taskDate),
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AdvertisementSection(),
        ],
      ),
    );
  }
}
