import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'TimerScreen.dart'; // For formatting the date

void main() {
  runApp(StudySyncDashboard());
}

class StudySyncDashboard extends StatelessWidget {
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
                HeaderSection(),
                SizedBox(height: 20),
                Expanded(
                  child: Row(
                    children: [
                      // Left: TO-DO List
                      Expanded(flex: 2, child: ToDoSection()),
                      SizedBox(width: 20),
                      // Right: Daily Streak & Time Spent
                      Expanded(flex: 3, child: StatsSection()),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Start Studying Button
                StartStudyingButton(),
                SizedBox(height: 10),
                // Advertisement Section
                AdvertisementSection(),
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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'STUDYSYNC',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        HeaderLink(text: 'Friends'),
        SizedBox(width: 60,),
        HeaderLink(text: 'Groups'),
        SizedBox(width: 60,),
        HeaderLink(text: 'Profile'),
        SizedBox(width: 20,),
      ],
    );
  }
}

class HeaderLink extends StatelessWidget {
  final String text;

  const HeaderLink({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}

// TO-DO Section
class ToDoSection extends StatelessWidget {
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
            child: ListView(
              children: [
                ToDoItem(title: 'Organic Chemistry Lecture', initialDate: DateTime(2023, 9, 1)),
                ToDoItem(title: 'Economics Essay', initialDate: DateTime(2023, 9, 1)),
                ToDoItem(title: 'Economics Essay', initialDate: DateTime(2023, 9, 2)),
                SizedBox(height: 10,),
                Row(
                  children: [
                    Icon(Icons.add_circle,color: Colors.white,),
                    SizedBox(width: 20,),
                    Text('Add Item',style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ToDoItem class with clickable date picker
class ToDoItem extends StatefulWidget {
  final String title;
  final DateTime initialDate;

  const ToDoItem({required this.title, required this.initialDate});

  @override
  _ToDoItemState createState() => _ToDoItemState();
}

class _ToDoItemState extends State<ToDoItem> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate; // Set initial date
  }

  // Function to open date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate, // Current date selected
      firstDate: DateTime(2020), // The minimum year the user can pick
      lastDate: DateTime(2101),  // The maximum year the user can pick
    );
    if (pickedDate != null && pickedDate != selectedDate)
      setState(() {
        selectedDate = pickedDate;
      });
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
                // Check if the item is the Organic Chemistry Lecture
                if (widget.title == 'Organic Chemistry Lecture') {
                  // Navigate to the Timer screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimerScreen(),
                    ),
                  );
                }
              },
              child: Text(
                widget.title,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          // GestureDetector to handle the date click
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Text(
              DateFormat('EEE, d MMM').format(selectedDate), // Format the date
              style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}


// Stats Section: Daily Streak and Time Spent
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

class DailyStreakSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAILY STREAK: 5 🔥',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          '* Streak counter: The streaks increase when a person logs in every consecutive day. It restarts from 0 if a person misses a day.',
          style: TextStyle(fontSize: 12),
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
          'Time spent on this week: XXh XXmin',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          '* Statistics on time spent on the app',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// Start Studying Button
class StartStudyingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xff003039), // Background color
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          // Navigate to the next slide
        },
        child: Text(
          'START STUDYING',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}

// Advertisement Section
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
