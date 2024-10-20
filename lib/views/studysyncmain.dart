import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/views/GroupsPage.dart';
import 'package:untitled/views/ProfilePage.dart';
import 'package:untitled/views/StartStudyingPage.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _restoreSelectedSection();
    timerProvider = TimerProvider();
    timerProvider.initialize(); // Call the initialize method to set up the timer
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
    _setUserOnlineStatus(true);
  }

  Future<void> _setUserOnlineStatus(bool isOnline) async {
    if (!mounted) return; // Check if the widget is still mounted
    await _firestore.collection('users').doc(widget.userId).update({
      'isOnline': isOnline,
    });
  }

  Future<void> _checkAuthState() async {
    if (!mounted) return; // Check if the widget is still mounted
    User? user = _auth.currentUser;
    if (user == null) {
      // Handle unauthenticated state, like redirecting to a login page
      Navigator.pushReplacementNamed(context, '/login');
    }
  }


  void onSectionChange(String section) async {
    setState(() {
      selectedSection = section;
    });
    await _saveSelectedSection(section);
  }

  Future<void> _saveSelectedSection(String section) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedSection', section);
  }

  Future<void> _restoreSelectedSection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedSection = prefs.getString('selectedSection');
    if (savedSection != null) {
      setState(() {
        selectedSection = savedSection;
      });
    }
  }


  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return; // Check if the widget is still mounted
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
  DateTime? selectedDate;

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
      builder: (context, todoSnapshot) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('completedTasks')
              .doc(userId)
              .snapshots(),
          builder: (context, completedSnapshot) {
            if (todoSnapshot.connectionState == ConnectionState.waiting ||
                completedSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // Check if either of the snapshots have data
            bool hasTodoTasks = todoSnapshot.hasData &&
                todoSnapshot.data!.exists &&
                todoSnapshot.data!.get('Todotasks') != null &&
                todoSnapshot.data!.get('Todotasks').isNotEmpty;

            bool hasCompletedTasks = completedSnapshot.hasData &&
                completedSnapshot.data!.exists &&
                completedSnapshot.data!.get('completedTasks') != null &&
                completedSnapshot.data!.get('completedTasks').isNotEmpty;

            // Fetching TO-DO Tasks
            List<dynamic> tasks = hasTodoTasks ? todoSnapshot.data!.get('Todotasks') : [];
            List<TodoTask> todoList = tasks.map((task) {
              return TodoTask.fromMap(task);
            }).toList()
              ..sort((a, b) {
                int priorityComparison = b.priority.compareTo(a.priority);
                if (priorityComparison != 0) return priorityComparison;
                if (a.date == null || b.date == null) return 0;
                return a.date!.compareTo(b.date!);
              });

            // Fetching Completed Tasks
            List<dynamic> completedTasks = hasCompletedTasks ? completedSnapshot.data!.get('completedTasks') : [];
            List<TodoTask> completedTaskList = completedTasks.map((task) {
              return TodoTask.fromMap(task);
            }).toList()
              ..sort((a, b) {
                int priorityComparison = b.priority.compareTo(a.priority);
                if (priorityComparison != 0) return priorityComparison;
                if (a.date == null || b.date == null) return 0;
                return a.date!.compareTo(b.date!);
              });

            return Container(
              constraints: BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xff003039),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display TO-DO tasks
                      Text(
                        'TO-DO',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      todoList.isEmpty
                          ? Text(
                        'No tasks added.',
                        style: TextStyle(color: Colors.white),
                      )
                          : Container(
                        height: 100,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: todoList.length,
                          itemBuilder: (context, index) {
                            return ToDoItem(
                              title: todoList[index].title,
                              taskId: todoList[index].taskId,
                              initialDate: todoList[index].date,
                              priority: todoList[index].priority,
                              groupName: todoList[index].groupName,
                              completionDate: todoList[index].completionDate,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      // Display Completed tasks
                      Text(
                        'Completed Tasks',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      completedTaskList.isEmpty
                          ? Text(
                        'No completed tasks.',
                        style: TextStyle(color: Colors.white),
                      )
                          : Container(
                        height: 100,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemCount: completedTaskList.length,
                          itemBuilder: (context, index) {
                            return ToDoItem(
                              title: completedTaskList[index].title,
                              taskId: completedTaskList[index].taskId,
                              initialDate: completedTaskList[index].completionDate,
                              priority: completedTaskList[index].priority,
                              groupName: completedTaskList[index].groupName,
                              completionDate: completedTaskList[index].completionDate,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      // Add Task Button (always displayed)
                      TextButton(
                        onPressed: () {
                          // Open a dialog to add a new task
                          showDialog(
                            context: context,
                            builder: (context) {
                              TextEditingController taskTitleController = TextEditingController();
                              DateTime? selectedDate;

                              return AlertDialog(
                                title: Text('Add Task'),
                                content: StatefulBuilder(
                                  builder: (BuildContext context, StateSetter setState) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: taskTitleController,
                                          decoration: InputDecoration(labelText: 'Task Title'),
                                        ),
                                        SizedBox(height: 16),
                                        GestureDetector(
                                          onTap: () async {
                                            DateTime? pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: selectedDate ?? DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2101),
                                            );

                                            if (pickedDate != null) {
                                              setState(() {
                                                selectedDate = pickedDate;
                                              });
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: selectedDate != null
                                                  ? 'Selected Date: ${selectedDate!.toLocal()}'.split(' ')[0]
                                                  : 'Select Date',
                                              border: OutlineInputBorder(),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                selectedDate != null
                                                    ? '${selectedDate!.toLocal()}'.split(' ')[0]
                                                    : 'No date selected',
                                                style: TextStyle(
                                                  color: selectedDate != null ? Colors.black : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      String taskTitle = taskTitleController.text;
                                      if (taskTitle.isNotEmpty && selectedDate != null) {
                                        Map<String, dynamic> newTask = {
                                          'title': taskTitle,
                                          'date': Timestamp.fromDate(selectedDate!),
                                          'priority': 1,
                                        };

                                        FirebaseFirestore.instance
                                            .collection('todoTasks')
                                            .doc(userId)
                                            .set({
                                          'Todotasks': FieldValue.arrayUnion([newTask])
                                        }, SetOptions(merge: true))
                                            .then((_) {
                                          Navigator.of(context).pop();
                                        }).catchError((error) {
                                          print("Failed to add task: $error");
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Please enter a task title and select a date.')),
                                        );
                                      }
                                    },
                                    child: Text('Add Task'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Add Item',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}




// TodoTask model update to include groupName
class TodoTask {
  final String title;
  final DateTime? date;
  final int priority;
  final String taskId;
  final DateTime? completionDate;
  final String? groupName; // Add groupName field

  TodoTask({
    required this.title,
    required this.taskId,
    this.completionDate,
    this.date,
    required this.priority,
    this.groupName, // Initialize groupName
  });

  factory TodoTask.fromMap(Map<String, dynamic> map) {
    return TodoTask(
      title: map['title'] , // Default to 'Untitled Task' if null
      taskId: map['taskId'] ?? 'unknown-task-id', // Default to 'unknown-task-id' if taskId is null
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : (map['date'] != null ? DateTime.tryParse(map['date']) : null), // Handle null or invalid date
      priority: map['priority'] ?? 0,
      completionDate: (map['completionDate'] as Timestamp?)?.toDate(),// Default to 0 if priority is null
      groupName: map['groupName'],// Default to 'Unknown Group' if null
    );
  }


}

class ToDoItem extends StatefulWidget {
  final String title;
  final DateTime? initialDate;
  final int priority;
  final String? groupName;
  final DateTime? completionDate; // Include completionDate here
  final String taskId;

  const ToDoItem({
    required this.title,
    this.initialDate,
    required this.priority,
    required this.completionDate, // Add completionDate to constructor parameters
    this.groupName,
    required this.taskId,
  });

  @override
  _ToDoItemState createState() => _ToDoItemState();
}

class _ToDoItemState extends State<ToDoItem> {
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
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
              return {
                'title': task['title'],
                'date': newDate,
                'priority': task['priority'],
                'completionDate': task['completionDate'], // Keep existing completionDate
              };
            }
            return task;
          }).toList();

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
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth < 600 ? 14 : 16;
    double dateFontSize = screenWidth < 600 ? 12 : 16;

    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2101);

    String displayText = widget.groupName != null && widget.groupName!.isNotEmpty
        ? '${widget.groupName}: ${widget.title}'
        : widget.title;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _getTaskStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return SizedBox.shrink();
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
              effectiveDate = DateTime.now();
            }
          }

          return Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: screenWidth < 600 ? 6 : 8,
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
                          taskId: widget.taskId,
                          taskDate: effectiveDate ?? DateTime.now(),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      overflow: TextOverflow.ellipsis,
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
                    fontSize: dateFontSize,
                    decoration: TextDecoration.underline,
                  ),
                )
                    : SizedBox.shrink(),
              ),
              SizedBox(width: 10),
              // Display the completion date if it exists
              if (widget.completionDate != null)
                Text(
                  DateFormat('EEE, d MMM').format(widget.completionDate!),
                  style: TextStyle(
                    color: Colors.white, // You can customize the color
                    fontSize: dateFontSize,
                    fontStyle: FontStyle.italic,
                  ),
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

class StartStudyingButton extends StatefulWidget {
  @override
  _StartStudyingButtonState createState() => _StartStudyingButtonState();
}

class _StartStudyingButtonState extends State<StartStudyingButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
        },
        child: GestureDetector(
          onTapDown: (_) {
            setState(() {
              _isPressed = true;
            });
          },
          onTapUp: (_) {
            setState(() {
              _isPressed = false;
            });
          },
          onTapCancel: () {
            setState(() {
              _isPressed = false;
            });
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalendarToDoPage()),
            );
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: _isPressed
                  ? Colors.teal[800] // Darker color when pressed
                  : _isHovered
                  ? Colors.teal // Lighter color when hovered
                  : Color(0xff003039), // Default color
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'START STUDYING',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}





