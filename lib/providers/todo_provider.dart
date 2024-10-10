// lib/todo_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TodoProvider extends ChangeNotifier {
  List<Map<String, dynamic>> todoList = [];
  List<Map<String, dynamic>> filteredTodoList = [];
  String searchText = '';

  TodoProvider() {
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
        todoList = tasks.map((task) {
          return {
            'id': task['id'],
            'title': task['title'],
            'date': task['date'] is Timestamp
                ? (task['date'] as Timestamp).toDate()
                : DateFormat('MM-dd-yyyy').parse(task['date']),
            'priority': task['priority'] ?? 0,
          };
        }).toList()
          ..sort((a, b) {
            int dateComparison = a['date'].compareTo(b['date']);
            if (dateComparison != 0) return dateComparison;
            return b['priority'].compareTo(a['priority']);
          });
        _filterTasks();
        notifyListeners();
      }
    }
  }

  void _filterTasks() {
    filteredTodoList = todoList.where((task) {
      return task['title'].toLowerCase().contains(searchText.toLowerCase());
    }).toList();
    notifyListeners();
  }

  void updateSearchText(String value) {
    searchText = value;
    _filterTasks();
  }

  Future<void> addTodoItem(String title, DateTime date) async {
    if (title.isNotEmpty) {
      int priority = _calculatePriority(date);
      User? currentUser = FirebaseAuth.instance.currentUser;
      String userId = currentUser?.uid ?? '';

      if (userId.isNotEmpty) {
        String taskId = FirebaseFirestore.instance
            .collection('todoTasks')
            .doc(userId)
            .collection('tasks')
            .doc()
            .id;

        todoList.add({'id': taskId, 'title': title, 'date': date, 'priority': priority});
        todoList.sort((a, b) {
          int dateComparison = a['date'].compareTo(b['date']);
          if (dateComparison != 0) return dateComparison;
          return b['priority'].compareTo(a['priority']);
        });
        _filterTasks();

        await FirebaseFirestore.instance.collection('todoTasks').doc(userId).set({
          'Todotasks': FieldValue.arrayUnion([{
            'id': taskId,
            'title': title,
            'date': Timestamp.fromDate(date),
            'priority': priority,
          }])
        }, SetOptions(merge: true));
        notifyListeners();
      }
    }
  }

  Future<void> deleteTodoItem(Map<String, dynamic> task) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userId = currentUser?.uid ?? '';

    if (userId.isNotEmpty) {
      todoList.remove(task);
      _filterTasks();
      await FirebaseFirestore.instance.collection('todoTasks').doc(userId).update({
        'Todotasks': FieldValue.arrayRemove([{
          'id': task['id'],
          'title': task['title'],
          'date': Timestamp.fromDate(task['date']),
          'priority': task['priority'],
        }])
      });
      notifyListeners();
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
}
