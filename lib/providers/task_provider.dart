import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

/// Provider class for managing tasks
class TaskProvider extends ChangeNotifier {
  final StorageService _storageService;
  List<Task> _tasks = [];

  TaskProvider(this._storageService) {
    _loadTasks();
  }

  /// Get all tasks
  List<Task> get tasks => _tasks;

  /// Get completed tasks count
  int get completedCount => _tasks.where((task) => task.isCompleted).length;

  /// Get pending tasks count
  int get pendingCount => _tasks.where((task) => !task.isCompleted).length;

  /// Load tasks from storage
  Future<void> _loadTasks() async {
    _tasks = _storageService.getTasks();
    notifyListeners();
  }

  /// Add a new task
  Future<void> addTask(String title, {String description = ''}) async {
    const uuid = Uuid();
    final newTask = Task(
      id: uuid.v4(),
      title: title,
      description: description,
      isCompleted: false,
    );
    _tasks.add(newTask);
    await _storageService.addTask(newTask);
    notifyListeners();
  }

  /// Update task (toggle completion)
  Future<void> toggleTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isCompleted: !_tasks[index].isCompleted);
      await _storageService.updateTask(_tasks[index]);
      notifyListeners();
    }
  }

  /// Update task details
  Future<void> updateTask(String taskId, String title,
      {String description = '', DateTime? dueDate}) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        title: title,
        description: description,
        dueDate: dueDate,
      );
      await _storageService.updateTask(_tasks[index]);
      notifyListeners();
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((task) => task.id == taskId);
    await _storageService.deleteTask(taskId);
    notifyListeners();
  }

  /// Clear all tasks
  Future<void> clearAllTasks() async {
    _tasks.clear();
    await _storageService.clearTasks();
    notifyListeners();
  }

  /// Get today's tasks
  List<Task> getTodaysTasks() {
    final today = DateTime.now();
    return _tasks.where((task) {
      final createdDate = task.createdAt;
      return createdDate.year == today.year &&
          createdDate.month == today.month &&
          createdDate.day == today.day;
    }).toList();
  }
}
