import 'package:cloud_firestore/cloud_firestore.dart';

class TodoTask {
  final String title;
  final DateTime? date;
  final int priority;

  TodoTask({
    required this.title,
    this.date,
    required this.priority,
  });

  factory TodoTask.fromMap(Map<String, dynamic> map) {
    return TodoTask(
      title: map['title'],
      date: map['date'] is Timestamp ? (map['date'] as Timestamp).toDate() : null,
      priority: map['priority'],
    );
  }
}
