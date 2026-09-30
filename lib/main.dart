import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/signup_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'services/storage_service.dart';
import 'services/user_service.dart';
import 'services/cart_service.dart';
import 'services/chat_service.dart';
import 'services/product_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  firebase_auth.FirebaseAuth? firebaseAuth;
  FirebaseFirestore? firestore;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseAuth = firebase_auth.FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
  } on FirebaseException catch (error) {
    debugPrint('Firebase initialization failed: ${error.message}');
  } on UnsupportedError catch (error) {
    debugPrint('Firebase is unavailable on this platform: $error');
  }

  final storageService = StorageService();
  final userService = UserService(
    firebaseAuth: firebaseAuth,
    firestore: firestore,
  );
  final cartService = CartService();
  final chatService = ChatService(firestore: firestore);
  final productService = ProductService();
  await storageService.init();
  await userService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<UserService>.value(value: userService),
        ChangeNotifierProvider<CartService>.value(value: cartService),
        Provider<ChatService>.value(value: chatService),
        Provider<ProductService>.value(value: productService),
        ChangeNotifierProvider(create: (_) => TaskProvider(storageService)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    return MaterialApp(
      title: 'NUBD Exchange',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.sampleBlue),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: AppColors.sampleCanvas,
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: AppColors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.sampleBlue,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF121318),
        cardColor: const Color(0xFF1D1E24),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF1D1E24),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const SignInScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
