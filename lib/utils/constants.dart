import 'package:flutter/material.dart';

/// App color constants
class AppColors {
  static const Color primary = Color(0xFF59A9AE);
  static const Color primaryLight = Color(0xFFEAF8F8);
  static const Color white = Colors.white;
  static const Color black87 = Color(0xFF212121);
  static const Color grey54 = Color(0xFF9E9E9E);
  static const Color orange = Color(0xFFFF9800);
  static const Color red = Color(0xFFF44336);
  static const Color cyan = Color(0xFF00BCD4);

  static const Color cyan200 = Color(0xFF4DD0E1);
  static const Color cyan100 = Color(0xFFB2EBF2);

  static const Color brandBlue = Color(0xFF174A96);
  static const Color brandGold = Color(0xFFE5A900);
  static const Color sampleBlue = Color(0xFF394A91);
  static const Color sampleCanvas = Color(0xFFFAF7FC);
  static const Color sampleCoral = Color(0xFFFF6258);

  static const Color tealButton = Color(0xFF4A7C8C);
}

/// App spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// App border radius constants
class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double circle = 60.0;
}

/// App text style constants
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.grey54,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.grey54,
  );
}

/// Validation messages
class ValidationMessages {
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordMinLength =
      'Password must be at least 6 characters';
  static const String taskTitleRequired = 'Task title is required';
}
