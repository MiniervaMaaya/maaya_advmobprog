import 'package:flutter/material.dart';

/// Notification model class
class NotificationModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    DateTime? createdAt,
    this.isRead = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a copy of this notification with some fields replaced
  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    Color? iconColor,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Mock notifications data
List<NotificationModel> getMockNotifications() {
  return [
    NotificationModel(
      id: '1',
      title: 'Time to Make Progress',
      description:
          'Your goals are waiting. Complete a task today and keep your momentum going',
      icon: Icons.timer,
      iconColor: const Color(0xFF00BCD4),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: '2',
      title: 'Start Strong',
      description:
          'A productive day starts with a plan. Check your schedule, prioritize, and tackle your top tasks',
      icon: Icons.bolt,
      iconColor: const Color(0xFFFF9800),
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    NotificationModel(
      id: '3',
      title: 'Don\'t Forget!',
      description:
          'You have pending tasks waiting. Every completed checklist brings you closer to your goals',
      icon: Icons.notifications_active,
      iconColor: const Color(0xFFF44336),
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];
}
