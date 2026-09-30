import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';

class ChatDetailScreen extends StatefulWidget {
  final User currentUser;
  final User recipient;

  const ChatDetailScreen({
    super.key,
    required this.currentUser,
    required this.recipient,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  String _pendingText = '';
  int _lastMessageCount = 0;
  late final Future<void> _conversationReady;

  String get _currentUid => widget.currentUser.authUid!;
  String get _recipientUid => widget.recipient.authUid!;

  @override
  void initState() {
    super.initState();
    _conversationReady = context.read<ChatService>().ensureConversation(
      firstUid: _currentUid,
      secondUid: _recipientUid,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    _messageController.clear();
    setState(() {
      _isSending = true;
      _pendingText = text;
    });
    try {
      await context.read<ChatService>().sendMessage(
        senderId: _currentUid,
        receiverId: _recipientUid,
        text: text,
      );
    } catch (error) {
      if (mounted) {
        _messageController.text = text;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _pendingText = '';
        });
      }
    }
  }

  void _afterMessagesBuilt(List<ChatMessage> messages) {
    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      });
    }
    unawaited(
      context.read<ChatService>().markMessagesSeen(
        currentUid: _currentUid,
        otherUid: _recipientUid,
        messages: messages,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.sampleBlue,
        foregroundColor: AppColors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.surface,
              backgroundImage: widget.recipient.image.isEmpty
                  ? null
                  : NetworkImage(widget.recipient.image),
              child: widget.recipient.image.isEmpty
                  ? Text(
                      widget.recipient.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.sampleBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipient.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.recipient.isOnline ? 'Online' : 'Offline',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _conversationReady,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return StreamBuilder<List<ChatMessage>>(
                  stream: chatService.watchMessages(_currentUid, _recipientUid),
                  builder: (context, messageSnapshot) {
                    if (messageSnapshot.hasError) {
                      return Center(
                        child: Text(messageSnapshot.error.toString()),
                      );
                    }
                    if (!messageSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = messageSnapshot.data!;
                    _afterMessagesBuilt(messages);
                    if (messages.isEmpty && !_isSending) {
                      return const Center(
                        child: Text('Start the conversation.'),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return _SendingBubble(text: _pendingText);
                        }
                        final message = messages[index];
                        return _AnimatedMessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isMine: message.senderId == _currentUid,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          _MessageComposer(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _AnimatedMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset((isMine ? 18 : -18) * (1 - value), 0),
          child: child,
        ),
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isMine
                ? AppColors.sampleBlue
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppBorderRadius.lg),
              topRight: const Radius.circular(AppBorderRadius.lg),
              bottomLeft: Radius.circular(
                isMine ? AppBorderRadius.lg : AppSpacing.xs,
              ),
              bottomRight: Radius.circular(
                isMine ? AppSpacing.xs : AppBorderRadius.lg,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMine
                        ? AppColors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(message.sentAt),
                    style: TextStyle(
                      color: isMine ? Colors.white70 : AppColors.grey54,
                      fontSize: 10,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      message.status == MessageStatus.seen
                          ? Icons.done_all
                          : Icons.done,
                      size: 14,
                      color: message.status == MessageStatus.seen
                          ? AppColors.cyan100
                          : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendingBubble extends StatelessWidget {
  final String text;

  const _SendingBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text('$text  •  sending…', style: AppTextStyles.bodySmall),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isSending,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              tooltip: 'Send message',
              onPressed: isSending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.sampleBlue,
                foregroundColor: AppColors.white,
              ),
              icon: isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
