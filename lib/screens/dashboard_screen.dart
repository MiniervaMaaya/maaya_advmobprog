import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import 'cart_screen.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  ChatService? _chatService;
  String? _presenceUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chatService = context.read<ChatService>();
    _presenceUid = context.read<UserService>().currentUser?.authUid;
    _updatePresence(true);
  }

  Future<void> _updatePresence(bool isOnline) async {
    final service = _chatService;
    final uid = _presenceUid;
    if (service == null || uid == null || !service.isAvailable) return;
    try {
      await service.setPresence(uid, isOnline: isOnline);
    } catch (_) {
      // Presence is best-effort and must not interrupt the rest of the app.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_updatePresence(true));
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_updatePresence(false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_updatePresence(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserService>().currentUser?.id;
    final screens = [
      const HomeScreen(),
      const ChatScreen(),
      userId == null
          ? const Center(child: Text('Sign in to view your cart.'))
          : CartScreen(key: ValueKey('cart-$userId'), userId: userId),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: AppColors.sampleBlue,
        unselectedItemColor: AppColors.grey54,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Shop',
            tooltip: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Chat',
            tooltip: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
            tooltip: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
            tooltip: 'Account',
          ),
        ],
      ),
    );
  }
}
