import 'package:flutter/material.dart';
import 'package:mifinper/screens/dashboard_screen.dart';
import 'package:mifinper/screens/authorization/login_screen.dart';
import 'package:mifinper/screens/authorization/register_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mifinper/screens/profile/create_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env.dev");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIFINPER', 
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF7A5C00,
          <int, Color>{
            50: Color(0xFFFFF8E1),
            100: Color(0xFFFFECB3),
            200: Color(0xFFFFE082),
            300: Color(0xFFFFD54F),
            400: Color(0xFFFFCA28),
            500: Color(0xFFFFD700),
            600: Color(0xFFFFB300),
            700: Color(0xFFA07F00),
            800: Color(0xFF8C6D00),
            900: Color(0xFF7A5C00),
          },
        ),
        scaffoldBackgroundColor: const Color(0xFF282828),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFFFECB3)),
          displayLarge: TextStyle(
            color: Color(0xFFFFECB3),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            color: Color(0xFFFFECB3),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        )
      ),
      // 1. Definimos la ruta inicial
      initialRoute: '/login',

      // 2. Definimos todas las rutas (pantallas) disponibles
      routes: {
        '/login': (context)           => const LoginScreen(),
        '/signup': (context)          => const RegisterScreen(),
        '/dashboard': (context)       => const DashboardScreen(),
        '/create-profile': (context)  => const CreateProfileScreen()
      },
    );
  }
}
