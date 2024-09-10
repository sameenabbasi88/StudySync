import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(TimerScreen());
}

class TimerScreen extends StatefulWidget {
  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late Timer _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = true;
      _timer.cancel();
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });
    _startTimer();
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _timer.cancel();
      _seconds = 0;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("STUDYSYNC"),
          backgroundColor: Colors.red,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Friends"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Groups"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Profile"),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today, 25 August 2024",
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
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
                                style: TextStyle(
                                    fontSize: 50, color: Colors.white),
                              ),
                              SizedBox(height: 20),
                              if (!_isRunning)
                                ElevatedButton(
                                  onPressed: _startTimer,
                                  child: Text("START"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              if (_isRunning && !_isPaused)
                                ElevatedButton(
                                  onPressed: _pauseTimer,
                                  child: Text("PAUSE"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              if (_isPaused)
                                ElevatedButton(
                                  onPressed: _resumeTimer,
                                  child: Text("RESUME"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              SizedBox(height: 10),
                              if (_isRunning)
                                ElevatedButton(
                                  onPressed: _stopTimer,
                                  child: Text("Finish"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              SizedBox(height: 10),
                              Text(
                                "Timer is default",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _seconds = 0; // Reset seconds
                                  });
                                  _startTimer();
                                },
                                child: Text(
                                  "TIMER | STOPWATCH | POMODORO",
                                  style: TextStyle(color: Colors.white),
                                ),
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
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TASKS FOR THIS SESSION",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "Organic Chemistry Lecture",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      leading: Radio(
                                        value: 1,
                                        groupValue: 1,
                                        onChanged: (value) {},
                                      ),
                                    ),
                                    SizedBox(height: 20),
                                    Text(
                                      "Other Uncompleted Tasks",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "Economics Essay\nSun, 1 Sep",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      leading: Radio(
                                        value: 2,
                                        groupValue: 1,
                                        onChanged: (value) {},
                                      ),
                                    ),
                                    ListTile(
                                      title: Text(
                                        "History Essay\nSun, 1 Sep",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      leading: Radio(
                                        value: 3,
                                        groupValue: 1,
                                        onChanged: (value) {},
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
                  ],
                ),
              ),
            ),
            AdvertisementSection(),
          ],
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
