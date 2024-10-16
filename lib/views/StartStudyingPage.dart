import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CalendarToDoPage extends StatefulWidget {
  @override
  _CalendarToDoPageState createState() => _CalendarToDoPageState();
}

class _CalendarToDoPageState extends State<CalendarToDoPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String searchText = '';
  List<Map<String, dynamic>> todoList = [];
  List<Map<String, dynamic>> filteredTodoList = [];

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
              'date': task['date'] is Timestamp
                  ? (task['date'] as Timestamp).toDate() // Timestamp to DateTime
                  : DateFormat('MM-dd-yyyy').parse(task['date']), // String to DateTime
              'priority': task['priority'] ?? 0,
            };
          }).toList()
            ..sort((a, b) {
              int dateComparison = a['date'].compareTo(b['date']);
              if (dateComparison != 0) return dateComparison;
              return b['priority'].compareTo(a['priority']);
            });
          _filterTasks();
        });
      }
    } else {
      print('No user is logged in.');
    }
  }


  void _filterTasks() {
    setState(() {
      filteredTodoList = todoList.where((task) {
        return task['title'].toLowerCase().contains(searchText.toLowerCase());
      }).toList();
    });
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
              title: const Text("Add To-Do Item"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: taskController,
                    decoration: const InputDecoration(hintText: "Task Name"),
                  ),
                  const SizedBox(height: 10),
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
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 10),
                        Text(DateFormat('EEE, d MMM').format(selectedDate)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text("Add"),
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
      int priority = _calculatePriority(date);

      User? currentUser = FirebaseAuth.instance.currentUser;
      String userId = currentUser?.uid ?? '';

      if (userId.isNotEmpty) {
        setState(() {
          todoList.add({'title': title, 'date': date, 'priority': priority});
          todoList.sort((a, b) {
            // Sort by date first (ascending), then by priority (descending)
            int dateComparison = a['date'].compareTo(b['date']);
            if (dateComparison != 0) return dateComparison;
            return b['priority'].compareTo(a['priority']);
          });
          _filterTasks(); // Apply filter after adding a new item
        });

        await FirebaseFirestore.instance
            .collection('todoTasks')
            .doc(userId)
            .set({
          'Todotasks': FieldValue.arrayUnion([{
            'title': title,
            'date': Timestamp.fromDate(date), // Save as Firestore Timestamp
            'priority': priority,
          }])
        }, SetOptions(merge: true));
      } else {
        print('No user is logged in.');
      }
    }
  }

  int _calculatePriority(DateTime date) {
    DateTime now = DateTime.now();
    Duration difference = date.difference(now);

    if (difference.inDays <= 7) {
      return 3; // High priority
    } else if (difference.inDays <= 30) {
      return 2; // Medium priority
    } else {
      return 1; // Low priority
    }
  }

  void _deleteTodoItem(Map<String, dynamic> task) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      setState(() {
        todoList.remove(task);
        _filterTasks(); // Update filtered list
      });

      await FirebaseFirestore.instance.collection('todoTasks').doc(userId).update({
        'Todotasks': FieldValue.arrayRemove([{
          'title': task['title'],
          'date': Timestamp.fromDate(task['date']), // Ensure date is stored as a Timestamp
          'priority': task['priority'],
        }])
      });
    } else {
      print('No user is logged in.');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do Calendar'),
      ),
      body:  Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8.0 : 16.0), // Adjust padding based on screen width
        child:   LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600; // Adjust this threshold as needed

            return isMobile
                ? Column(
              children: [
                Container(

                  // Slightly increased padding
                  decoration: BoxDecoration(
                    color: const Color(0xff003039),
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14, // Adjust font size
                        fontWeight: FontWeight.w500, // Adjust font weight
                      ),
                      weekendTextStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14, // Adjust font size
                        fontWeight: FontWeight.w500, // Adjust font weight
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      titleTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 18, // Adjusted header font size
                        fontWeight: FontWeight.bold, // Adjusted header font weight
                      ),
                      formatButtonTextStyle: const TextStyle(color: Colors.white),
                      formatButtonDecoration: BoxDecoration(
                        color: Colors.lightBlue,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ),
                ),


                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // Uniform spacing
                    padding: const EdgeInsets.all(10.0), // Slightly increased padding
                    decoration: BoxDecoration(
                      color: const Color(0xff003039),
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              height: 30, // Add padding if needed
                              decoration: BoxDecoration(
                                color: Color(0xff003039), // Background color for the container
                                borderRadius: BorderRadius.circular(12.0), // Match the border radius
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    searchText = value;
                                    _filterTasks(); // Apply filter on search text change
                                  });
                                },
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Search for assignments...',
                                  labelStyle: const TextStyle(color: Colors.white),
                                  filled: true,
                                  fillColor: Colors.transparent, // Set to transparent for the TextField fill
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                    borderSide: const BorderSide(color: Colors.white),
                                  ),
                                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                                ),
                              ),
                            )

                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredTodoList.length,
                            itemBuilder: (context, index) {
                              return ToDoItem(
                                title: filteredTodoList[index]['title'],
                                initialDate: filteredTodoList[index]['date'],
                                onDelete: () {
                                  _deleteTodoItem(filteredTodoList[index]);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _showAddItemDialog,
                          child: const Row(
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
                  ),
                ),
              ],
            )

                : Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xff003039),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      calendarFormat: _calendarFormat,
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Colors.lightBlue,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: TextStyle(color: Colors.white),
                        weekendTextStyle: TextStyle(color: Colors.white70),
                      ),
                      headerStyle: HeaderStyle(
                        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                        formatButtonTextStyle: const TextStyle(color: Colors.white),
                        formatButtonDecoration: BoxDecoration(
                          color: Colors.lightBlue,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
                        rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xff003039),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchText = value;
                                _filterTasks(); // Apply filter on search text change
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Search for assignments...',
                              labelStyle: const TextStyle(color: Colors.white),
                              filled: true,
                              fillColor: const Color(0xff003039),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(color: Colors.white),
                              ),
                              prefixIcon: const Icon(Icons.search, color: Colors.white),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredTodoList.length,
                            itemBuilder: (context, index) {
                              return ToDoItem(
                                title: filteredTodoList[index]['title'],
                                initialDate: filteredTodoList[index]['date'],
                                onDelete: () {
                                  _deleteTodoItem(filteredTodoList[index]);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _showAddItemDialog,
                          child: const Row(
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
                  ),
                ),
              ],
            );
          },
        ),

      ),
    );
  }
}


class ToDoItem extends StatelessWidget {
  final String title;
  final DateTime initialDate;
  final VoidCallback onDelete;

  const ToDoItem({
    required this.title,
    required this.initialDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(DateFormat('EEE, d MMM').format(initialDate), style: const TextStyle(color: Colors.white70)),
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          // Show confirmation dialog before deletion
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Delete Task"),
                content: const Text("Do you really want to delete this task?"),
                actions: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                  ),
                  TextButton(
                    child: const Text("Delete"),
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      onDelete(); // Call the onDelete callback
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}


