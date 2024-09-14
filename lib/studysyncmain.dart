import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled/GroupsPage.dart';
import 'package:untitled/ProfilePage.dart';
import 'Friendpage.dart';
import 'TimerScreen.dart';

class StudySyncDashboard extends StatefulWidget {
  final String userId;

  StudySyncDashboard({required this.userId});

  @override
  _StudySyncDashboardState createState() => _StudySyncDashboardState();
}

class _StudySyncDashboardState extends State<StudySyncDashboard> {
  String selectedSection = 'studysync'; // Default section
  Duration totalTimeSpentThisWeek = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeSpentThisWeek(); // Call function to calculate time spent
  }

  // Fetch session data and calculate total time spent this week
  Future<void> _calculateTimeSpentThisWeek() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      // Get the current date
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(
          Duration(days: now.weekday - 1)); // Start of the week (Monday)

      // Query Firestore for sessions in the current week
      QuerySnapshot sessionSnapshot = await FirebaseFirestore.instance
          .collection('sessionLogs')
          .where('userId', isEqualTo: userId)
          .where(
          'startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get();

      // Initialize total time spent to 0
      Duration totalSpent = Duration.zero;

      // Loop through the sessions and calculate time spent
      sessionSnapshot.docs.forEach((doc) {
        Map<String, dynamic> sessionData = doc.data() as Map<String, dynamic>;
        DateTime startTime = (sessionData['startTime'] as Timestamp).toDate();
        DateTime endTime = (sessionData['endTime'] as Timestamp).toDate();

        Duration sessionDuration = endTime.difference(startTime);
        totalSpent += sessionDuration;
      });

      // Update the state with the total time spent
      setState(() {
        totalTimeSpentThisWeek = totalSpent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WillPopScope(
        onWillPop: () async {
          // This ensures that pressing back always navigates to the StudySync page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudySyncDashboard(userId: widget.userId),
            ),
          );
          return false; // Prevent default back navigation
        },
        child: Scaffold(
          backgroundColor: Color(0xFFfae5d3),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  HeaderSection(onLinkPressed: (section) {
                    setState(() {
                      selectedSection = section;
                    });
                  }),
                  SizedBox(height: 20),
                  // Middle content changes based on selected section
                  Expanded(
                    child: Row(
                      children: [
                        if (selectedSection == 'studysync') ...[
                          Expanded(flex: 2, child: ToDoSection()),
                          SizedBox(width: 20),
                          Expanded(flex: 3, child: StatsSection(
                              totalTimeSpentThisWeek: totalTimeSpentThisWeek)),
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
                  // Conditional advertisement section
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

// TO-DO Section
class ToDoSection extends StatefulWidget {
  @override
  _ToDoSectionState createState() => _ToDoSectionState();
}

class _ToDoSectionState extends State<ToDoSection> {
  List<Map<String, dynamic>> todoList = [];

  @override
  void initState() {
    super.initState();
    _fetchTodoItems();
  }

  void _fetchTodoItems() async {
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
          todoList = tasks.map((task) {
            return {
              'title': task['title'],
              'date': DateTime.parse(task['date']),
            };
          }).toList();
        });
      }
    } else {
      print('No user is logged in.');
    }
  }

  void _showAddItemDialog() {
    TextEditingController taskController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add To-Do Item"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: taskController,
                    decoration: InputDecoration(hintText: "Task Name"),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && pickedDate != selectedDate) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today),
                        SizedBox(width: 10),
                        Text(DateFormat('EEE, d MMM').format(selectedDate)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("Add"),
                  onPressed: () {
                    _addTodoItem(taskController.text, selectedDate);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addTodoItem(String title, DateTime date) async {
    if (title.isNotEmpty) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String userId = currentUser?.uid ?? '';

      if (userId.isNotEmpty) {
        setState(() {
          todoList.add({'title': title, 'date': date});
        });

        await FirebaseFirestore.instance
            .collection('todoTasks')
            .doc(userId)
            .set({
          'Todotasks': FieldValue.arrayUnion([{
            'title': title,
            'date': date.toIso8601String()
          }])
        }, SetOptions(merge: true));
      } else {
        print('No user is logged in.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  title: todoList[index]['title'],
                  initialDate: todoList[index]['date'],
                );
              },
            ),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: _showAddItemDialog,
            child: Row(
              children: [
                Icon(Icons.add_circle, color: Colors.white),
                SizedBox(width: 20),
                Text(
                  'Add Item',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ToDoItem extends StatelessWidget {
  final String title;
  final DateTime initialDate;

  const ToDoItem({required this.title, required this.initialDate});

  void _updateDate(BuildContext context, DateTime newDate) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      // Update the date in Firestore
      await FirebaseFirestore.instance.collection('todoTasks').doc(userId).update({
        'Todotasks': FieldValue.arrayUnion([
          {
            'title': title,
            'date': newDate.toIso8601String()
          }
        ]),
      });

      // Optionally remove the old date
      await FirebaseFirestore.instance.collection('todoTasks').doc(userId).update({
        'Todotasks': FieldValue.arrayRemove([
          {
            'title': title,
            'date': initialDate.toIso8601String()
          }
        ]),
      });
    } else {
      print('No user is logged in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
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
                      taskTitle: title,
                      taskDate: initialDate,
                    ),
                  ),
                );
              },
              child: Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null && pickedDate != initialDate) {
                _updateDate(context, pickedDate);
                // You may need to refresh the list or update the state accordingly
              }
            },
            child: Text(
              DateFormat('EEE, d MMM').format(initialDate),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class StatsSection extends StatelessWidget {
  final Duration totalTimeSpentThisWeek;

  StatsSection({required this.totalTimeSpentThisWeek}); // Make sure this is passed

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DailyStreakSection(),
        SizedBox(height: 30),
        TimeSpentSection(totalTimeSpentThisWeek: totalTimeSpentThisWeek), // Pass actual value here
        SizedBox(height: 20),
        StartStudyingButton(), // Add the button here
      ],
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

          // Check if the difference is at least 24 hours
          if (difference.inHours >= 24) {
            int newStreakNumber = (userData['streakNumber'] ?? 0) + 1;

            // Update Firestore
            await FirebaseFirestore.instance.collection('users').doc(userId).update({
              'streakNumber': newStreakNumber,
              'lastStreakUpdate': Timestamp.fromDate(currentTime),
            });

            setState(() {
              streakNumber = newStreakNumber;
            });
          } else {
            // No streak update if within 24 hours
            setState(() {
              streakNumber = userData['streakNumber'] ?? 0;
            });
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

class TimeSpentSection extends StatelessWidget {
  final Duration totalTimeSpentThisWeek;

  TimeSpentSection({required this.totalTimeSpentThisWeek});

  @override
  Widget build(BuildContext context) {
    String formattedTimeSpent = _formatDuration(totalTimeSpentThisWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time spent this week: $formattedTimeSpent',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          '* Statistics on time spent in the app',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // Helper function to format Duration into hours and minutes
  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
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
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) =>
          //   ),
          // );
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


