import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:untitled/views/GroupsPage.dart';
import 'package:untitled/views/ProfilePage.dart';
import 'package:untitled/views/StartStudyingPage.dart';
import '../providers/timer_provider.dart';
import 'Friendpage.dart';
import 'TimerScreen.dart';
import 'dart:async';
import 'package:untitled/models/todo_task_model.dart'; // Import your model


class StudySyncDashboard extends StatefulWidget {
  final String userId;

  StudySyncDashboard({required this.userId});

  @override
  _StudySyncDashboardState createState() => _StudySyncDashboardState();
}

class _StudySyncDashboardState extends State<StudySyncDashboard> {
  String selectedSection = 'studysync'; // Default section
  late TimerProvider timerProvider;

  @override
  void initState() {
    super.initState();
    timerProvider = TimerProvider(); // Initialize TimerProvider
    timerProvider.startTimer(); // Start the timer when the widget is initialized
  }

  @override
  void dispose() {
    timerProvider.stopTimer(); // Stop the timer when the widget is disposed
    super.dispose();
  }

  void onSectionChange(String section) {
    setState(() {
      selectedSection = section; // Change the section without stopping the timer
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimerProvider>.value(
      value: timerProvider,
      child: Consumer<TimerProvider>(
        builder: (context, timerProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: WillPopScope(
              onWillPop: () async {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudySyncDashboard(userId: widget.userId),
                  ),
                );
                return false;
              },
              child: Scaffold(
                backgroundColor: Color(0xFFfae5d3),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeaderSection(onLinkPressed: onSectionChange),
                        SizedBox(height: 20),
                        Expanded(
                          child: Row(
                            children: [
                              if (selectedSection == 'studysync') ...[
                                Expanded(flex: 2, child: ToDoSection()),
                                SizedBox(width: 20),
                                Expanded(
                                  flex: 3,
                                  child: StatsSection(sessionDurationNotifier: timerProvider.sessionDurationNotifier),
                                ),
                              ] else if (selectedSection == 'friends') ...[
                                Expanded(child: FriendsPage()),
                              ] else if (selectedSection == 'groups') ...[
                                Expanded(child: GroupsPage()),
                              ] else if (selectedSection == 'profile') ...[
                                Expanded(child: ProfilePage()),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        if (selectedSection == 'studysync') ...[
                          AdvertisementSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Header Section
class HeaderSection extends StatelessWidget {
  final Function(String) onLinkPressed;

  const HeaderSection({required this.onLinkPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            onLinkPressed('studysync'); // Show StudySync context
          },
          child: Text(
            'STUDYSYNC',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        Spacer(),
        HeaderLink(text: 'Friends', onLinkPressed: onLinkPressed),
        SizedBox(width: 60),
        HeaderLink(text: 'Groups', onLinkPressed: onLinkPressed),
        SizedBox(width: 60),
        HeaderLink(text: 'Profile', onLinkPressed: onLinkPressed),
        SizedBox(width: 20),
      ],
    );
  }
}

class HeaderLink extends StatelessWidget {
  final String text;
  final Function(String) onLinkPressed;

  const HeaderLink({required this.text, required this.onLinkPressed});

  @override
  Widget build(BuildContext context) {
    // Fetch screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Determine font size and padding dynamically based on screen width
    double fontSize = screenWidth * 0.045; // Adjusts font size relative to screen
    double horizontalPadding = screenWidth * 0.02; // Adjust padding

    return GestureDetector(
      onTap: () {
        onLinkPressed(text.toLowerCase()); // Pass which link was clicked
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize.clamp(14, 22), // Min 14, Max 22 font size
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class ToDoSection extends StatefulWidget {
  @override
  _ToDoSectionState createState() => _ToDoSectionState();
}

class _ToDoSectionState extends State<ToDoSection> {
  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isEmpty) {
      return Center(child: Text('No user logged in.'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('todoTasks')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xff003039),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'No tasks added.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        List<dynamic> tasks = snapshot.data!.get('Todotasks') ?? [];
        List<TodoTask> todoList = tasks.map((task) {
          return TodoTask.fromMap(task);
        }).toList()
          ..sort((a, b) {
            int priorityComparison = b.priority.compareTo(a.priority); // Descending order
            if (priorityComparison != 0) return priorityComparison;
            if (a.date == null || b.date == null) return 0;
            return a.date!.compareTo(b.date!); // Ascending order
          });

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xff003039),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TO-DO',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: todoList.length,
                  itemBuilder: (context, index) {
                    return ToDoItem(
                      title: todoList[index].title,
                      initialDate: todoList[index].date,
                      priority: todoList[index].priority,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ToDoItem extends StatefulWidget {
  final String title;
  final DateTime? initialDate;
  final int priority;

  const ToDoItem({
    required this.title,
    this.initialDate,
    required this.priority,
  });

  @override
  _ToDoItemState createState() => _ToDoItemState();
}

class _ToDoItemState extends State<ToDoItem> {
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate; // Initialize with the date from Firestore
  }

  Stream<DocumentSnapshot> _getTaskStream() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('todoTasks')
          .doc(userId)
          .snapshots();
    } else {
      return Stream.empty();
    }
  }

  void _updateDate(DateTime newDate) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      try {
        DocumentReference docRef = FirebaseFirestore.instance.collection('todoTasks').doc(userId);
        DocumentSnapshot userTaskSnapshot = await docRef.get();

        if (userTaskSnapshot.exists && userTaskSnapshot.data() != null) {
          List<dynamic> tasks = userTaskSnapshot.get('Todotasks');

          var updatedTasks = tasks.map((task) {
            if (task['title'] == widget.title) {
              // Update the task with the new date
              return {
                'title': task['title'],
                'date': newDate,
                'priority': task['priority']
              };
            }
            return task;
          }).toList();

          // Update Firestore with the new task list
          await docRef.update({
            'Todotasks': updatedTasks,
          });

          setState(() {
            _selectedDate = newDate;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task date updated!')),
          );
        }
      } catch (e) {
        print('Error updating task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task.')),
        );
      }
    } else {
      print('No user is logged in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2101);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _getTaskStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return SizedBox.shrink(); // Handle no data scenario if necessary
          }

          List<dynamic> tasks = snapshot.data!.get('Todotasks') ?? [];
          var task = tasks.firstWhere(
                (task) => task['title'] == widget.title,
            orElse: () => null,
          );

          DateTime? effectiveDate = task?['date']?.toDate();

          return Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red,
                radius: 8,
              ),
              SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TimerScreen(
                          taskTitle: widget.title,
                          taskDate: effectiveDate ?? DateTime.now(),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    widget.title,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: effectiveDate ?? DateTime.now(),
                    firstDate: firstDate,
                    lastDate: lastDate,
                  );
                  if (pickedDate != null && pickedDate != _selectedDate) {
                    _updateDate(pickedDate);
                  }
                },
                child: effectiveDate != null
                    ? Text(
                  DateFormat('EEE, d MMM').format(effectiveDate),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                )
                    : SizedBox.shrink(), // Hide if no date is set
              ),

            ],
          );
        },
      ),
    );
  }
}

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

class StatsSection extends StatelessWidget {
  final ValueNotifier<Duration> sessionDurationNotifier;

  StatsSection({required this.sessionDurationNotifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DailyStreakSection(),
        SizedBox(height: 30),
        ValueListenableBuilder<Duration>(
          valueListenable: sessionDurationNotifier,
          builder: (context, duration, child) {
            return TimeSpentSection(totalTimeSpentThisWeek: duration);
          },
        ),
        SizedBox(height: 20),
        StartStudyingButton(),
      ],
    );
  }
}

class TimeSpentSection extends StatelessWidget {
  final Duration totalTimeSpentThisWeek;

  TimeSpentSection({required this.totalTimeSpentThisWeek});

  @override
  Widget build(BuildContext context) {
    String formattedTimeSpent = _formatDuration(totalTimeSpentThisWeek);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 4,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Spent This Week:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            formattedTimeSpent,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return '$hours hours, $minutes minutes, $seconds seconds';
  }
}

class StatBox extends StatelessWidget {
  final String label;
  final String value;

  const StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

class StartStudyingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff003039),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarToDoPage()
            ),
          );
        },
        child: Text(
          'START STUDYING',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class AdvertisementSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.grey[300],
      child: Center(
        child: Text(
          'Advertisement',
          style: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }
}


