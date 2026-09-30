import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  // Enhancement 1: route returning users from the persisted authentication state.
  Future<void> _restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final userService = context.read<UserService>();
    Navigator.of(context).pushReplacementNamed(
      userService.isAuthenticated ? '/dashboard' : '/signin',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: AppColors.sampleCanvas,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/nuicon.jpeg',
                width: 156,
                height: 156,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.storefront,
                  color: AppColors.sampleBlue,
                  size: 88,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'NUBD Exchange',
                style: TextStyle(
                  color: AppColors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.sampleBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
