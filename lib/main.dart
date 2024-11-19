import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TaskTrackerApp());
}

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minute Minder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TaskTracker(title: 'Minute Minder'),
    );
  }
}

class TaskTracker extends StatefulWidget {
  const TaskTracker({super.key, required this.title});
  final String title;

  @override
  State<TaskTracker> createState() => _TaskTrackerState();
}

class _TaskTrackerState extends State<TaskTracker> {
  // Task Input Controllers
  final TextEditingController _dateInputController = TextEditingController();
  final TextEditingController _startTimeInputController = TextEditingController();
  final TextEditingController _endTimeInputController = TextEditingController();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskTagsController = TextEditingController();

  // Search Input Controllers
  final TextEditingController _searchDateController = TextEditingController();
  final TextEditingController _searchTagController = TextEditingController();
  final TextEditingController _searchNameController = TextEditingController();

  // Feedback Message
  String _statusMessage = '';

  Future<void> _addNewTask() async {
    try {
      DocumentReference newTaskRef = FirebaseFirestore.instance.collection('tasks').doc();

      await newTaskRef.set({
        'date': _dateInputController.text,
        'startTime': _startTimeInputController.text,
        'endTime': _endTimeInputController.text,
        'task': _taskNameController.text,
        'tags': _taskTagsController.text,
      });

      setState(() {
        _statusMessage = 'Task added: ${_taskNameController.text}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error adding task: $e';
      });
    }
  }

  Future<void> _showAllTaskList() async {
    try {
      QuerySnapshot querySnap = await FirebaseFirestore.instance.collection('tasks').get();
      List<QueryDocumentSnapshot> taskList = querySnap.docs;

      _showTaskDialog(taskList);
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to retreive tasks: $e';
      });
    }
  }

  void _showTaskDialog(List<QueryDocumentSnapshot> tasks) {
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
                    icon: const Icon(Icons.delete, color: Colors.pink),
                    onPressed: () {
                      _removeTask(taskId);
                      Navigator.of(context).pop(); // Close the dialog
                      _showAllTaskList(); // Refresh the task list
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

  Future<void> _removeTask(String taskId) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      setState(() {
        _statusMessage = 'Successfully Deleted';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to delete task: $e';
      });
    }
  }

  Future<void> _searchForTasks() async {
    try {
      Query query = FirebaseFirestore.instance.collection('tasks');

      if (_searchDateController.text.isNotEmpty) {
        query = query.where('date', isEqualTo: _searchDateController.text);
      }
      if (_searchTagController.text.isNotEmpty) {
        List<String> tags = _searchTagController.text.split(',').map((tag) => tag.trim()).toList();
        query = query.where('tags', whereIn: tags);
      }
      if (_searchNameController.text.isNotEmpty) {
        query = query.where('task', isEqualTo: _searchNameController.text);
      }

      QuerySnapshot querySnapshot = await query.get();
      _showSearchResults(querySnapshot.docs);
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to search tasks $e';
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
                  subtitle: Text('${data['date']} from ${data['startTime']} to ${data['endTime']} [Tags: ${data['tags']}]'),
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

  void _showAddTaskForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _dateInputController,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
                TextField(
                  controller: _startTimeInputController,
                  decoration: const InputDecoration(labelText: 'Start Time'),
                ),
                TextField(
                  controller: _endTimeInputController,
                  decoration: const InputDecoration(labelText: 'End Time'),
                ),
                TextField(
                  controller: _taskNameController,
                  decoration: const InputDecoration(labelText: 'Task Name'),
                ),
                TextField(
                  controller: _taskTagsController,
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
                _addNewTask();
                Navigator.of(context).pop();
              },
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  void _showSearchTaskForm() {
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
                  controller: _searchTagController,
                  decoration: const InputDecoration(labelText: 'Tags'),
                ),
                TextField(
                  controller: _searchNameController,
                  decoration: const InputDecoration(labelText: 'Task Name'),
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
                _searchForTasks();
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
              onPressed: _showAllTaskList,
              child: const Text('Show All Tasks'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showAddTaskForm,
              child: const Text('Add Task'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showSearchTaskForm,
              child: const Text('Search Tasks'),
            ),
            const SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}
