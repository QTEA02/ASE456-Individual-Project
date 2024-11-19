import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MinuteMinderApp());
}

class MinuteMinderApp extends StatelessWidget {
  const MinuteMinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minute Minder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TaskManagerScreen(title: 'Minute Minder'),
    );
  }
}

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key, required this.title});
  final String title;

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  // Task Input Controllers
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  // Search Input Controllers
  final TextEditingController _searchDateController = TextEditingController();
  final TextEditingController _searchTagsController = TextEditingController();
  final TextEditingController _searchTaskController = TextEditingController();

  // Feedback Message
  String _message = '';

  Future<void> _addTask() async {
    try {
      DocumentReference newTaskRef = FirebaseFirestore.instance.collection('tasks').doc();

      await newTaskRef.set({
        'date': _dateController.text,
        'startTime': _startTimeController.text,
        'endTime': _endTimeController.text,
        'task': _taskController.text,
        'tags': _tagsController.text,
      });

      setState(() {
        _message = 'Task added successfully: ${_taskController.text}';
      });
    } catch (e) {
      setState(() {
        _message = 'Error adding task: $e';
      });
    }
  }

  Future<void> _showAllTasks() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('tasks').get();
      List<QueryDocumentSnapshot> tasks = querySnapshot.docs;

      _showTaskListDialog(tasks);
    } catch (e) {
      setState(() {
        _message = 'Error retrieving tasks: $e';
      });
    }
  }

  void _showTaskListDialog(List<QueryDocumentSnapshot> tasks) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('All Tasks'),
          content: SingleChildScrollView(
            child: ListBody(
              children: tasks.map((task) {
                Map<String, dynamic> data = task.data() as Map<String, dynamic>;
                String taskId = task.id;

                return ListTile(
                  title: Text(data['task'] ?? 'Unnamed Task'),
                  subtitle: Text('${data['date']} from ${data['startTime']} to ${data['endTime']} [Tags: ${data['tags']}]'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteTask(taskId);
                      Navigator.of(context).pop(); // Close the dialog
                      _showAllTasks(); // Refresh the task list
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      setState(() {
        _message = 'Task deleted successfully.';
      });
    } catch (e) {
      setState(() {
        _message = 'Error deleting task: $e';
      });
    }
  }

  Future<void> _searchTasks() async {
    try {
      Query query = FirebaseFirestore.instance.collection('tasks');

      if (_searchDateController.text.isNotEmpty) {
        query = query.where('date', isEqualTo: _searchDateController.text);
      }
      if (_searchTagsController.text.isNotEmpty) {
        List<String> tags = _searchTagsController.text.split(',').map((tag) => tag.trim()).toList();
        query = query.where('tags', whereIn: tags);
      }
      if (_searchTaskController.text.isNotEmpty) {
        query = query.where('task', isEqualTo: _searchTaskController.text);
      }

      QuerySnapshot querySnapshot = await query.get();
      _showSearchResults(querySnapshot.docs);
    } catch (e) {
      setState(() {
        _message = 'Error searching tasks: $e';
      });
    }
  }

  void _showSearchResults(List<QueryDocumentSnapshot> tasks) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Results'),
          content: SingleChildScrollView(
            child: ListBody(
              children: tasks.map((task) {
                Map<String, dynamic> data = task.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['task'] ?? 'Unnamed Task'),
                  subtitle: Text(
                      '${data['date']} from ${data['startTime']} to ${data['endTime']} [Tags: ${data['tags']}]'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
                TextField(
                  controller: _startTimeController,
                  decoration: const InputDecoration(labelText: 'Start Time'),
                ),
                TextField(
                  controller: _endTimeController,
                  decoration: const InputDecoration(labelText: 'End Time'),
                ),
                TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(labelText: 'Task'),
                ),
                TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(labelText: 'Tags'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addTask();
                Navigator.of(context).pop();
              },
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  void _showSearchTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Tasks'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _searchDateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
                TextField(
                  controller: _searchTagsController,
                  decoration: const InputDecoration(labelText: 'Tags'),
                ),
                TextField(
                  controller: _searchTaskController,
                  decoration: const InputDecoration(labelText: 'Task'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _searchTasks();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _showAllTasks,
              child: const Text('Show All Tasks'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAddTaskDialog,
              child: const Text('Add Task'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showSearchTaskDialog,
              child: const Text('Search Tasks'),
            ),
            const SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
