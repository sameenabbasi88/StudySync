import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled/views/studysyncmain.dart';

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
  bool _isCompleted = false;
  List<Map<String, dynamic>> uncompletedTasks = []; // Store uncompleted tasks

  @override
  void initState() {
    super.initState();
    _fetchUncompletedTasks(); // Fetch uncompleted tasks when the screen loads
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Fetch uncompleted tasks from Firebase Firestore
  void _fetchUncompletedTasks() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('todoTasks')
          .doc(userId)
          .get();

      if (docSnapshot.exists) {
        List<dynamic> tasks = docSnapshot.get('Todotasks') ?? [];
        setState(() {
          uncompletedTasks = tasks
              .map((task) => {
            'title': task['title'],
            'date': DateTime.parse(task['date']),
          })
              .toList()
              .where((task) => task['title'] != widget.taskTitle) // Exclude the current task
              .toList();
        });
      }
    }
  }

  // Timer logic
  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60);
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

  // Pomodoro Timer Logic
  void _startPomodoroTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _seconds = 1500; // Set timer to 25 minutes (1500 seconds)
      _isCompleted = false;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        _timer.cancel();
        setState(() {
          _isCompleted = true;
          _isRunning = false;
        });
      }
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
    _startPomodoroTimer();
  }

  void _completeTask() async {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _timer.cancel();
      _isCompleted = true; // Set task as completed
    });

    // Get the current user
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    // Check if the user is logged in
    if (userId.isNotEmpty) {
      // Reference to the user's todoTasks document
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('todoTasks')
          .doc(userId);

      // Get the current task list from the database
      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        List<dynamic> tasks = docSnapshot.get('Todotasks') ?? [];

        // Remove the task from the list by matching the title
        tasks.removeWhere((task) => task['title'] == widget.taskTitle);

        // Update the Firestore document with the new list of tasks
        await docRef.update({
          'Todotasks': tasks,
        });

        // Optionally, show a message when the task is removed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task "${widget.taskTitle}" completed and deleted.')),
        );
      }
    }
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
          HeaderSection(onLinkPressed: _handleLinkPress),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_getFormattedDate(), style: TextStyle(fontSize: 18)),
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
                                onPressed: _startPomodoroTimer,
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
                              onTap: _startPomodoroTimer,
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
                                _isCompleted ? Icons.check_circle : Icons.circle_outlined,
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
                          SizedBox(height: 20),
                          // Uncompleted Tasks Section
                          Text(
                            "UNCOMPLETED TASKS",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: uncompletedTasks.length,
                              itemBuilder: (context, index) {
                                final task = uncompletedTasks[index];
                                return ListTile(
                                  leading: Icon(Icons.circle_outlined, color: Colors.white),
                                  title: Text(
                                    task['title'],
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    DateFormat('EEE, d MMM').format(task['date']),
                                    style: TextStyle(color: Colors.white70),
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
          ),
        ],
      ),
    );
  }
}

// Placeholder for HeaderSection component
class HeaderSection extends StatelessWidget {
  final Function(String) onLinkPressed;

  HeaderSection({required this.onLinkPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      color: Color(0xff003039),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () => onLinkPressed('studysync'),
            child: Text('STUDYSYNC', style: TextStyle(color: Colors.white)),
          ),
          GestureDetector(
            onTap: () => onLinkPressed('friends'),
            child: Text('FRIENDS', style: TextStyle(color: Colors.white)),
          ),
          GestureDetector(
            onTap: () => onLinkPressed('groups'),
            child: Text('GROUPS', style: TextStyle(color: Colors.white)),
          ),
          GestureDetector(
            onTap: () => onLinkPressed('profile'),
            child: Text('PROFILE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
