import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import 'cart_screen.dart';
import 'settings_screen.dart';
import 'signin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = context.read<UserService>().getUserData();
  }

  Future<void> _signOut(BuildContext context) async {
    await context.read<UserService>().signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedInUser = context.watch<UserService>().currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.sampleBlue,
        foregroundColor: AppColors.white,
        title: Text(
          signedInUser?.firstName.isNotEmpty == true
              ? signedInUser!.firstName
              : 'Profile',
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Profile options',
            onSelected: (value) {
              if (value == 'cart') {
                final user = context.read<UserService>().currentUser;
                if (user != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CartScreen(userId: user.id),
                    ),
                  );
                }
              } else if (value == 'settings') {
                _openSettings(context);
              } else if (value == 'signout') {
                _signOut(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'cart', child: Text('My cart')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
              PopupMenuItem(value: 'signout', child: Text('Sign out')),
            ],
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = signedInUser ?? snapshot.data;
          if (user == null) {
            return const Center(child: Text('No signed-in user'));
          }
          return _buildProfile(context, user);
        },
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await Navigator.of(context).pushNamed('/settings');
    if (mounted) {
      setState(() {
        _userFuture = context.read<UserService>().getUserData();
      });
    }
  }

  Widget _buildProfile(BuildContext context, User user) {
    // Enhancement 3: render saved user details and use the same user's ID for their cart.
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                backgroundImage: user.image.isEmpty
                    ? null
                    : NetworkImage(user.image),
                child: user.image.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 38,
                        color: AppColors.sampleBlue,
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(user.displayName, style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '@${user.username}',
                style: const TextStyle(
                  color: AppColors.brandGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: Column(
            children: [
              _ProfileDetail(
                icon: Icons.mail_outline,
                label: 'Email',
                value: user.email,
              ),
              const Divider(height: 1, color: AppColors.primaryLight),
              _ProfileDetail(
                icon: Icons.people_outline,
                label: 'Gender',
                value: user.gender.isEmpty ? 'Not provided' : user.gender,
              ),
              const Divider(height: 1, color: AppColors.primaryLight),
              _ProfileDetail(
                icon: Icons.cake_outlined,
                label: 'Age',
                value: user.age?.toString() ?? 'Not provided',
              ),
              const Divider(height: 1, color: AppColors.primaryLight),
              _ProfileDetail(
                icon: Icons.phone_outlined,
                label: 'Contact',
                value: user.contactNo.isEmpty ? 'Not provided' : user.contactNo,
              ),
              const Divider(height: 1, color: AppColors.primaryLight),
              _ProfileDetail(
                icon: Icons.badge_outlined,
                label: 'User ID',
                value: '#${user.id}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.sampleBlue,
                ),
                title: const Text('Edit username'),
                subtitle: Text('@${user.username}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => SettingsScreen.showUpdateUsername(context, user),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.lock_outline,
                  color: AppColors.sampleBlue,
                ),
                title: const Text('Change password'),
                subtitle: Text(
                  user.loginType == LoginType.firebase
                      ? 'Update your Firebase password'
                      : 'Available for Firebase accounts',
                ),
                trailing: const Icon(Icons.chevron_right),
                enabled: user.loginType == LoginType.firebase,
                onTap: user.loginType == LoginType.firebase
                    ? () => SettingsScreen.showChangePassword(context)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () => _signOut(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sampleCoral,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log Out'),
          ),
        ),
      ],
    );
  }
}

class _ProfileDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.brandGold),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 72,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
