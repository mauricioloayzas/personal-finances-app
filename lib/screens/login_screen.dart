import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Importar dotenv
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 2. Importar secure storage

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 3. Crear instancia del storage
  final _storage = const FlutterSecureStorage();

  // 4. Construir la URL usando la variable de entorno
  final String _loginUrl = '${dotenv.env['API_ORCHESTRATOR_URL']}/auth/login';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final payload = {
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      final response = await http.post(
        Uri.parse(_loginUrl), // Usar la URL construida
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        // 5. Decodificar la respuesta
        final Map<String, dynamic> responseData = json.decode(response.body);

        final String? idToken = responseData['IdToken'];
        final String? sub = responseData['sub'];

        if (idToken != null && sub != null) {
          // 7. Guardar el token de forma segura
          await _storage.write(key: 'idToken', value: idToken);
          await _storage.write(key: 'sub', value: sub);

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          // El login fue exitoso (200) pero no vino el token
          if (mounted) {
            _showError('Respuesta inválida del servidor.');
          }
        }
      } else {
        // Error de credenciales (401, 403)
        if (mounted) {
          _showError('Email o contraseña incorrectos.');
        }
      }
    } catch (e) {
      // Error de red
      if (mounted) {
        _showError('Error de red: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Función helper para mostrar errores
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El resto del widget (UI) sigue exactamente igual que antes...
    // ... (El Scaffold, los TextFields, y los botones) ...
    // ... No es necesario copiarlo aquí de nuevo ...
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Iniciar Sesión',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Iniciar Sesión'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pushNamed(context, '/signup');
                      },
                child: const Text('¿No tienes cuenta? Crear una'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
