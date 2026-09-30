import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import 'signin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final user = context.watch<UserService>().currentUser;
    final isFirebaseAccount = user?.loginType == LoginType.firebase;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            value: themeProvider.isDarkMode,
            onChanged: themeProvider.setDarkMode,
            secondary: Icon(
              themeProvider.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode_outlined,
            ),
            title: Text(themeProvider.isDarkMode ? 'Dark mode' : 'Light mode'),
            subtitle: Text(
              themeProvider.isDarkMode
                  ? 'Dark appearance is active'
                  : 'Light appearance is active',
            ),
            activeTrackColor: AppColors.sampleBlue,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Update username'),
            subtitle: Text(user?.username ?? ''),
            onTap: user == null
                ? null
                : () => showUpdateUsername(context, user),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change password'),
            subtitle: Text(
              isFirebaseAccount
                  ? 'Confirm your current password first'
                  : 'Available for Firebase accounts',
            ),
            enabled: isFirebaseAccount,
            onTap: isFirebaseAccount ? () => showChangePassword(context) : null,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.red),
            title: const Text('Delete account'),
            subtitle: const Text('Permanently delete your Firebase account'),
            enabled: isFirebaseAccount,
            onTap: isFirebaseAccount ? () => _deleteAccount(context) : null,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.sampleCoral),
            title: const Text('Log out'),
            onTap: () => _logOut(context),
          ),
        ],
      ),
    );
  }

  static Future<void> showUpdateUsername(
    BuildContext context,
    User user,
  ) async {
    var editedUsername = user.username;
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update username'),
        content: TextFormField(
          initialValue: user.username,
          autofocus: true,
          onChanged: (value) => editedUsername = value,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, editedUsername.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (username == null || username.length < 3) return;
    if (!context.mounted) return;
    final userService = context.read<UserService>();
    final messenger = ScaffoldMessenger.of(context);
    await _perform(() async {
      await userService.updateUsername(username);
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Username updated')),
        );
      }
    }, messenger);
  }

  static Future<void> showChangePassword(BuildContext context) async {
    var currentPassword = '';
    var newPassword = '';
    final passwords = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              obscureText: true,
              onChanged: (value) => currentPassword = value,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            TextFormField(
              obscureText: true,
              onChanged: (value) => newPassword = value,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, [currentPassword, newPassword]),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (passwords == null ||
        passwords.first.isEmpty ||
        passwords.last.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter your current password and a new password of at least 6 characters.',
          ),
        ),
      );
      return;
    }
    final userService = context.read<UserService>();
    final messenger = ScaffoldMessenger.of(context);
    await _perform(() async {
      await userService.resetPasswordFromCurrentPassword(
        currentPassword: passwords.first,
        newPassword: passwords.last,
      );
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Password changed')),
        );
      }
    }, messenger);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    var currentPassword = '';
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: TextFormField(
          obscureText: true,
          onChanged: (value) => currentPassword = value,
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, currentPassword),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (password == null) return;
    if (!context.mounted) return;
    final userService = context.read<UserService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _perform(() async {
      await userService.deleteAccount(currentPassword: password);
      if (navigator.mounted) _goToSignIn(navigator);
    }, messenger);
  }

  Future<void> _logOut(BuildContext context) async {
    final userService = context.read<UserService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _perform(() async {
      await userService.signOut();
      if (navigator.mounted) _goToSignIn(navigator);
    }, messenger);
  }

  static Future<void> _perform(
    Future<void> Function() action,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      await action();
    } catch (error) {
      if (messenger.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  void _goToSignIn(NavigatorState navigator) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }
}
