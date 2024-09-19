import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled/views/studysyncmain.dart';
import '../utils/color.dart';
import '../widgets/Header_Section.dart';
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
  bool isPomodoro = false; // Add this line
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
            'date': (task['date'] is Timestamp)
                ? (task['date'] as Timestamp).toDate()
                : DateFormat('MM-dd-yyyy').parse(task['date']),
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
      isPomodoro = true; // Set to true when starting Pomodoro
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

  void _startButtonTimer() {
    setState(() {
      isPomodoro = false; // Set to false when starting general timer
      _isRunning = true;
      _isPaused = false;
      _seconds = 0; // Start timer from 0
      _isCompleted = false;
    });

    // Start a periodic timer that increments every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++; // Increment the timer by 1 second every tick
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      _timer.cancel();
    });
  }

  void _resumeTimerS() {
    setState(() {
      _isPaused = false;
      _isRunning = true;
    });

    // Resume the timer from where it was paused
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds++;
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

  void _resumeTimerP() {
    setState(() {
      _isPaused = false;
      _isRunning = true;
    });

    // Resume the timer from where it was paused
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

        // Refresh the uncompleted tasks list
        _fetchUncompletedTasks();
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

  void _resetToStartScreen() {
    setState(() {
      _timer.cancel(); // Stop the timer
      _seconds = 0; // Reset the seconds count
      _isRunning = false; // Ensure the timer is not running
      _isPaused = false; // Reset any paused state
      _isCompleted = false; // Mark the task as not completed
    });
  }

  void _onResumeButtonPressed() {
    if (isPomodoro) {
      _resumeTimerP();
    } else {
      _resumeTimerS();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.backgroundColor,
        child: Column(
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
                              // Display the timer
                              Text(
                                _formatTime(_seconds),
                                style: TextStyle(fontSize: 50, color: Colors.white),
                              ),
                              SizedBox(height: 20),

                              // Start button, disabled if task is completed
                              if (!_isRunning && !_isCompleted)
                                ElevatedButton(
                                  onPressed: !_isCompleted ? _startButtonTimer : null, // Disable when completed
                                  child: Text("START"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                              // Pause button
                              if (_isRunning && !_isPaused)
                                ElevatedButton(
                                  onPressed: _pauseTimer,
                                  child: Text("PAUSE"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                              // Resume button
                              if (_isPaused)
                                ElevatedButton(
                                  onPressed: _onResumeButtonPressed,
                                  child: Text(isPomodoro ? 'Resume' : 'Resume'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                              SizedBox(height: 10),

                              // Finish button
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

                              // Wrap for Timer, Stopwatch, Pomodoro (disabled if _isCompleted is true)
                              Wrap(
                                spacing: 8.0, // Adds space between each item
                                children: [
                                  GestureDetector(
                                    onTap: !_isCompleted ? () { _resetToStartScreen(); } : null, // Disable if completed
                                    child: Text(
                                      "TIMER |",
                                      style: TextStyle(
                                        color: _isCompleted ? Colors.grey : Colors.white, // Gray out if disabled
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: !_isCompleted ? () { _resetToStartScreen(); } : null, // Disable if completed
                                    child: Text(
                                      "STOPWATCH |",
                                      style: TextStyle(
                                        color: _isCompleted ? Colors.grey : Colors.white, // Gray out if disabled
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: !_isCompleted ? _startPomodoroTimer : null, // Disable if completed
                                    child: Text(
                                      "POMODORO",
                                      style: TextStyle(
                                        color: _isCompleted ? Colors.grey : Colors.white, // Gray out if disabled
                                      ),
                                    ),
                                  ),
                                ],
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
                            SizedBox(height: 20),
                            Text(
                              "UNCOMPLETED TASKS",
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            SizedBox(height: 10),
                            ...uncompletedTasks.map((task) {
                              return ListTile(
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.circle_outlined,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      task['title'],
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  task['date'] != null ? DateFormat('MM-dd-yyyy').format(task['date']) : 'No date set',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              );
                            }).toList(),
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
      ),
    );
  }
}
