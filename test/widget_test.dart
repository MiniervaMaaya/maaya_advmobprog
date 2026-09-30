import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maaya_advmobile/main.dart';
import 'package:maaya_advmobile/providers/theme_provider.dart';
import 'package:maaya_advmobile/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash routes unauthenticated users to sign in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final userService = UserService();
    await userService.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserService>.value(value: userService),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Demo API'), findsNothing);
    expect(find.text('Firebase'), findsNothing);
    expect(find.text('Email address'), findsOneWidget);
    userService.dispose();
  });
}
