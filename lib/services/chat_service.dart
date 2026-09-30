import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';
import '../models/user.dart';

class ChatService {
  final FirebaseFirestore? _firestore;

  ChatService({FirebaseFirestore? firestore}) : this._(firestore);

  ChatService._(this._firestore);

  bool get isAvailable => _firestore != null;

  Future<void> setPresence(String uid, {required bool isOnline}) async {
    await _requireFirestore().collection('users').doc(uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<User>> watchUsers(String currentUid) {
    final firestore = _requireFirestore();
    return firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .where((document) => document.id != currentUid)
          .map((document) {
            final data = document.data();
            return User.fromJson({
              ...data,
              'authUid': data['authUid'] ?? document.id,
            });
          })
          .toList();
      users.sort(
        (first, second) => first.displayName.toLowerCase().compareTo(
          second.displayName.toLowerCase(),
        ),
      );
      return users;
    });
  }

  Stream<List<ChatMessage>> watchMessages(String firstUid, String secondUid) {
    final firestore = _requireFirestore();
    return firestore
        .collection('conversations')
        .doc(conversationId(firstUid, secondUid))
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) =>
                    ChatMessage.fromFirestore(document.id, document.data()),
              )
              .toList(),
        );
  }

  Future<void> ensureConversation({
    required String firstUid,
    required String secondUid,
  }) async {
    final participants = [firstUid, secondUid]..sort();
    await _requireFirestore()
        .collection('conversations')
        .doc(conversationId(firstUid, secondUid))
        .set({'participants': participants}, SetOptions(merge: true));
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final firestore = _requireFirestore();
    final conversation = firestore
        .collection('conversations')
        .doc(conversationId(senderId, receiverId));
    final message = conversation.collection('messages').doc();
    final batch = firestore.batch();
    batch.set(conversation, {
      'participants': [senderId, receiverId],
      'lastMessage': trimmedText,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(message, {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': trimmedText,
      'sentAt': FieldValue.serverTimestamp(),
      'status': MessageStatus.delivered.name,
    });
    await batch.commit();
  }

  Future<void> markMessagesSeen({
    required String currentUid,
    required String otherUid,
    required List<ChatMessage> messages,
  }) async {
    final unread = messages
        .where(
          (message) =>
              message.receiverId == currentUid &&
              message.status != MessageStatus.seen,
        )
        .toList();
    if (unread.isEmpty) return;

    final firestore = _requireFirestore();
    final messagesCollection = firestore
        .collection('conversations')
        .doc(conversationId(currentUid, otherUid))
        .collection('messages');
    final batch = firestore.batch();
    for (final message in unread) {
      batch.update(messagesCollection.doc(message.id), {
        'status': MessageStatus.seen.name,
      });
    }
    await batch.commit();
  }

  String conversationId(String firstUid, String secondUid) {
    final participants = [firstUid, secondUid]..sort();
    return participants.join('_');
  }

  FirebaseFirestore _requireFirestore() {
    final firestore = _firestore;
    if (firestore == null) {
      throw const ChatServiceException('Chat is unavailable without Firebase.');
    }
    return firestore;
  }
}

class ChatServiceException implements Exception {
  final String message;

  const ChatServiceException(this.message);

  @override
  String toString() => message;
}
