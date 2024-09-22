import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class TaskManagerApp extends StatelessWidget {
  final String groupId;

  TaskManagerApp({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TaskManagerScreen(groupId: groupId),
    );
  }
}

class TaskManagerScreen extends StatefulWidget {
  final String groupId;

  TaskManagerScreen({required this.groupId});

  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  List<Task> tasks = [];
  String groupName = '';
  String creatorUsername = '';
  String creatorId = ''; // Add this to store the creator's user ID
  bool isFollowing = false; // Track follow status
  List<String> members = [];

  @override
  void initState() {
    super.initState();
    _startListeningToTasks();
    if (widget.groupId.isNotEmpty) {
      _fetchGroupDetails(); // Fetch group details when the screen is initialized
      _fetchTasks(); // Fetch tasks
    } else {
      print('Group ID is empty');
    }
  }

  void _showTaskPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: TaskManager(
            tasks: tasks,
            onTaskAdded: (newTask) {
              setState(() {
                tasks.add(newTask); // Update the local task list
                _updateTodoTasks(
                    [newTask]); // Ensure new tasks are pushed to followers
              });
            },
            groupId: widget.groupId, // Pass the group ID
          ),
        );
      },
    );
  }

  Future<void> _fetchGroupDetails() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        setState(() {
          groupName = groupSnapshot['groupname'] ??
              'Unknown Group'; // Fetch the group name
          creatorId =
              groupSnapshot['owner'] ?? ''; // Fetch the creator's user ID
          _fetchCreatorUsername(creatorId); // Fetch the creator's username
          _checkIfFollowing(); // Check if the user is following the group
          _checkIfCreator(); // Check if the current user is the creator
        });
      } else {
        print('Group document does not exist');
      }
    } catch (e) {
      print('Error fetching group details: $e');
    }
  }

  Future<void> _fetchCreatorUsername(String creatorId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .get();

      if (userSnapshot.exists) {
        setState(() {
          creatorUsername = userSnapshot['username'] ??
              'Unknown Creator'; // Fetch the username
        });
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching creator username: $e');
    }
  }

  Future<void> _fetchMembers() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        List<dynamic> followers = groupSnapshot['followers'] ?? [];
        List<String> memberList = [];

        for (var follower in followers) {
          String followerId = follower['userId'];
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(followerId)
              .get();

          if (userSnapshot.exists) {
            String username = userSnapshot['username'] ?? 'Unknown';
            memberList.add(username);
          }
        }

        setState(() {
          members = memberList;
        });

        _showMembersDialog();
      }
    } catch (e) {
      print('Error fetching members: $e');
    }
  }

  void _showMembersDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Group Members'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Admin: $creatorUsername',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              ...members.map((member) => Text(member)).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchTasks() async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        List<dynamic> tasksFromFirestore = groupSnapshot['tasks'] ?? [];
        setState(() {
          tasks = tasksFromFirestore.map((taskData) {
            return Task(
              taskName: taskData['task'],
              progress: taskData['progress'],
            );
          }).toList();
        });
      } else {
        print('Group document does not exist');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  Future<void> _checkIfCreator() async {
    try {
      User? currentUser = FirebaseAuth
          .instance.currentUser; // Get current user from Firebase Auth

      if (currentUser != null) {
        String userId = currentUser.uid; // Retrieve the current user's ID

        setState(() {
          // Check if the current user is the creator
          bool isCreator = userId == creatorId;
          _showManageTasksButton(isCreator);
        });
      }
    } catch (e) {
      print('Error checking creator status: $e');
    }
  }

  void _showManageTasksButton(bool isCreator) {
    // Logic to show or hide the "Manage Tasks" button
    setState(() {
      // Add logic here if needed
    });
  }

  Future<void> _checkIfFollowing() async {
    try {
      User? currentUser = FirebaseAuth
          .instance.currentUser; // Get current user from Firebase Auth

      if (currentUser != null) {
        String userId = currentUser
            .uid; // Retrieve the current user's ID from Firebase Authentication

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          List<dynamic> followingGroups = userSnapshot['joinedgroup'] ?? [];
          setState(() {
            // Ensure groupId is compared as a string
            isFollowing = followingGroups.any((group) =>
                group['groupId'].toString() == widget.groupId.toString());
          });
        }
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  int _calculateTaskPriority(DateTime taskDueDate) {
    DateTime today = DateTime.now();
    Duration difference = taskDueDate.difference(today);

    // Priority logic: closer the task due date, higher the priority
    if (difference.inDays <= 1) {
      return 1; // High priority
    } else if (difference.inDays <= 3) {
      return 2; // Medium priority
    } else {
      return 3; // Low priority
    }
  }

  void _startListeningToTasks() {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .snapshots()
        .listen((groupSnapshot) {
      if (groupSnapshot.exists) {
        List<dynamic> tasksFromFirestore = groupSnapshot['tasks'] ?? [];
        setState(() {
          tasks = tasksFromFirestore.map((taskData) {
            return Task(
              taskName: taskData['task'],
              progress: taskData['progress'],
            );
          }).toList();
        });

        // Update the todoTasks collection when tasks change
        _updateTodoTasks(tasksFromFirestore);
      }
    });
  }

  Future<void> _updateTodoTasks(List<dynamic> newTasks) async {
    try {
      // Fetch the group document to get the list of followers
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        List<dynamic> followers = groupSnapshot['followers'] ?? [];

        for (var follower in followers) {
          String followerId =
              follower['userId'].toString(); // Ensure userId is String

          // Update todoTasks for each follower
          await FirebaseFirestore.instance
              .collection('todoTasks')
              .doc(followerId)
              .set({
            'Todotasks': FieldValue.arrayUnion(newTasks.map((taskData) {
              DateTime date =
                  DateTime.now().add(Duration(days: 7)); // Example date
              int taskPriority =
                  _calculateTaskPriority(date); // Calculate the priority
              String formattedDate = DateFormat('MM-dd-yyyy').format(date);

              return {
                'title': taskData['task'],
                'userId': followerId, // Ensure userId is String
                'date': formattedDate,
                'priority': taskPriority,
              };
            }).toList()),
          }, SetOptions(merge: true)); // Merge with existing tasks
        }
      }
    } catch (e) {
      print('Error updating todoTasks for followers: $e');
    }
  }

  Future<void> _toggleFollow() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String userId = currentUser.uid;

        DocumentReference userDoc =
            FirebaseFirestore.instance.collection('users').doc(userId);
        DocumentReference groupDoc =
            FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

        if (isFollowing) {
          // Unfollow logic
          await userDoc.update({
            'joinedgroup': FieldValue.arrayRemove([
              {
                'groupId': widget.groupId,
                'groupName': groupName,
              }
            ]),
          });
          await groupDoc.update({
            'followers': FieldValue.arrayRemove([
              {'userId': userId}
            ]),
          });
        } else {
          // Follow logic
          await userDoc.update({
            'joinedgroup': FieldValue.arrayUnion([
              {
                'groupId': widget.groupId,
                'groupName': groupName,
              }
            ]),
          });
          await groupDoc.update({
            'followers': FieldValue.arrayUnion([
              {'userId': userId}
            ]),
          });
        }

        setState(() {
          isFollowing = !isFollowing; // Toggle follow status
        });
      }
    } catch (e) {
      print('Error toggling follow status: $e');
    }
  }

  void _copyGroupLink() {
    final String groupLink =
        "https://yourapp.com/group/${widget.groupId}"; // Example group link
    Clipboard.setData(ClipboardData(text: groupLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Group link copied to clipboard!')),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        // Get screen width to determine font size, icon size, and padding
        double screenWidth = MediaQuery.of(context).size.width;
        double fontSize = screenWidth < 600 ? 12.0 : 18.0;  // Smaller font for mobile
        double iconSize = screenWidth < 600 ? 18.0 : 30.0;  // Smaller icons for mobile
        EdgeInsets containerPadding = screenWidth < 600 ? EdgeInsets.zero : EdgeInsets.all(16.0);  // Remove padding on mobile

        return Container(
          padding: containerPadding,
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.share, size: iconSize), // Adjust icon size
                title: Text('WhatsApp', style: TextStyle(fontSize: fontSize)),
                onTap: () {
                  _shareLink('WhatsApp');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, size: iconSize), // Adjust icon size
                title: Text('Instagram', style: TextStyle(fontSize: fontSize)),
                onTap: () {
                  _shareLink('Instagram');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share, size: iconSize), // Adjust icon size
                title: Text('Facebook', style: TextStyle(fontSize: fontSize)),
                onTap: () {
                  _shareLink('Facebook');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }



  void _shareLink(String platform) {
    final String groupLink =
        "https://yourapp.com/group/${widget.groupId}"; // Example group link
    String message = "Check out this group: $groupLink";

    Share.share(message, subject: 'Share this group link');
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width
    double screenWidth = MediaQuery.of(context).size.width;

    // Define font sizes based on screen width
    double groupNameFontSize = screenWidth < 600 ? 14 : 24;
    double creatorUsernameFontSize = screenWidth < 600 ? 12 : 18;
    double manageTasksButtonFontSize = screenWidth < 600 ? 12 : 20;
    double taskNameFontSize = screenWidth < 600 ? 14 : 18;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Color(0xFFc1121f),
              ),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xff003039), width: 2),
                  ),
                  padding: EdgeInsets.all(8.0), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(4.0), // Reduced padding
                          decoration: BoxDecoration(
                            color: Color(0xFFc1121f),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          width: double.infinity,
                          child: Wrap(
                            spacing: 10,
                            children: [
                              Text(
                                groupName,
                                style: TextStyle(
                                  fontSize: groupNameFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Created by: $creatorUsername',
                                style: TextStyle(
                                  fontSize: creatorUsernameFontSize,
                                  color: Colors.white,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: _toggleFollow,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFollowing ? Colors.grey : Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: TextStyle(color: Colors.white, fontSize: creatorUsernameFontSize),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_horiz, color: Colors.white),
                                onSelected: (value) {
                                  if (value == 'Share') {
                                    _showShareOptions();
                                  } else if (value == 'Copy Link') {
                                    _copyGroupLink();
                                  } else if (value == 'Members') {
                                    _fetchMembers();
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return {'Share', 'Copy Link', 'Members'}
                                      .map((String choice) {
                                    return PopupMenuItem<String>(
                                      value: choice,
                                      child: Text(choice),
                                    );
                                  }).toList();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8), // Reduced height
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double screenWidth = constraints.maxWidth;
                            return ListView.builder(
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0), // Reduced padding
                                  width: screenWidth < 600 ? screenWidth * 0.9 : screenWidth * 0.8,
                                  child: TaskItem(
                                    taskNumber: (index + 1).toString(),
                                    taskName: tasks[index].taskName,
                                    progress: tasks[index].progress,
                                    fontSize: taskNameFontSize, // Dynamic font size
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8), // Reduced height
                      if (FirebaseAuth.instance.currentUser?.uid == creatorId)
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
                            ),
                            onPressed: _showTaskPopup,
                            child: Text(
                              'Manage Tasks',
                              style: TextStyle(fontSize: manageTasksButtonFontSize, color: Colors.white),
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
      ),
    );
  }


}

class TaskManager extends StatefulWidget {
  final List<Task> tasks;
  final ValueChanged<Task> onTaskAdded;
  final String groupId;

  TaskManager(
      {required this.tasks, required this.onTaskAdded, required this.groupId});

  @override
  _TaskManagerState createState() => _TaskManagerState();
}

class _TaskManagerState extends State<TaskManager> {
  List<String> taskNames = [];
  String? newTaskName;

  @override
  void initState() {
    super.initState();
    taskNames = widget.tasks.map((task) => task.taskName).toList();
  }

  void _handleTaskDeletion(String task) {
    setState(() {
      taskNames.remove(task);
    });
  }

  Future<void> _addTaskToFirestore(String taskName) async {
    try {
      if (widget.groupId.isEmpty) {
        throw Exception('Group ID is empty');
      }

      // Set the due date to 7 days from today
      DateTime dueDate = DateTime.now().add(Duration(days: 7));
      String formattedDate = DateFormat('yyyy-MM-dd').format(dueDate);

      // Assign priority based on date or any other logic you want
      int taskPriority = _calculateTaskPriority(dueDate);

      // Add the new task to Firestore
      DocumentReference groupDoc =
      FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
      await groupDoc.update({
        'tasks': FieldValue.arrayUnion([
          {
            'task': taskName,
            'progress': 0.0, // Set initial progress
            'date': formattedDate,
            'priority': taskPriority,
          }
        ]),
      });
    } catch (e) {
      print('Error adding task to Firestore: $e');
    }
  }

// Function to calculate task priority based on the due date
  int _calculateTaskPriority(DateTime dueDate) {
    DateTime today = DateTime.now();
    // Example logic: Priority decreases as the task date is further in the future
    int daysUntilDue = dueDate
        .difference(today)
        .inDays;
    return daysUntilDue <= 7 ? 1 : 2; // High priority if within 7 days
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Task'),
          content: TextField(
            decoration: InputDecoration(hintText: 'Enter task name'),
            onChanged: (value) {
              newTaskName = value;
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (newTaskName != null && newTaskName!.isNotEmpty) {
                  Task newTask = Task(taskName: newTaskName!, progress: 0.0);
                  setState(() {
                    taskNames.add(newTask.taskName); // Add to local task list
                  });
                  widget.onTaskAdded(newTask); // Add to global task list
                  _addTaskToFirestore(newTask.taskName); // Save to Firestore
                  Navigator.of(context).pop(); // Close dialog
                }
              },
              child: Text('Add'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without adding
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    // Determine font size based on screen width
    double fontSize = screenWidth < 600
        ? 16
        : 20; // Smaller font for mobile view

    return Container(
      width: 350,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF003540),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Tasks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ...taskNames
              .map((task) =>
              TaskPopupItem(
                task: task,
                groupId: widget.groupId,
                onTaskDeleted: _handleTaskDeletion,
              ))
              .toList(),
          SizedBox(height: 20),
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              onPressed: _showAddTaskDialog,
              child: Icon(Icons.add),
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskPopupItem extends StatelessWidget {
  final String task;
  final String groupId;
  final ValueChanged<String> onTaskDeleted;

  TaskPopupItem({
    required this.task,
    required this.groupId,
    required this.onTaskDeleted,
  });

  void _deleteTask(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Task'),
          content: Text('Do you really want to delete this task?'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        DocumentReference groupDoc =
            FirebaseFirestore.instance.collection('groups').doc(groupId);
        await groupDoc.update({
          'tasks': FieldValue.arrayRemove([
            {
              'task': task,
              'progress': 0.0, // Ensure this matches the initial progress value
            }
          ]),
        });

        // Notify the parent to update the UI
        onTaskDeleted(task);
      } catch (e) {
        print('Error deleting task: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          title: Text(
            task,
            style: TextStyle(fontSize: 16),
          ),
          trailing: GestureDetector(
            onTap: () => _deleteTask(context),
            child: CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Task {
  final String taskName;
  final double progress;

  Task({
    required this.taskName,
    required this.progress,
  });
}

class TaskItem extends StatelessWidget {
  final String taskNumber;
  final String taskName;
  final double progress;

  TaskItem({
    required this.taskNumber,
    required this.taskName,
    required this.progress, required fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Text(
            '$taskNumber.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              taskName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Container(
          //   width: 200,
          //   child: SliderTheme(
          //     data: SliderThemeData(
          //       trackHeight: 18.0,
          //       thumbShape: SliderComponentShape.noThumb,
          //       overlayShape: SliderComponentShape.noOverlay,
          //       activeTrackColor: Colors.green,
          //       inactiveTrackColor: Colors.grey[300],
          //       thumbColor: Colors.transparent,
          //       overlayColor: Colors.transparent,
          //     ),
          //     child: Slider(
          //       value: progress,
          //       min: 0.0,
          //       max: 1.0,
          //       onChanged: (value) {
          //         // You might want to handle slider changes if needed
          //       },
          //       divisions: 10,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
