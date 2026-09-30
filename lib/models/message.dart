import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, delivered, seen }

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime sentAt;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.sentAt,
    required this.status,
  });

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    final rawDate = data['sentAt'];
    final sentAt = switch (rawDate) {
      Timestamp value => value.toDate(),
      DateTime value => value,
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };
    return ChatMessage(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      sentAt: sentAt,
      status: MessageStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => MessageStatus.delivered,
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'sentAt': Timestamp.fromDate(sentAt),
    'status': status.name,
  };
}
