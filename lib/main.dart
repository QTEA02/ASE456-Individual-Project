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

  // Time Format Toggles
  bool is24HourFormat = false;
  bool? isStartPm;
  bool? isEndPm;

  Future<void> _addNewTask() async {
    if (_dateInputController.text.isEmpty ||
        _startTimeInputController.text.isEmpty ||
        _endTimeInputController.text.isEmpty ||
        _taskNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields')),
      );
      return;
    }

    String startTime = is24HourFormat
        ? _startTimeInputController.text
        : _convertTo24Hour(_startTimeInputController.text, isStartPm);

    String endTime = is24HourFormat
        ? _endTimeInputController.text
        : _convertTo24Hour(_endTimeInputController.text, isEndPm);

    await FirebaseFirestore.instance.collection('tasks').add({
      'date': _dateInputController.text,
      'startTime': startTime,
      'endTime': endTime,
      'task': _taskNameController.text,
      'tags': _taskTagsController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task added successfully!')),
    );

    // Clear form
    _dateInputController.clear();
    _startTimeInputController.clear();
    _endTimeInputController.clear();
    _taskNameController.clear();
    _taskTagsController.clear();

    setState(() {
      _statusMessage = 'Task added successfully!';
      isStartPm = null;
      isEndPm = null;
    });
  }

  String _convertTo24Hour(String time, bool? isPm) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      if (isPm == true && hour < 12) hour += 12;
      if (isPm == false && hour == 12) hour = 0;

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Time';
    }
  }

  Future<void> _showAllTaskList() async {
    try {
      QuerySnapshot querySnap = await FirebaseFirestore.instance.collection('tasks').get();
      List<QueryDocumentSnapshot> taskList = querySnap.docs;

      _showTaskDialog(taskList);
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to retrieve tasks: $e';
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
            child: Column(
              children: tasks.map((task) {
                final data = task.data() as Map<String, dynamic>;

                return ListTile(
                  title: Text(data['task'] ?? 'Unnamed Task'),
                  subtitle: Text(
                    '${data['date']} from ${data['startTime']} to ${data['endTime']} [Tags: ${data['tags']}]',
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

  Future<void> _searchForTasks() async {
    try {
      Query query = FirebaseFirestore.instance.collection('tasks');

      if (_searchDateController.text.isNotEmpty) {
        query = query.where('date', isEqualTo: _searchDateController.text);
      }
      if (_searchTagController.text.isNotEmpty) {
        query = query.where('tags', isEqualTo: _searchTagController.text);
      }
      if (_searchNameController.text.isNotEmpty) {
        query = query.where('task', isEqualTo: _searchNameController.text);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tasks found for the given criteria')),
        );
      } else {
        _showSearchResults(querySnapshot.docs);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to search tasks: $e';
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
            child: Column(
              children: tasks.map((task) {
                Map<String, dynamic> data = task.data() as Map<String, dynamic>;

                return ListTile(
                  title: Text(data['task'] ?? 'Unnamed Task'),
                  subtitle: Text(
                    '${data['date']} from ${data['startTime']} to ${data['endTime']} [Tags: ${data['tags']}]',
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

  void _showAddTaskForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _dateInputController,
                      decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                    ),
                    TextField(
                      controller: _startTimeInputController,
                      decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
                    ),
                    if (!is24HourFormat)
                      Row(
                        children: [
                          const Text('AM'),
                          Radio<bool?>(
                            value: false,
                            groupValue: isStartPm,
                            onChanged: (value) {
                              setState(() {
                                isStartPm = value;
                              });
                            },
                          ),
                          const Text('PM'),
                          Radio<bool?>(
                            value: true,
                            groupValue: isStartPm,
                            onChanged: (value) {
                              setState(() {
                                isStartPm = value;
                              });
                            },
                          ),
                        ],
                      ),
                    TextField(
                      controller: _endTimeInputController,
                      decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
                    ),
                    if (!is24HourFormat)
                      Row(
                        children: [
                          const Text('AM'),
                          Radio<bool?>(
                            value: false,
                            groupValue: isEndPm,
                            onChanged: (value) {
                              setState(() {
                                isEndPm = value;
                              });
                            },
                          ),
                          const Text('PM'),
                          Radio<bool?>(
                            value: true,
                            groupValue: isEndPm,
                            onChanged: (value) {
                              setState(() {
                                isEndPm = value;
                              });
                            },
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        const Text('24-Hour Format'),
                        Checkbox(
                          value: is24HourFormat,
                          onChanged: (value) {
                            setState(() {
                              is24HourFormat = value!;
                              isStartPm = null;
                              isEndPm = null;
                            });
                          },
                        ),
                      ],
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
                  decoration: const InputDecoration(labelText: 'Search by Date (YYYY-MM-DD)'),
                ),
                TextField(
                  controller: _searchTagController,
                  decoration: const InputDecoration(labelText: 'Search by Tag'),
                ),
                TextField(
                  controller: _searchNameController,
                  decoration: const InputDecoration(labelText: 'Search by Task Name'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _searchForTasks(); // Execute the search

                // Clear the search fields
                _searchDateController.clear();
                _searchTagController.clear();
                _searchNameController.clear();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }


  void _showTimeUsageMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time Usage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showTimeUsageByDate();
                },
                child: const Text('Time Usage by Date'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showTimeUsageByTag();
                },
                child: const Text('Time Usage by Tag'),
              ),
            ],
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

  void _showTimeUsageByTag() {
    TextEditingController tagInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time Usage by Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tagInputController,
                decoration: const InputDecoration(labelText: 'Enter Tag'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String tag = tagInputController.text.trim();
                if (tag.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a tag')),
                  );
                  return;
                }
                await _calculateTimeByTag(tag);

              },
              child: const Text('Calculate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _calculateTimeByTag(String tag) async {
    try {
      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('tags', isEqualTo: tag)
          .get();

      int totalMinutes = 0;

      for (var task in querySnap.docs) {
        final data = task.data() as Map<String, dynamic>;
        String startTime = data['startTime'] ?? '';
        String endTime = data['endTime'] ?? '';

        totalMinutes += _calculateTimeDifferenceInMinutes(startTime, endTime);
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Tag Usage Summary'),
            content: Text('You spent $totalMinutes minutes on tag "$tag".'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();// Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating time by tag: $e')),
      );
    }
  }

  void _showTimeUsageByDate() {
    TextEditingController fromDateController = TextEditingController();
    TextEditingController toDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time Usage by Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fromDateController,
                decoration: const InputDecoration(labelText: 'From Date (YYYY/MM/DD)'),
              ),
              TextField(
                controller: toDateController,
                decoration: const InputDecoration(labelText: 'To Date (YYYY/MM/DD)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String fromDate = fromDateController.text.trim();
                String toDate = toDateController.text.trim();
                if (fromDate.isEmpty || toDate.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both dates')),
                  );
                  return;
                }
                await _calculateTimeByDateRange(fromDate, toDate);
              },
              child: const Text('Calculate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _calculateTimeByDateRange(String fromDate, String toDate) async {
    try {
      // Fetch tasks within the date range
      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: fromDate)
          .where('date', isLessThanOrEqualTo: toDate)
          .get();

      if (querySnap.docs.isEmpty) {
        // No tasks found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tasks found in the specified date range.')),
        );
        return;
      }

      // Display tasks and calculate time spent on each
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Tasks and Time Spent'),
            content: SingleChildScrollView(
              child: Column(
                children: querySnap.docs.map((task) {
                  final data = task.data() as Map<String, dynamic>;
                  String startTime = data['startTime'] ?? '';
                  String endTime = data['endTime'] ?? '';
                  int minutesSpent = _calculateTimeDifferenceInMinutes(startTime, endTime);

                  return ListTile(
                    title: Text(data['task'] ?? 'Unnamed Task'),
                    subtitle: Text(
                      '${data['date']} from ${data['startTime']} to ${data['endTime']} ($minutesSpent minutes)',
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrieving tasks: $e')),
      );
    }
  }


  DateTime _parseDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) {
        throw FormatException('Invalid date format');
      }
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      throw FormatException('Invalid date format: $date. Expected YYYY/MM/DD');
    }
  }


  int _calculateTimeDifferenceInMinutes(String startTime, String endTime) {
    try {
      final startParts = startTime.split(':').map(int.parse).toList();
      final endParts = endTime.split(':').map(int.parse).toList();

      final startMinutes = startParts[0] * 60 + startParts[1];
      final endMinutes = endParts[0] * 60 + endParts[1];

      return endMinutes - startMinutes;
    } catch (e) {
      return 0;
    }
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
            ElevatedButton(
              onPressed: _showTimeUsageMenu,
              child: const Text('Time Usage'),
            ),
            const SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}


devide these into a DBHandler Class, RecordRepository class, query class that has task, date, and tag, a userHandler class, and a validate class.

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

  // Time Format Toggles
  bool is24HourFormat = false;
  bool? isStartPm;
  bool? isEndPm;

  Future<void> _addNewTask() async {
    if (_dateInputController.text.isEmpty ||
        _startTimeInputController.text.isEmpty ||
        _endTimeInputController.text.isEmpty ||
        _taskNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields')),
      );
      return;
    }

    String startTime = is24HourFormat
        ? _startTimeInputController.text
        : _convertTo24Hour(_startTimeInputController.text, isStartPm);

    String endTime = is24HourFormat
        ? _endTimeInputController.text
        : _convertTo24Hour(_endTimeInputController.text, isEndPm);

    await FirebaseFirestore.instance.collection('tasks').add({
      'date': _dateInputController.text,
      'startTime': startTime,
      'endTime': endTime,
      'task': _taskNameController.text,
      'tags': _taskTagsController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task added successfully!')),
    );

    // Clear form
    _dateInputController.clear();
    _startTimeInputController.clear();
    _endTimeInputController.clear();
    _taskNameController.clear();
    _taskTagsController.clear();

    setState(() {
      _statusMessage = 'Task added successfully!';
      isStartPm = null;
      isEndPm = null;
    });
  }

  String _convertTo24Hour(String time, bool? isPm) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      if (isPm == true && hour < 12) hour += 12;
      if (isPm == false && hour == 12) hour = 0;

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Time';
    }
  }

  Future<void> _showAllTaskList() async {
    try {
      QuerySnapshot querySnap = await FirebaseFirestore.instance.collection('tasks').get();
      List<QueryDocumentSnapshot> taskList = querySnap.docs;

      _showTaskDialog(taskList);
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to retrieve tasks: $e';
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
            child: Column(
              children: tasks.map((task) {
                final data = task.data() as Map<String, dynamic>;

                return ListTile(
                  title: Text(data['task'] ?? 'Unnamed Task'),
                  subtitle: Text(
                    '${data['date']} from ${data['startTime']} to ${data['endTime']} [Tags: ${data['tags']}]',
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

  Future<void> _searchForTasks() async {
    try {
      Query query = FirebaseFirestore.instance.collection('tasks');

      if (_searchDateController.text.isNotEmpty) {
        query = query.where('date', isEqualTo: _searchDateController.text);
      }
      if (_searchTagController.text.isNotEmpty) {
        query = query.where('tags', isEqualTo: _searchTagController.text);
      }
      if (_searchNameController.text.isNotEmpty) {
        query = query.where('task', isEqualTo: _searchNameController.text);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tasks found for the given criteria')),
        );
      } else {
        _showSearchResults(querySnapshot.docs);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Unable to search tasks: $e';
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
            child: Column(
              children: tasks.map((task) {
                Map<String, dynamic> data = task.data() as Map<String, dynamic>;

                return ListTile(
                  title: Text(data['task'] ?? 'Unnamed Task'),
                  subtitle: Text(
                    '${data['date']} from ${data['startTime']} to ${data['endTime']} [Tags: ${data['tags']}]',
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

  void _showAddTaskForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _dateInputController,
                      decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                    ),
                    TextField(
                      controller: _startTimeInputController,
                      decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
                    ),
                    if (!is24HourFormat)
                      Row(
                        children: [
                          const Text('AM'),
                          Radio<bool?>(
                            value: false,
                            groupValue: isStartPm,
                            onChanged: (value) {
                              setState(() {
                                isStartPm = value;
                              });
                            },
                          ),
                          const Text('PM'),
                          Radio<bool?>(
                            value: true,
                            groupValue: isStartPm,
                            onChanged: (value) {
                              setState(() {
                                isStartPm = value;
                              });
                            },
                          ),
                        ],
                      ),
                    TextField(
                      controller: _endTimeInputController,
                      decoration: const InputDecoration(labelText: 'End Time (HH:MM)'),
                    ),
                    if (!is24HourFormat)
                      Row(
                        children: [
                          const Text('AM'),
                          Radio<bool?>(
                            value: false,
                            groupValue: isEndPm,
                            onChanged: (value) {
                              setState(() {
                                isEndPm = value;
                              });
                            },
                          ),
                          const Text('PM'),
                          Radio<bool?>(
                            value: true,
                            groupValue: isEndPm,
                            onChanged: (value) {
                              setState(() {
                                isEndPm = value;
                              });
                            },
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        const Text('24-Hour Format'),
                        Checkbox(
                          value: is24HourFormat,
                          onChanged: (value) {
                            setState(() {
                              is24HourFormat = value!;
                              isStartPm = null;
                              isEndPm = null;
                            });
                          },
                        ),
                      ],
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
                  decoration: const InputDecoration(labelText: 'Search by Date (YYYY-MM-DD)'),
                ),
                TextField(
                  controller: _searchTagController,
                  decoration: const InputDecoration(labelText: 'Search by Tag'),
                ),
                TextField(
                  controller: _searchNameController,
                  decoration: const InputDecoration(labelText: 'Search by Task Name'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _searchForTasks(); // Execute the search

                // Clear the search fields
                _searchDateController.clear();
                _searchTagController.clear();
                _searchNameController.clear();
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }


  void _showTimeUsageMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time Usage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showTimeUsageByDate();
                },
                child: const Text('Time Usage by Date'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showTimeUsageByTag();
                },
                child: const Text('Time Usage by Tag'),
              ),
            ],
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

  void _showTimeUsageByTag() {
    TextEditingController tagInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time Usage by Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tagInputController,
                decoration: const InputDecoration(labelText: 'Enter Tag'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String tag = tagInputController.text.trim();
                if (tag.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a tag')),
                  );
                  return;
                }
                await _calculateTimeByTag(tag);

              },
              child: const Text('Calculate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _calculateTimeByTag(String tag) async {
    try {
      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('tags', isEqualTo: tag)
          .get();

      int totalMinutes = 0;

      for (var task in querySnap.docs) {
        final data = task.data() as Map<String, dynamic>;
        String startTime = data['startTime'] ?? '';
        String endTime = data['endTime'] ?? '';

        totalMinutes += _calculateTimeDifferenceInMinutes(startTime, endTime);
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Tag Usage Summary'),
            content: Text('You spent $totalMinutes minutes on tag "$tag".'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();// Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating time by tag: $e')),
      );
    }
  }

  void _showTimeUsageByDate() {
    TextEditingController fromDateController = TextEditingController();
    TextEditingController toDateController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time Usage by Date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fromDateController,
                decoration: const InputDecoration(labelText: 'From Date (YYYY/MM/DD)'),
              ),
              TextField(
                controller: toDateController,
                decoration: const InputDecoration(labelText: 'To Date (YYYY/MM/DD)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String fromDate = fromDateController.text.trim();
                String toDate = toDateController.text.trim();
                if (fromDate.isEmpty || toDate.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both dates')),
                  );
                  return;
                }
                await _calculateTimeByDateRange(fromDate, toDate);
              },
              child: const Text('Calculate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _calculateTimeByDateRange(String fromDate, String toDate) async {
    try {
      // Fetch tasks within the date range
      QuerySnapshot querySnap = await FirebaseFirestore.instance
          .collection('tasks')
          .where('date', isGreaterThanOrEqualTo: fromDate)
          .where('date', isLessThanOrEqualTo: toDate)
          .get();

      if (querySnap.docs.isEmpty) {
        // No tasks found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tasks found in the specified date range.')),
        );
        return;
      }

      // Display tasks and calculate time spent on each
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Tasks and Time Spent'),
            content: SingleChildScrollView(
              child: Column(
                children: querySnap.docs.map((task) {
                  final data = task.data() as Map<String, dynamic>;
                  String startTime = data['startTime'] ?? '';
                  String endTime = data['endTime'] ?? '';
                  int minutesSpent = _calculateTimeDifferenceInMinutes(startTime, endTime);

                  return ListTile(
                    title: Text(data['task'] ?? 'Unnamed Task'),
                    subtitle: Text(
                      '${data['date']} from ${data['startTime']} to ${data['endTime']} ($minutesSpent minutes)',
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error retrieving tasks: $e')),
      );
    }
  }


  DateTime _parseDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) {
        throw FormatException('Invalid date format');
      }
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (e) {
      throw FormatException('Invalid date format: $date. Expected YYYY/MM/DD');
    }
  }


  int _calculateTimeDifferenceInMinutes(String startTime, String endTime) {
    try {
      final startParts = startTime.split(':').map(int.parse).toList();
      final endParts = endTime.split(':').map(int.parse).toList();

      final startMinutes = startParts[0] * 60 + startParts[1];
      final endMinutes = endParts[0] * 60 + endParts[1];

      return endMinutes - startMinutes;
    } catch (e) {
      return 0;
    }
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
            ElevatedButton(
              onPressed: _showTimeUsageMenu,
              child: const Text('Time Usage'),
            ),
            const SizedBox(height: 20),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}
