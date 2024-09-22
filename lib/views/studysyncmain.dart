import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:untitled/views/GroupsPage.dart';
import 'package:untitled/views/ProfilePage.dart';
import 'package:untitled/views/StartStudyingPage.dart';
import '../models/todo_task.dart';
import '../providers/timer_provider.dart';
import '../utils/color.dart';
import '../widgets/Advertisment_Section.dart';
import '../widgets/DailyStreak_Section.dart';
import '../widgets/Header_Section.dart';
import '../widgets/TimeSpent_Section.dart';
import '../widgets/Web_Helper.dart';
import 'Friendpage.dart';
import 'TimerScreen.dart';
import 'dart:async';


class StudySyncDashboard extends StatefulWidget {
  final String userId;

  StudySyncDashboard({required this.userId});

  @override
  _StudySyncDashboardState createState() => _StudySyncDashboardState();
}

class _StudySyncDashboardState extends State<StudySyncDashboard> {
  String selectedSection = 'studysync'; // Default section
  late TimerProvider timerProvider;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    timerProvider = TimerProvider();
    timerProvider.startTimer();
    _setUserOnlineStatus(true);

    if (kIsWeb) {
      addBeforeUnloadListener(() {
        _setUserOnlineStatus(false);
      });
    }
  }

  @override
  void dispose() {
    timerProvider.stopTimer();
    _setUserOnlineStatus(false);

    if (kIsWeb) {
      removeBeforeUnloadListener();
    }

    super.dispose();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update online status when dependencies change (e.g., navigating to a new page)
    _setUserOnlineStatus(true);
  }

  Future<void> _setUserOnlineStatus(bool isOnline) async {
    await _firestore.collection('users').doc(widget.userId).update({
      'isOnline': isOnline,
    });
  }

  void onSectionChange(String section) {
    setState(() {
      selectedSection =
          section; // Change the section without stopping the timer
    });
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _setUserOnlineStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      _setUserOnlineStatus(true);
    }
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimerProvider>.value(
      value: timerProvider,
      child: Consumer<TimerProvider>(builder: (context, timerProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: AppColors.backgroundColor,
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
                            Expanded(
                              flex: 1, // Equal flex for ToDoSection
                              child: ToDoSection(),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              flex: 1, // Equal flex for StatsSection
                              child: StatsSection(
                                  sessionDurationNotifier: timerProvider
                                      .sessionDurationNotifier),
                            ),
                          ] else
                            if (selectedSection == 'friends') ...[
                              Expanded(child: FriendsPage()),
                            ] else
                              if (selectedSection == 'groups') ...[
                                Expanded(child: GroupsPage()),
                              ] else
                                if (selectedSection == 'profile') ...[
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
        );
      }),
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
    // Get the screen width to adjust the UI based on the device.
    double screenWidth = MediaQuery.of(context).size.width;

    // Adjust the font size based on the screen width (smaller for mobile).
    double fontSize = screenWidth < 600 ? 14 : 16;
    double dateFontSize = screenWidth < 600 ? 12 : 16;

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

          DateTime? effectiveDate;

          if (task?['date'] is Timestamp) {
            effectiveDate = (task['date'] as Timestamp).toDate();
          } else if (task?['date'] is String) {
            try {
              effectiveDate = DateFormat('MM-dd-yyyy').parse(task['date']);
            } catch (e) {
              print('Error parsing date string: $e');
              effectiveDate = DateTime.now(); // Set a default date or handle the error as needed
            }
          }

          return Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: screenWidth < 600 ? 6 : 8, // Adjust radius based on screen width
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize, // Adjust font size based on screen width
                      overflow: TextOverflow.ellipsis, // Ensure text stays on one line
                    ),
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
                    fontSize: dateFontSize, // Adjust date font size
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




