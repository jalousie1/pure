// Importações necessárias para o funcionamento do app
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

// Imports
import 'pages/start_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/chatbot_page.dart';
import 'pages/after_register.dart';
import 'pages/profile_page.dart';
import 'pages/medicines_page.dart';
import 'pages/meals_page.dart';
import 'pages/workouts_page.dart';
import 'pages/sleep_page.dart';
import 'firebase_options.dart';
import 'pages/terms_page.dart';

// Função principal que inicia o aplicativo
Future<void> main() async {
  // Inicializa o Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Carrega as variáveis de ambiente
  await dotenv.load(fileName: ".env");
  // Inicia o app
  runApp(const MainApp());
}

// Classe principal do aplicativo
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PureLife',
      // Configuração do tema claro
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8A2C8), // Cor lilás principal
          brightness: Brightness.light,
          surface: const Color(0xFFFAFAFA),
          surfaceTint: const Color(0xFFFAFAFA),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Set scaffold background
        useMaterial3: true,
      ),
      // Configuração do tema escuro
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8A2C8), // Lilac color
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Usa o tema do sistema
      debugShowCheckedModeBanner: false, // Remove a faixa de debug
      initialRoute: '/', // Rota inicial do app
      // Definição de todas as rotas (páginas) do aplicativo
      routes: {
        '/': (context) => const StartPageWidget(),      // Página inicial
        '/login': (context) => const LoginPage(),       // Página de login
        '/register': (context) => const RegisterPage(), // Página de registro
        '/after_register': (context) => const AfterRegisterWidget(), // Página pós-registro
        '/home': (context) => const HomePageWidget(),   // Página principal
        '/chatbot': (context) => const ChatBotPageWidget(), // Página do chatbot
        '/profile': (context) => const ProfilePage(),   // Página de perfil
        '/medicines': (context) => const MedicinesPage(), // Página de medicamentos
        '/meals': (context) => const MealsPage(),       // Página de refeições
        '/workouts': (context) => const WorkoutsPage(), // Página de exercícios
        '/sleep': (context) => const SleepPage(),       // Página de sono
        '/terms': (context) => const TermsPage(),       // Página de termos
      },
      // Página mostrada quando uma rota não é encontrada
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(child: Text('Route not found')),
        ),
      ),
    );
  }
}
