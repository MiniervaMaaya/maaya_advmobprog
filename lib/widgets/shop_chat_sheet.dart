import 'package:flutter/material.dart';

import '../utils/constants.dart';

class ShopChatSheet extends StatefulWidget {
  const ShopChatSheet({super.key});

  @override
  State<ShopChatSheet> createState() => _ShopChatSheetState();
}

class _ShopChatSheetState extends State<ShopChatSheet> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Hi! I can help with products, your cart, shipping, and returns.',
      isBot: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: message, isBot: false));
      _messages.add(_ChatMessage(text: _replyFor(message), isBot: true));
      _messageController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _replyFor(String message) {
    final query = message.toLowerCase();
    if (query.contains('cart') || query.contains('quantity')) {
      return 'Open the cart tab to change item quantities or remove products.';
    }
    if (query.contains('ship') || query.contains('delivery')) {
      return 'Delivery details are provided by the shop. Check the product page for availability before ordering.';
    }
    if (query.contains('return') || query.contains('refund')) {
      return 'For return or refund help, contact the shop with your order details.';
    }
    if (query.contains('product') ||
        query.contains('find') ||
        query.contains('search')) {
      return 'Use the search field or category filters on the Shop page to find products.';
    }
    return 'I can help with products, cart quantities, shipping, and returns. What would you like to know?';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.68,
        decoration: const BoxDecoration(
          color: AppColors.sampleCanvas,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.lg),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.sampleBlue,
                    child: Icon(
                      Icons.support_agent,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Shop assistant',
                      style: AppTextStyles.heading3,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close chat',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isBot
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 290),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: message.isBot
                            ? AppColors.white
                            : AppColors.sampleBlue,
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isBot
                              ? AppColors.black87
                              : AppColors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ask the shop assistant',
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.md,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton.filled(
                      tooltip: 'Send message',
                      onPressed: _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.sampleBlue,
                        foregroundColor: AppColors.white,
                      ),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isBot;

  const _ChatMessage({required this.text, required this.isBot});
}
