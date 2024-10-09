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
  final String taskId;
  final DateTime taskDate;

  TimerScreen({required this.taskTitle, required this.taskDate, required this.taskId});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCompleted = false;
  bool isPomodoro = false; // Add this line
  String selectedOption = "";
  bool _isStopwatchSelected = false;
  List<Map<String, dynamic>> uncompletedTasks = []; // Store uncompleted tasks

  @override
  void initState() {
    super.initState();
    _fetchUncompletedTasks(); // Fetch uncompleted tasks when the screen loads
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  TextStyle _getTextStyle(String option) {
    return TextStyle(
      fontSize: 12,
      color: _isCompleted ? Colors.grey : Colors.white,
    );
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
    final year = now.year;
    final monthName = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][now.month - 1];

    return 'Today, $day $monthName $year';
  }

  // Pomodoro Timer Logic
  void _setPomodoroTimer() {
    setState(() {
      isPomodoro = true;  // Set to true for Pomodoro mode
      _isRunning = false; // Don't start the timer immediately
      _isPaused = false;
      _seconds = 1500;    // Set timer to 25 minutes (1500 seconds)
      _isCompleted = false;
    });
  }


  void _startButtonTimer() {
    setState(() {
      _isStopwatchSelected = true; // Set to true for stopwatch
      _isRunning = true;
      _isPaused = false;
      _seconds = 0; // Start timer from 0
      _isCompleted = false;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++; // Increment the timer by 1 second every tick
      });
    });
  }

  void _startPomodoroTimer() {
    if (_isRunning || _seconds == 0) return; // Prevent starting if already running

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _seconds = 1500; // Set to 25 minutes for Pomodoro
      _isCompleted = false;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--; // Decrease the time every second
        });
      } else {
        _timer?.cancel();
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
      _isRunning = false; // Mark as not running
      _timer?.cancel(); // Cancel the timer
    });
  }

  void _resumeTimerS() {
    setState(() {
      _isPaused = false;
      _isRunning = true; // Mark as running
    });

    // Resume based on whether it's a stopwatch or pomodoro
    if (isPomodoro) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_seconds > 0) {
          setState(() {
            _seconds--; // Decrement for Pomodoro
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isCompleted = true;
            _isRunning = false;
          });
        }
      });
    } else {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++; // Increment for Stopwatch
        });
      });
    }
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
        _timer?.cancel();
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
      _timer?.cancel();
      _isCompleted = true; // Set task as completed
    });

    // Get the current user
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    // Check if the user is logged in
    if (userId.isNotEmpty) {
      // Reference to the user's todoTasks document
      DocumentReference todoDocRef = FirebaseFirestore.instance
          .collection('todoTasks')
          .doc(userId);

      // Reference to the user's completedTasks document
      DocumentReference completedDocRef = FirebaseFirestore.instance
          .collection('completedTasks')
          .doc(userId);

      // Get the current task list from the database
      DocumentSnapshot todoDocSnapshot = await todoDocRef.get();

      if (todoDocSnapshot.exists) {
        List<dynamic> tasks = todoDocSnapshot.get('Todotasks') ?? [];

        // Find the completed task by matching the title
        Map<String, dynamic>? completedTask;
        tasks.removeWhere((task) {
          if (task['title'] == widget.taskTitle) {
            completedTask = Map<String, dynamic>.from(task); // Create a copy of the task
            return true;
          }
          return false;
        });

        // Update the Firestore document with the new list of tasks
        await todoDocRef.update({
          'Todotasks': tasks,
        });

        // Save the completed task to the completedTasks collection
        if (completedTask != null) {
          DocumentSnapshot completedDocSnapshot = await completedDocRef.get();
          List<dynamic> completedTasks = completedDocSnapshot.exists
              ? completedDocSnapshot.get('completedTasks') ?? []
              : [];

          // Add the completion date to the completed task
          completedTask!['completionDate'] = DateTime.now(); // Using the null check operator

          // Add the completed task to the completedTasks list
          completedTasks.add(completedTask);

          // Update the completedTasks document with the new task
          await completedDocRef.set({
            'completedTasks': completedTasks,
          });
        }

        // Optionally, show a message when the task is moved
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task "${widget.taskTitle}" completed and moved to Completed Tasks.')),
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
              return TimerScreen(taskTitle: '', taskDate: DateTime.now(), taskId: '',); // Fallback screen
          }
        },
      ),
    );
  }

  void _resetToStartScreen() {
    setState(() {
      _timer?.cancel(); // Stop the timer
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

  void _startUserDefinedTimer(int minutes) {
    setState(() {
      _seconds = minutes * 60; // Convert minutes to seconds
      _isRunning = true;
      _isPaused = false;
      _isCompleted = false;
    });

    // Start the countdown logic (e.g., using a Timer)
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        timer.cancel();
        _completeTask(); // Handle task completion
      }
    });
  }

  void _showTimerDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Set Timer"),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: "Enter time in minutes"),
            keyboardType: TextInputType.number,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("CANCEL"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("SET"),
              onPressed: () {
                int minutes = int.tryParse(_controller.text) ?? 25; // Default to 25 minutes if input is invalid
                setState(() {
                  _seconds = minutes * 60; // Convert minutes to seconds
                });
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
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
                child: MediaQuery.of(context).size.width >= 600
                    ?Row(
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
                                style: TextStyle(fontSize: 30, color: Colors.white),
                              ),
                              SizedBox(height: 5),

                              // Start button for Pomodoro
                              if (isPomodoro && !_isRunning && !_isCompleted)
                                ElevatedButton(
                                  onPressed: !_isCompleted ? _startPomodoroTimer : null,
                                  child: Text("START", style: TextStyle(fontSize: 10)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                              // Start button for User Defined Timer
                              if (!isPomodoro && !_isStopwatchSelected && !_isRunning && !_isCompleted)
                                ElevatedButton(
                                  onPressed: !_isCompleted ? () => _showTimerDialog(context) : null,
                                  child: Text("Start", style: TextStyle(fontSize: 10)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                              // Stopwatch Start Button (Step 3: Conditional rendering)
                              if (_isStopwatchSelected && !_isRunning && !_isCompleted)
                                ElevatedButton(
                                  onPressed: !_isCompleted ? _startButtonTimer : null,
                                  child: Text("START STOPWATCH", style: TextStyle(fontSize: 10)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                              // Pause button
                              if (_isRunning && !_isPaused)
                                ElevatedButton(
                                  onPressed: _pauseTimer,
                                  child: Text("PAUSE", style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                              // Resume button
                              if (_isPaused)
                                ElevatedButton(
                                  onPressed: _onResumeButtonPressed,
                                  child: Text('Resume', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                              SizedBox(height: 5),

                              // Finish button
                              if (_isRunning)
                                ElevatedButton(
                                  onPressed: _completeTask,
                                  child: Text("FINISH", style: TextStyle(fontSize: 12)),
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
                                spacing: 8.0,
                                children: [
                                  GestureDetector(
                                    onTap: !_isCompleted
                                        ? () {
                                      setState(() {
                                        selectedOption = "TIMER"; // Update selected option
                                        _showTimerDialog(context);
                                        _isStopwatchSelected = false; // Reset stopwatch selection
                                      });
                                    }
                                        : null,
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        // Underline for selected option
                                        if (selectedOption == "TIMER")
                                          Container(
                                            height: 2,
                                            width: 50, // Adjust width as needed
                                            color: Colors.white,
                                          ),
                                        Text(
                                          "TIMER |",
                                          style: _getTextStyle("TIMER"),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: !_isCompleted
                                        ? () {
                                      setState(() {
                                        selectedOption = "STOPWATCH"; // Update selected option
                                        _isStopwatchSelected = true; // Step 2: Update the stopwatch selection
                                        _resetToStartScreen();
                                      });
                                    }
                                        : null,
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        // Underline for selected option
                                        if (selectedOption == "STOPWATCH")
                                          Container(
                                            height: 2,
                                            width: 80, // Adjust width as needed
                                            color: Colors.white,
                                          ),
                                        Text(
                                          "STOPWATCH |",
                                          style: _getTextStyle("STOPWATCH"),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: !_isCompleted
                                        ? () {
                                      setState(() {
                                        selectedOption = "POMODORO"; // Update selected option
                                        _setPomodoroTimer();
                                        _isStopwatchSelected = false; // Reset stopwatch selection
                                      });
                                    }
                                        : null,
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        // Underline for selected option
                                        if (selectedOption == "POMODORO")
                                          Container(
                                            height: 2,
                                            width: 80, // Adjust width as needed
                                            color: Colors.white,
                                          ),
                                        Text(
                                          "POMODORO",
                                          style: _getTextStyle("POMODORO"),
                                        ),
                                      ],
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
                ):Column(children: [
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
                              style: TextStyle(fontSize: 30, color: Colors.white),
                            ),
                            SizedBox(height: 5),

                            // Start button for Pomodoro
                            if (isPomodoro && !_isRunning && !_isCompleted)
                              ElevatedButton(
                                onPressed: !_isCompleted ? _startPomodoroTimer : null,
                                child: Text("START", style: TextStyle(fontSize: 10)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),

                            // Start button for User Defined Timer
                            if (!isPomodoro && !_isRunning && !_isCompleted)
                              ElevatedButton(
                                onPressed: !_isCompleted ? () => _showTimerDialog(context) : null,
                                child: Text("SET TIMER", style: TextStyle(fontSize: 10)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),

                            // Stopwatch Start Button (Step 3: Conditional rendering)
                            if (_isStopwatchSelected && !_isRunning && !_isCompleted)
                              ElevatedButton(
                                onPressed: !_isCompleted ? _startButtonTimer : null,
                                child: Text("START STOPWATCH", style: TextStyle(fontSize: 10)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),

                            // Pause button
                            if (_isRunning && !_isPaused)
                              ElevatedButton(
                                onPressed: _pauseTimer,
                                child: Text("PAUSE", style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),

                            // Resume button
                            if (_isPaused)
                              ElevatedButton(
                                onPressed: _onResumeButtonPressed,
                                child: Text('Resume', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                ),
                              ),

                            SizedBox(height: 5),

                            // Finish button
                            if (_isRunning)
                              ElevatedButton(
                                onPressed: _completeTask,
                                child: Text("FINISH", style: TextStyle(fontSize: 12)),
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
                              spacing: 8.0,
                              children: [
                                GestureDetector(
                                  onTap: !_isCompleted
                                      ? () {
                                    setState(() {
                                      selectedOption = "TIMER"; // Update selected option
                                      _showTimerDialog(context);
                                      _isStopwatchSelected = false; // Reset stopwatch selection
                                    });
                                  }
                                      : null,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      // Underline for selected option
                                      if (selectedOption == "TIMER")
                                        Container(
                                          height: 2,
                                          width: 50, // Adjust width as needed
                                          color: Colors.white,
                                        ),
                                      Text(
                                        "TIMER |",
                                        style: _getTextStyle("TIMER"),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: !_isCompleted
                                      ? () {
                                    setState(() {
                                      selectedOption = "STOPWATCH"; // Update selected option
                                      _isStopwatchSelected = true; // Step 2: Update the stopwatch selection
                                      _resetToStartScreen();
                                    });
                                  }
                                      : null,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      // Underline for selected option
                                      if (selectedOption == "STOPWATCH")
                                        Container(
                                          height: 2,
                                          width: 80, // Adjust width as needed
                                          color: Colors.white,
                                        ),
                                      Text(
                                        "STOPWATCH |",
                                        style: _getTextStyle("STOPWATCH"),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: !_isCompleted
                                      ? () {
                                    setState(() {
                                      selectedOption = "POMODORO"; // Update selected option
                                      _setPomodoroTimer();
                                      _isStopwatchSelected = false; // Reset stopwatch selection
                                    });
                                  }
                                      : null,
                                  child: Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      // Underline for selected option
                                      if (selectedOption == "POMODORO")
                                        Container(
                                          height: 2,
                                          width: 80, // Adjust width as needed
                                          color: Colors.white,
                                        ),
                                      Text(
                                        "POMODORO",
                                        style: _getTextStyle("POMODORO"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),
                  // Tasks Section
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xff003039),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(child:  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TASK FOR THIS SESSION",
                            style: TextStyle(fontSize: 14, color: Colors.white),
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
                                style: TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Text(
                            "UNCOMPLETED TASKS",
                            style: TextStyle(fontSize: 14, color: Colors.white),
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
                                    style: TextStyle(

                                        fontSize: 12,color: Colors.white),
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
                  )],),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
