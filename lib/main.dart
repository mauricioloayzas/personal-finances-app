import 'package:flutter/material.dart';
import 'package:frontend/screens/credit_card_debts_screen.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/cash_screen.dart';
import 'package:frontend/screens/loan_debts_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finances',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 1. Definimos la ruta inicial
      initialRoute: '/login',

      // 2. Definimos todas las rutas (pantallas) disponibles
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/cash': (context) => const CashScreen(),
        '/credit-card-debts': (context) => const CreditCardDebtsScreen(),
        '/loan-debts': (context) => const LoanDebtsScreen(),
      },
    );
  }
}
