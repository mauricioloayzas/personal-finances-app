import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mifinper/services/api_service.dart';
import 'package:mifinper/widgets/custom_app_bar.dart';
import 'package:mifinper/widgets/custom_dropdown_selector.dart';
import 'package:mifinper/widgets/custom_text_field.dart';
import 'package:mifinper/widgets/main_layout.dart';
import 'package:mifinper/screens/dashboard_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _selectedCountryId;
  String? _selectedCurrencyId;

  List<dynamic> _countries = [];
  List<dynamic> _currencies = [];

  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  bool _isCreating = false;
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
      ]);

      setState(() {
        _countries = results[0];
        _currencies = results[1];
        _isFetchingData = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos iniciales: $e')),
        );
      }
      setState(() {
        _isFetchingData = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createProfileAndInitialize() async {
    if (_selectedCountryId == null || _selectedCurrencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final String? userId = await _storage.read(key: 'sub');
      if (userId == null) {
        throw Exception('User not logged in.');
      }

      // 1. Create Profile
      final Map<String, dynamic> newProfile = await _apiService.createProfile(
        name: _nameController.text,
        email: _emailController.text,
        countryId: _selectedCountryId!,
        currencyId: _selectedCurrencyId!,
      );
      final String newProfileId = newProfile['id'];

      // 2. Create RBAC for the new profile
      await _apiService.createRbac(
        newProfileId,
        userId,
      );

      // 3. Initialize Profile Accounts
      await _apiService.initProfileAccounts(newProfileId);

      _apiService.clearProfilesCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Perfil creado y inicializado con éxito')),
        );
        // Navigate to DashboardScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear o inicializar el perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: CustomAppBar(
        onDashboardInformationChanged: (_) {},
        onFetchingDashboardInformationChanged: (_) {},
        onSelectedProfileChanged: (_) {},
      ),
      child: _isCreating || _isFetchingData
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 600
                          ? 600
                          : constraints.maxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crear Nuevo Perfil',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                                _nameController, 'Nombre del Perfil'),
                            const SizedBox(height: 20),
                            _buildTextField(_emailController, 'Email del Perfil'),
                            const SizedBox(height: 20),
                            CustomDropdownSelector(
                              label: 'País *',
                              items: _countries,
                              selectedId: _selectedCountryId,
                              onChanged: (value) => setState(() => _selectedCountryId = value),
                            ),
                            const SizedBox(height: 20),
                            CustomDropdownSelector(
                              label: 'Moneda *',
                              items: _currencies,
                              selectedId: _selectedCurrencyId,
                              itemLabel: (currency) => '${currency['name']} (${currency['code']})',
                              onChanged: (value) => setState(() => _selectedCurrencyId = value),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _createProfileAndInitialize,
                                child: const Text('Crear Perfil'),
                              ),
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return CustomTextField(
      controller: controller,
      label: label,
      isRequired: true,
    );
  }
}
