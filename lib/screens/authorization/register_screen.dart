import 'package:flutter/material.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/screens/authorization/confirm_user_screen.dart';
import 'package:mifinper/widgets/custom_dropdown_selector.dart';
import 'package:mifinper/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String? _selectedCountryId;
  String? _selectedTimeZoneId;
  String? _selectedLanguageId;

  List<dynamic> _countries = [];
  List<dynamic> _timeZones = [];
  List<dynamic> _languages = [];

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isFetchingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _apiService.fetchCountries(),
        _apiService.fetchTimezones(),
        _apiService.fetchLanguages(),
      ]);

      setState(() {
        _countries = results[0];
        _timeZones = results[1];
        _languages = results[2];
        _isFetchingData = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos iniciales: $e')),
      );
      setState(() {
        _isFetchingData = false;
      });
    }
  }

  void _register() async {
    if (_selectedCountryId == null ||
        _selectedTimeZoneId == null ||
        _selectedLanguageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String name = _nameController.text;
    final String email = _emailController.text;
    final String password = _passwordController.text;
    final String countryId = _selectedCountryId!;
    final String timeZoneId = _selectedTimeZoneId!;
    final String languageId = _selectedLanguageId!;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> result = await _apiService.registerUser(
      name: name,
      email: email,
      password: password,
      countryId: countryId,
      timeZoneId: timeZoneId,
      languageId: languageId,
    );
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
        SnackBar(content: Text('Registration failed: ${result['error'] ?? result['message']}')),
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
      body: _isFetchingData
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 600 ? 400 : constraints.maxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 150, // Ajusta el tamaño
                              height: 150,
                            ),
                            CustomTextField(
                              controller: _nameController,
                              label: 'Nombre',
                              isPassword: false,
                              enabled: !_isLoading,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              isPassword: false,
                              enabled: !_isLoading,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16.0),
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              isPassword: true,
                              enabled: !_isLoading,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16.0),
                            CustomDropdownSelector(
                              label: 'País *',
                              items: _countries,
                              selectedId: _selectedCountryId,
                              enabled: !_isLoading,
                              onChanged: (value) => setState(() => _selectedCountryId = value),
                            ),
                            const SizedBox(height: 16.0),
                            CustomDropdownSelector(
                              label: 'Zona Horaria *',
                              items: _timeZones,
                              selectedId: _selectedTimeZoneId,
                              enabled: !_isLoading,
                              onChanged: (value) => setState(() => _selectedTimeZoneId = value),
                            ),
                            const SizedBox(height: 16.0),
                            CustomDropdownSelector(
                              label: 'Idioma *',
                              items: _languages,
                              selectedId: _selectedLanguageId,
                              enabled: !_isLoading,
                              onChanged: (value) => setState(() => _selectedLanguageId = value),
                            ),
                            const SizedBox(height: 32.0),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text('Registrar'),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
