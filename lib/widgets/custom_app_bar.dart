import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueChanged<List<dynamic>> onAccountsChanged;
  final ValueChanged<bool> onFetchingAccountsChanged;
  final ValueChanged<String?> onSelectedProfileChanged;

  const CustomAppBar({
    super.key,
    required this.onAccountsChanged,
    required this.onFetchingAccountsChanged,
    required this.onSelectedProfileChanged,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _profiles = [];
  String? _selectedProfile;
  bool _isLoading = true;
  List<dynamic> _accounts = [];

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    try {
      final idToken = await _storage.read(key: 'idToken');
      final sub = await _storage.read(key: 'sub');
      final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
      final response = await http.get(
        Uri.parse('$apiOrchestratorUrl/profiles/rbacs/by-user?user_id=$sub'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> rbacs = jsonDecode(response.body);

        final profileDetails = await Future.wait(
          rbacs.map<Future<Map<String, dynamic>>>((rbac) {
            return _fetchProfileDetails(rbac['profile_id'].toString());
          }).toList(),
        );
        setState(() {
          _profiles = profileDetails;
          if (_profiles.isNotEmpty) {
            _selectedProfile = _profiles.first['id'].toString();
            widget.onSelectedProfileChanged(_selectedProfile);
            _fetchAccounts(_selectedProfile!);
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        final errorMessages = jsonDecode(response.body);
        _showError(errorMessages['message']);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error de red: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchProfileDetails(String profileId) async {
    final idToken = await _storage.read(key: 'idToken');
    final apiOrchestratorUrl = dotenv.env['API_ORCHESTRATOR_URL'];
    final response = await http.get(
      Uri.parse('$apiOrchestratorUrl/profiles/$profileId'),
      headers: {
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile details');
    }
  }

  Future<void> _fetchAccounts(String profileId) async {
    widget.onFetchingAccountsChanged(true);

    try {
      final idToken = await _storage.read(key: 'idToken');
      final apiPFUrl = dotenv.env['API_PF_URL'];
      final response = await http.get(
        Uri.parse('$apiPFUrl/profiles/$profileId/accounts'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _accounts = jsonDecode(response.body);
          widget.onAccountsChanged(_accounts);
          widget.onFetchingAccountsChanged(false);
        });
      } else {
        setState(() {
          _accounts = [];
          widget.onAccountsChanged([]);
          widget.onFetchingAccountsChanged(false);
        });
        final errorMessages = jsonDecode(response.body);
        _showError(errorMessages['message']);
      }
    } catch (e) {
      widget.onFetchingAccountsChanged(false);
      _showError('Error de red: $e');
    }
  }

  void _onProfileChanged(String? newProfileId) {
    if (newProfileId != null && newProfileId != _selectedProfile) {
      setState(() {
        _selectedProfile = newProfileId;
        widget.onSelectedProfileChanged(newProfileId);
        _accounts = [];
        widget.onAccountsChanged([]);
      });
      _fetchAccounts(newProfileId);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'idToken');
    await _storage.delete(key: 'sub');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(days: 365),
          action: SnackBarAction(
            label: 'CERRAR',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child:
                Center(child: CircularProgressIndicator(color: Colors.black)),
          )
        else if (_profiles.isNotEmpty)
          DropdownButton<String>(
            value: _selectedProfile,
            hint: const Text('Select Profile',
                style: TextStyle(color: Colors.black)),
            onChanged: _onProfileChanged,
            items: _profiles.map<DropdownMenuItem<String>>((profile) {
              return DropdownMenuItem<String>(
                value: profile['id'].toString(),
                child: Text(profile['name']),
              );
            }).toList(),
            dropdownColor: Colors.orange,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.black),
            iconEnabledColor: Colors.black,
            underline: Container(),
          ),
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // Acción de notificaciones
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _logout(context),
        ),
      ],
    );
  }
}
