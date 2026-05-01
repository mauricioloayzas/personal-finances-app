import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/widgets/custom_dropdown_selector.dart';
import 'package:mifinper/widgets/custom_text_field.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String? _selectedCountryId;
  String? _selectedTimeZoneId;
  String? _selectedLanguageId;

  List<dynamic> _countries = [];
  List<dynamic> _timeZones = [];
  List<dynamic> _languages = [];

  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _isFetchingData = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      _userId = await _storage.read(key: 'sub');
      if (_userId == null) throw Exception('User not logged in');

      final results = await Future.wait([
        _apiService.fetchCountries(),
        _apiService.fetchTimezones(),
        _apiService.fetchLanguages(),
        _apiService.fetchUser(_userId!),
      ]);

      final userData = results[3] as Map<String, dynamic>;

      setState(() {
        _countries = results[0] as List<dynamic>;
        _timeZones = results[1] as List<dynamic>;
        _languages = results[2] as List<dynamic>;
        
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _selectedCountryId = userData['country_id'];
        _selectedTimeZoneId = userData['time_zone_id'];
        _selectedLanguageId = userData['language_id'];
        
        _isFetchingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
      setState(() {
        _isFetchingData = false;
      });
    }
  }

  void _updateUser() async {
    if (_selectedCountryId == null ||
        _selectedTimeZoneId == null ||
        _selectedLanguageId == null ||
        _nameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'country_id': _selectedCountryId,
        'time_zone_id': _selectedTimeZoneId,
        'language_id': _selectedLanguageId,
      };

      await _apiService.updateUser(_userId!, userData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario actualizado con éxito')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar usuario: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuario'),
      ),
      body: _isFetchingData
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nombre',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16.0),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      isRequired: true,
                      enabled: false,
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
                            onPressed: _updateUser,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Actualizar Usuario'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
