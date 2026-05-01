import 'package:flutter/material.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/widgets/custom_dropdown_selector.dart';
import 'package:mifinper/widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  final String profileId;

  const EditProfileScreen({super.key, required this.profileId});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String? _selectedCountryId;
  String? _selectedCurrencyId;

  List<dynamic> _countries = [];
  List<dynamic> _currencies = [];

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
        _apiService.fetchCurrencies(),
        _apiService.fetchProfileDetails(widget.profileId),
      ]);

      final profileData = results[2] as Map<String, dynamic>;

      setState(() {
        _countries = results[0] as List<dynamic>;
        _currencies = results[1] as List<dynamic>;
        
        _nameController.text = profileData['name'] ?? '';
        _emailController.text = profileData['email'] ?? '';
        _selectedCountryId = profileData['country_id'];
        _selectedCurrencyId = profileData['currency_id'];
        
        _isFetchingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos del perfil: $e')),
        );
      }
      setState(() {
        _isFetchingData = false;
      });
    }
  }

  void _updateProfile() async {
    if (_selectedCountryId == null ||
        _selectedCurrencyId == null ||
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
      final profileData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'country_id': _selectedCountryId,
        'currency_id': _selectedCurrencyId,
      };

      await _apiService.updateProfile(widget.profileId, profileData);
      
      _apiService.clearProfilesCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar perfil: $e')),
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
        title: const Text('Editar Perfil'),
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
                      label: 'Nombre del Perfil',
                      isRequired: true,
                    ),
                    const SizedBox(height: 16.0),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email del Perfil',
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
                      label: 'Moneda *',
                      items: _currencies,
                      selectedId: _selectedCurrencyId,
                      enabled: !_isLoading,
                      itemLabel: (item) => '${item['name']} (${item['code']})',
                      onChanged: (value) => setState(() => _selectedCurrencyId = value),
                    ),
                    const SizedBox(height: 32.0),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _updateProfile,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Actualizar Perfil'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
