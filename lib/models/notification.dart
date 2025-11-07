// lib/models/notification.dart
class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String type; // LOST_ALERT, LOCATION, REMINDER, INFO
  final DateTime createdAt;
  final String urgencyLevel; // HIGH (Urgente) o MEDIUM

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.type,
    required this.createdAt,
    required this.urgencyLevel,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['read'] as bool, // Coincide con 'read' en NotificationDTO
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      urgencyLevel: json['urgencyLevel'] as String,
    );
  }
}