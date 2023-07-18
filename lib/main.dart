import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent, // Make app bar transparent in dark mode
        ),
        textTheme: TextTheme(
          // Define a custom text style with black color for tasks
          bodyLarge: TextStyle(color: Colors.black),
        ),
        primaryColor: Colors.deepPurple, // Use deepPurple as the primary color
      ),
      home: TodoList(),
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({Key? key}) : super(key: key);

  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  List<TaskData> tasks = [];
  final _prefsKey = 'tasks_key';

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  void loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tasks = (prefs.getStringList(_prefsKey) ?? []).map((taskJson) => TaskData.fromJson(taskJson)).toList();
    });
  }

  void saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_prefsKey, tasks.map((task) => task.toJson()).toList());
  }

  void addTask(String task, bool isImportant) {
    setState(() {
      tasks.add(TaskData(task: task, isImportant: isImportant));
      saveTasks(); // Save tasks to local storage
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task added: $task')),
    );
  }

  void removeTask(int index) {
    setState(() {
      tasks.removeAt(index);
      saveTasks(); // Save tasks to local storage
    });
  }

  void toggleTaskCompletion(int index) {
    setState(() {
      tasks[index].isImportant = !tasks[index].isImportant;
      saveTasks(); // Save tasks to local storage
    });
  }

  void clearAllTasks() {
    setState(() {
      tasks.clear();
      saveTasks(); // Save tasks to local storage
    });
  }

  Future<void> _navigateToAddTaskPage() async {
    final newTaskData = await Navigator.push<TaskData>(
      context,
      MaterialPageRoute(builder: (context) => AddTaskPage()),
    );

    if (newTaskData != null && newTaskData.task.isNotEmpty) {
      addTask(newTaskData.task, newTaskData.isImportant);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo App'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final taskData = tasks[index];
          final task = taskData.task;
          final isImportant = taskData.isImportant;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.8),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                leading: SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    'assets/icons/todo_icon.svg', // Replace with your custom SVG icon asset
                    color: isImportant ? Colors.deepOrange : Colors.black54, // Use black54 for non-important tasks
                  ),
                ),
                title: Text(
                  task,
                  style: TextStyle(
                    decoration: task.startsWith('✓ ') ? TextDecoration.lineThrough : null,
                    color: isImportant ? Colors.black : Colors.black54, // Use black54 for non-important tasks
                  ),
                ),
                trailing: ColorFiltered(
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  child: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => removeTask(index),
                  ),
                ),
                onTap: () => toggleTaskCompletion(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTaskPage, // Navigate to AddTaskPage
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({Key? key}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  String task = '';
  bool isImportant = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  task = value;
                });
              },
              decoration: InputDecoration(hintText: 'Enter task...'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Important'),
                Checkbox(
                  value: isImportant,
                  onChanged: (value) {
                    setState(() {
                      isImportant = value ?? false;
                    });
                  },
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Set the background color of the button to white
              ),
              onPressed: () {
                if (task.isNotEmpty) {
                  // If the user entered a task, pass it back to the previous screen and pop this screen
                  Navigator.of(context).pop(TaskData(task: task, isImportant: isImportant));
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskData {
  String task;
  bool isImportant;

  TaskData({
    required this.task,
    this.isImportant = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'task': task,
      'isImportant': isImportant,
    };
  }

  factory TaskData.fromMap(Map<String, dynamic> map) {
    return TaskData(
      task: map['task'],
      isImportant: map['isImportant'],
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskData.fromJson(String source) => TaskData.fromMap(json.decode(source));
}
