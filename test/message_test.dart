import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maaya_advmobile/models/message.dart';

void main() {
  test('message parses Firestore data and preserves delivery status', () {
    final sentAt = DateTime.utc(2026, 9, 30, 8, 15);
    final message = ChatMessage.fromFirestore('message-1', {
      'senderId': 'sender',
      'receiverId': 'receiver',
      'text': 'Hello',
      'sentAt': Timestamp.fromDate(sentAt),
      'status': 'seen',
    });

    expect(message.id, 'message-1');
    expect(message.text, 'Hello');
    expect(message.sentAt.millisecondsSinceEpoch, sentAt.millisecondsSinceEpoch);
    expect(message.status, MessageStatus.seen);
    expect(message.toFirestore()['status'], 'seen');
  });

  test('unknown message status safely defaults to delivered', () {
    final message = ChatMessage.fromFirestore('message-2', {
      'senderId': 'sender',
      'receiverId': 'receiver',
      'text': 'Hello',
      'status': 'unexpected',
    });

    expect(message.status, MessageStatus.delivered);
  });
}
