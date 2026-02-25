import 'package:flutter/material.dart';
import 'package:mifinper/screens/dashboard_screen.dart';
import 'package:mifinper/screens/authorization/login_screen.dart';
import 'package:mifinper/screens/authorization/register_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mifinper/screens/profile/create_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env.prod");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIFINPER',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
