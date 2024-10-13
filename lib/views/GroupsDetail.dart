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
    _startListeningToTasks(); // Listen for changes in tasks
    if (widget.groupId.isNotEmpty) {
      _fetchGroupDetails(); // Fetch group details
      _fetchTasks(); // Fetch initial tasks
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
                _updateTodoTasks([newTask]); // Push new tasks to followers
              });
            },
            groupId: widget.groupId,
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
          groupName = groupSnapshot['groupname'] ?? 'Unknown Group';
          creatorId = groupSnapshot['owner'] ?? '';
          _fetchCreatorUsername(creatorId);
          _checkIfFollowing();
          _checkIfCreator();
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
          creatorUsername = userSnapshot['username'] ?? 'Unknown Creator';
        });
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching creator username: $e');
    }
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
      }
    });
  }

  Future<void> _updateTodoTasks(List<Task> newTasks) async {
    try {
      DocumentSnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (groupSnapshot.exists) {
        List<dynamic> followers = groupSnapshot['followers'] ?? [];

        for (var follower in followers) {
          String followerId = follower['userId'].toString();

          List<Map<String, dynamic>> taskDataList = newTasks.map((task) {
            DateTime date = DateTime.now().add(Duration(days: 7)); // Example date
            int taskPriority = _calculateTaskPriority(date); // Calculate the priority
            String formattedDate = DateFormat('MM-dd-yyyy').format(date);

            // Ensure proper structure for tasks
            return {
              'title': task.taskName,   // Access the task name properly
              'progress': task.progress, // Include progress field if needed
              'userId': followerId,
              'date': formattedDate,
              'priority': taskPriority,
              'groupName': groupName,
            };
          }).toList();

          await FirebaseFirestore.instance
              .collection('todoTasks')
              .doc(followerId)
              .set({
            'Todotasks': FieldValue.arrayUnion(taskDataList),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      print('Error updating todoTasks for followers: $e');
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
        "https://studysync-bf9da.web.app"; // Example group link
    Clipboard.setData(ClipboardData(text: groupLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Group link copied to clipboard!')),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                    Icons.share), // You can replace this with a specific icon
                title: Text('Share on WhatsApp'),
                onTap: () {
                  _shareLink('WhatsApp');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share), // Replace with Instagram icon
                title: Text('Share on Instagram'),
                onTap: () {
                  _shareLink('Instagram');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share), // Replace with Facebook icon
                title: Text('Share on Facebook'),
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
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Color(0xFFc1121f), // Maroon color
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Wrap(
                          spacing: 5,
                          children: [

                            MediaQuery.of(context).size.width >= 600
                                ? Text(
                              groupName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                                : SizedBox.shrink(), // Returns an empty widget for mobile

                            Text(
                              'Created by: $creatorUsername',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 14, // 12 for mobile, 18 for web
                                color: Colors.white,
                              ),
                            ),

                            ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                isFollowing ? Colors.grey : Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isFollowing ? 'Following' : 'join',
                                style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 600 ? 10 : 14,
                                    color: Colors.white),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert,size: 10, color: Colors.white),
                              onSelected: (value) {
                                if (value == 'Share') {
                                  _showShareOptions();
                                } else if (value == 'Copy Link') {
                                  _copyGroupLink();
                                } else if (value == 'Members') {
                                  _fetchMembers(); // Define a method to show the list of members
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
                            )
                          ],
                        ),
                      ),


                      Container(
                        height: MediaQuery.of(context).size.height * 0.2, // Takes 50% of screen height
                        child: ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            return TaskItem(
                              taskNumber: (index + 1).toString(),
                              taskName: tasks[index].taskName,
                              progress: tasks[index].progress,
                            );
                          },
                        ),
                      ),



                      Spacer(),
                      // Conditionally show the "Manage Tasks" button
                      if (FirebaseAuth.instance.currentUser?.uid == creatorId)
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            onPressed: _showTaskPopup,
                            child: Text(
                              'Manage Tasks',
                              style:
                              TextStyle(fontSize: 12, color: Colors.white),
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
    _removeTaskFromFirestore(task); // Remove from Firestore
  }

  Future<void> _removeTaskFromFirestore(String taskName) async {
    try {
      if (widget.groupId.isEmpty) {
        throw Exception('Group ID is empty');
      }

      // Fetch the group document
      DocumentReference groupDoc = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

      // Remove the task from the group's Firestore document
      await groupDoc.update({
        'tasks': FieldValue.arrayRemove([{'task': taskName}]),
      });

      // Optionally, remove from the current user's todoTasks collection if needed
      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId != null) {
        DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(currentUserId);

        // Remove the task from the user's 'todoTasks' collection
        await userDoc.update({
          'todoTasks': FieldValue.arrayRemove([{'task': taskName}]),
        });
      }
    } catch (e) {
      print('Error removing task from Firestore: $e');
    }
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
    int daysUntilDue = dueDate.difference(today).inDays;
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
                  fontSize: 20,
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
          // Wrap task list in SingleChildScrollView
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: taskNames
                    .map((task) => TaskPopupItem(
                  task: task,
                  groupId: widget.groupId,
                  onTaskDeleted: _handleTaskDeletion,
                ))
                    .toList(),
              ),
            ),
          ),
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

        // Fetch the current tasks from Firestore
        DocumentSnapshot snapshot = await groupDoc.get();
        List<dynamic> tasks = snapshot['tasks'];

        // Find the task object to remove (matching by task name or other fields)
        Map<String, dynamic>? taskToRemove;
        for (var task in tasks) {
          if (task['task'] == this.task) {
            taskToRemove = task;
            break;
          }
        }

        if (taskToRemove != null) {
          // Remove the full task object from Firestore
          await groupDoc.update({
            'tasks': FieldValue.arrayRemove([taskToRemove]),
          });

          // Notify the parent to update the UI
          onTaskDeleted(this.task);
        } else {
          print('Task not found for deletion');
        }
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
    required this.progress,
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
          Container(
            width: 200,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 18.0,
                thumbShape: SliderComponentShape.noThumb,
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.green,
                inactiveTrackColor: Colors.grey[300],
                thumbColor: Colors.transparent,
                overlayColor: Colors.transparent,
              ),
              child: Slider(
                value: progress,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  // You might want to handle slider changes if needed
                },
                divisions: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
