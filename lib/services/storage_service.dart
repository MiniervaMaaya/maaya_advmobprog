import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

/// Service for handling local storage operations
class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  late SharedPreferences _prefs;

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save a list of tasks
  Future<bool> saveTasks(List<Task> tasks) async {
    try {
      final taskJsonList = tasks.map((task) => task.toJsonString()).toList();
      return await _prefs.setStringList(_tasksKey, taskJsonList);
    } catch (e) {
      print('Error saving tasks: $e');
      return false;
    }
  }

  /// Get all saved tasks
  List<Task> getTasks() {
    try {
      final taskJsonList = _prefs.getStringList(_tasksKey) ?? [];
      return taskJsonList.map((taskJson) => Task.fromJsonString(taskJson)).toList();
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  /// Add a single task
  Future<bool> addTask(Task task) async {
    try {
      final tasks = getTasks();
      tasks.add(task);
      return await saveTasks(tasks);
    } catch (e) {
      print('Error adding task: $e');
      return false;
    }
  }

  /// Update a task
  Future<bool> updateTask(Task updatedTask) async {
    try {
      final tasks = getTasks();
      final index = tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        tasks[index] = updatedTask;
        return await saveTasks(tasks);
      }
      return false;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  /// Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      final tasks = getTasks();
      tasks.removeWhere((task) => task.id == taskId);
      return await saveTasks(tasks);
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  /// Clear all tasks
  Future<bool> clearTasks() async {
    try {
      return await _prefs.remove(_tasksKey);
    } catch (e) {
      print('Error clearing tasks: $e');
      return false;
    }
  }

  /// Set login state
  Future<bool> setLoginState(bool isLoggedIn) async {
    try {
      return await _prefs.setBool(_isLoggedInKey, isLoggedIn);
    } catch (e) {
      print('Error setting login state: $e');
      return false;
    }
  }

  /// Get login state
  bool getLoginState() {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Save user data
  Future<bool> saveUserData(String email, String userName) async {
    try {
      await _prefs.setString('user_email', email);
      await _prefs.setString('user_name', userName);
      return await _prefs.setBool(_isLoggedInKey, true);
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  /// Get user email
  String? getUserEmail() {
    return _prefs.getString('user_email');
  }

  /// Get user name
  String? getUserName() {
    return _prefs.getString('user_name');
  }

  /// Logout - clear user data
  Future<bool> logout() async {
    try {
      await _prefs.remove('user_email');
      await _prefs.remove('user_name');
      return await _prefs.setBool(_isLoggedInKey, false);
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }
}
