import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodoTask {
  final String title;
  final DateTime? date;
  final int priority;

  TodoTask({required this.title, this.date, required this.priority});

  factory TodoTask.fromMap(Map<String, dynamic> map) {
    // Adjust date parsing based on the format in Firestore
    DateTime? parsedDate;
    if (map['date'] != null) {
      if (map['date'] is Timestamp) {
        // If the date is stored as a Firestore Timestamp
        parsedDate = (map['date'] as Timestamp).toDate();
      } else if (map['date'] is String) {
        // If the date is stored as a String, attempt to parse it
        try {
          parsedDate = DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(map['date']); // Assuming Firestore ISO format
        } catch (e) {
          print('Error parsing date string: $e');
        }
      }
    }

    return TodoTask(
      title: map['title'] ?? '',
      date: parsedDate,
      priority: map['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      // Ensure the date is converted to the correct format when saving back to Firestore
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'priority': priority,
    };
  }
}
