import 'package:flutter/material.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/screens/authorization/confirm_user_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _register() async {
    setState(() {
      _isLoading = true;
    });

    final String name = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;

    final Map<String, dynamic> result =
        await _apiService.registerUser(name, email, password);
    print(result);
    if (result['success']) {
      // Navigate to confirmation screen or show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Great: ${result['data']['message']}')),
      );
      // Optionally navigate to confirm user screen, passing the email
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConfirmUserScreen(email: email),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${result['error']}')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 300, // Ajusta el tamaño
              height: 300,
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32.0),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}
