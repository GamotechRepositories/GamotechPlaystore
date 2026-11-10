import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/onboarding_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final completedOnboarding = await const OnboardingService().isCompleted();
  runApp(MyApp(showOnboarding: !completedOnboarding));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.showOnboarding = false});

  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFFA78BFA),
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Gamotech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: const Color(0xFFF9F5FF),
          displayColor: const Color(0xFFF9F5FF),
        ),
        scaffoldBackgroundColor: const Color(0xFF190C30),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF382548),
          contentPadding: const EdgeInsets.all(18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF654778)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            foregroundColor: colors.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      home: showOnboarding ? const OnboardingScreen() : const LoginScreen(),
    );
  }
}
