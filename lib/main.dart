import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/start_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/chatbot_page.dart';
import 'pages/after_register.dart';
import 'pages/profile_page.dart';  // Add this import
import 'pages/medicines_page.dart';
import 'pages/meals_page.dart';
import 'pages/workouts_page.dart';
import 'pages/sleep_page.dart';
import 'firebase_options.dart';
import 'pages/terms_page.dart';  // Add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PureLife',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8A2C8), // Lilac color
          brightness: Brightness.light,
          surface: const Color(0xFFFAFAFA),
          surfaceTint: const Color(0xFFFAFAFA),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Set scaffold background
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8A2C8), // Lilac color
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const StartPageWidget(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/after_register': (context) => const AfterRegisterWidget(),
        '/home': (context) => const HomePageWidget(),
        '/chatbot': (context) => const ChatBotPageWidget(),
        '/profile': (context) => const ProfilePage(),
        '/medicines': (context) => const MedicinesPage(),
        '/meals': (context) => const MealsPage(),
        '/workouts': (context) => const WorkoutsPage(),
        '/sleep': (context) => const SleepPage(),
        '/terms': (context) => const TermsPage(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(child: Text('Route not found')),
        ),
      ),
    );
  }
}
