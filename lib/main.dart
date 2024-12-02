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

                // Convert time to 24-hour format if AM/PM is selected
                String convertTo24Hour(String? time, String? amPm) {
                  if (time == null || time.isEmpty) {
                    return 'Invalid Time'; // Default for missing times
                  }

                  try {
                    // Split "HH:MM"
                    final timeParts = time.split(':');
                    if (timeParts.length != 2) {
                      return 'Invalid Time'; // Ensure time is in "HH:MM" format
                    }

                    int hour = int.parse(timeParts[0]);
                    int minute = int.parse(timeParts[1]);

                    // Handle AM/PM conversions
                    if (amPm != null && amPm.isNotEmpty) {
                      amPm = amPm.toUpperCase(); // Ensure AM/PM is uppercase
                      if (amPm == "PM" && hour < 12) {
                        hour += 12; // Add 12 hours for PM times
                      } else if (amPm == "AM" && hour == 12) {
                        hour = 0; // Convert 12 AM to 00:00
                      }
                    }

                    // Format time back to HH:MM
                    final formattedHour = hour.toString().padLeft(2, '0');
                    final formattedMinute = minute.toString().padLeft(2, '0');
                    return '$formattedHour:$formattedMinute';
                  } catch (e) {
                    return 'Invalid Time'; // Handle parsing errors gracefully
                  }
                }

                // Retrieve start and end times along with AM/PM
                String startTime = convertTo24Hour(
                  data['startTime']?.toString(),
                  data['startAmPm']?.toString(),
                );
                String endTime = convertTo24Hour(
                  data['endTime']?.toString(),
                  data['endAmPm']?.toString(),
                );

                // Display the date as a string
                String formattedDate = data['date'] ?? 'Unknown Date';

                return ListTile(
                  title: Text(data['task'] ?? 'Unnamed Task'),
                  subtitle: Text(
                    '$formattedDate from $startTime to $endTime [Tags: ${data['tags']}]',
                  ),
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
        bool? isStartPm; // For start time AM/PM toggle
        bool? isEndPm; // For end time AM/PM toggle
        bool is24HourFormat = false; // Whether to use 24-hour format

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
                      decoration: const InputDecoration(labelText: 'Date'),
                    ),
                    TextField(
                      controller: _startTimeInputController,
                      decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'),
                    ),
                    if (!is24HourFormat) // Show AM/PM options only if not in 24-hour format
                      Row(
                        children: [
                          const Text('AM:'),
                          Radio<bool?>(
                            value: false,
                            groupValue: isStartPm,
                            onChanged: (value) {
                              setState(() {
                                isStartPm = value;
                              });
                            },
                          ),
                          const Text('PM:'),
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
                    if (!is24HourFormat) // Show AM/PM options only if not in 24-hour format
                      Row(
                        children: [
                          const Text('AM:'),
                          Radio<bool?>(
                            value: false,
                            groupValue: isEndPm,
                            onChanged: (value) {
                              setState(() {
                                isEndPm = value;
                              });
                            },
                          ),
                          const Text('PM:'),
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
                    const SizedBox(height: 16.0),
                    const Text('Time Format:'),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: is24HourFormat,
                          onChanged: (value) {
                            setState(() {
                              is24HourFormat = value!;
                              isStartPm = null; // Reset AM/PM selection
                              isEndPm = null; // Reset AM/PM selection
                            });
                          },
                        ),
                        const Text('24-Hour'),
                        const SizedBox(width: 16.0),
                        Radio<bool>(
                          value: false,
                          groupValue: is24HourFormat,
                          onChanged: (value) {
                            setState(() {
                              is24HourFormat = value!;
                            });
                          },
                        ),
                        const Text('AM/PM'),
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
                    // Validate inputs
                    if (!is24HourFormat && (isStartPm == null || isEndPm == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select AM or PM for both times.')),
                      );
                      return;
                    }

                    // Convert times to 24-hour format if using AM/PM
                    String convertTo24Hour(String time, bool? isPm) {
                      try {
                        final parts = time.split(':');
                        int hour = int.parse(parts[0]);
                        int minute = int.parse(parts[1]);

                        if (isPm == true && hour < 12) {
                          hour += 12; // Add 12 for PM times
                        } else if (isPm == false && hour == 12) {
                          hour = 0; // Convert 12 AM to 00:00
                        }

                        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                      } catch (e) {
                        return 'Invalid Time';
                      }
                    }

                    // Determine final start and end times
                    String startTime = is24HourFormat
                        ? _startTimeInputController.text
                        : convertTo24Hour(_startTimeInputController.text, isStartPm);

                    String endTime = is24HourFormat
                        ? _endTimeInputController.text
                        : convertTo24Hour(_endTimeInputController.text, isEndPm);

                    // Save task to Firestore
                    FirebaseFirestore.instance.collection('tasks').add({
                      'date': _dateInputController.text,
                      'startTime': startTime,
                      'endTime': endTime,
                      'task': _taskNameController.text,
                      'tags': _taskTagsController.text,
                    }).then((_) {
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task added successfully!')),
                      );

                      // Clear form fields
                      _dateInputController.clear();
                      _startTimeInputController.clear();
                      _endTimeInputController.clear();
                      _taskNameController.clear();
                      _taskTagsController.clear();

                      // Reset AM/PM selections
                      setState(() {
                        isStartPm = null;
                        isEndPm = null;
                        is24HourFormat = false;
                      });

                      Navigator.of(context).pop(); // Close dialog
                    }).catchError((error) {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add task: $error')),
                      );
                    });
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
class TimeInputWidget extends StatefulWidget {
  final String label;
  final void Function(TimeOfDay time) onTimeChanged;

  TimeInputWidget({required this.label, required this.onTimeChanged});

  @override
  _TimeInputWidgetState createState() => _TimeInputWidgetState();
}

class _TimeInputWidgetState extends State<TimeInputWidget> {
  TimeOfDay? _selectedTime;
  bool _isPM = false;

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      _updateTime();
    }
  }

  void _updateTime() {
    if (_selectedTime != null) {
      int hour = _selectedTime!.hour;
      int minute = _selectedTime!.minute;

      if (_isPM && hour < 12) hour += 12;
      if (!_isPM && hour == 12) hour = 0;

      widget.onTimeChanged(TimeOfDay(hour: hour, minute: minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => _selectTime(context),
            child: Text(
              _selectedTime != null
                  ? _selectedTime!.format(context)
                  : "Select ${widget.label} Time",
            ),
          ),
        ),
        Checkbox(
          value: _isPM,
          onChanged: (bool? value) {
            setState(() {
              _isPM = value ?? false;
            });
            _updateTime();
          },
        ),
        Text("PM"),
      ],
    );
  }
}

class TaskInputForm extends StatefulWidget {
  @override
  _TaskInputFormState createState() => _TaskInputFormState();
}

class _TaskInputFormState extends State<TaskInputForm> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  void saveToDatabase() {
    if (startTime != null && endTime != null) {
      FirebaseFirestore.instance.collection('tasks').add({
        'startTime': '${startTime!.hour}:${startTime!.minute}',
        'endTime': '${endTime!.hour}:${endTime!.minute}',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TimeInputWidget(
          label: 'Start',
          onTimeChanged: (time) {
            setState(() {
              startTime = time;
            });
          },
        ),
        TimeInputWidget(
          label: 'End',
          onTimeChanged: (time) {
            setState(() {
              endTime = time;
            });
          },
        ),
        ElevatedButton(
          onPressed: saveToDatabase,
          child: Text("Save Task"),
        ),
      ],
    );
  }
}

class TaskTrackerView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TaskInputForm(),
      ),
    );
  }
}
