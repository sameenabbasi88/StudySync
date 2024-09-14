import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
                        Expanded(flex: 3, child: StatsSection()),
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

                // Conditional "Start Studying" button and advertisement
                if (selectedSection == 'studysync') ...[
                  StartStudyingButton(),
                  SizedBox(height: 10),
                  AdvertisementSection(),
                ],
              ],
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

  // Function to fetch items from the database
  void _fetchTodoItems() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      // Fetch the user's todo items from the database
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
      // Handle case where user is not logged in
      print('No user is logged in.');
    }
  }

  // Function to show the add item dialog
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

  // Function to add item to the list and store it in the database
  void _addTodoItem(String title, DateTime date) async {
    if (title.isNotEmpty) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String userId = currentUser?.uid ?? '';

      if (userId.isNotEmpty) {
        setState(() {
          todoList.add({'title': title, 'date': date});
        });

        // Use set with merge: true to avoid the not-found error if the document doesn't exist
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red,
              radius: 8,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            Text(
              DateFormat('EEE, d MMM').format(initialDate),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Other sections remain unchanged (StatsSection, StartStudyingButton, AdvertisementSection)
class StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DailyStreakSection(),
        SizedBox(height: 30),
        TimeSpentSection(),
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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time spent this week: XXh XXmin',
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
          // Handle "Start Studying" button press
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


