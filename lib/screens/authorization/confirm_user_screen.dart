import 'package:flutter/material.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/screens/authorization/login_screen.dart';
import 'package:mifinper/widgets/custom_text_field.dart'; // Assuming login_screen is in the same directory

class ConfirmUserScreen extends StatefulWidget {
  final String email;
  const ConfirmUserScreen({super.key, required this.email});

  @override
  State<ConfirmUserScreen> createState() => _ConfirmUserScreenState();
}

class _ConfirmUserScreenState extends State<ConfirmUserScreen> {
  final TextEditingController _confirmationCodeController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _confirmUser() async {
    setState(() {
      _isLoading = true;
    });

    final String confirmationCode = _confirmationCodeController.text;

    final Map<String, dynamic> result = await _apiService.confirmUser(widget.email, confirmationCode);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User confirmed successfully!')),
      );
      // Navigate to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Confirmation failed: ${result['message']}')),
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
        title: const Text('Confirm User'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth > 600 ? 400 : constraints.maxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 150, // Ajusta el tamaño
                      height: 150,
                    ),
                    Text(
                        'Ingresa el código enviado a ${widget.email}'),
                    const SizedBox(height: 16.0),
                    CustomTextField(
                      controller: _confirmationCodeController,
                      label: 'Confirmar Código',
                      isPassword: false,
                      enabled: !_isLoading,
                      isRequired: true,
                    ),
                    const SizedBox(height: 32.0),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _confirmUser,
                            child: const Text('Confirmar'),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}