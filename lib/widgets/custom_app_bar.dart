import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueChanged<List<dynamic>> onDashboardInformationChanged;
  final ValueChanged<bool> onFetchingDashboardInformationChanged;
  final ValueChanged<String?> onSelectedProfileChanged;

  const CustomAppBar({
    super.key,
    required this.onDashboardInformationChanged,
    required this.onFetchingDashboardInformationChanged,
    required this.onSelectedProfileChanged,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final ApiService _apiService = ApiService();
  List<dynamic> _profiles = [];
  String? _selectedProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await _apiService.fetchProfiles();
      setState(() {
        _profiles = profiles;
        if (_profiles.isNotEmpty) {
          _selectedProfile = _profiles.first['id'].toString();
          widget.onSelectedProfileChanged(_selectedProfile);
          _loadDashboardInformation(_selectedProfile!);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError(e.toString());
    }
  }

  Future<void> _loadDashboardInformation(String profileId) async {
    widget.onFetchingDashboardInformationChanged(true);
    try {
      final journals = await _apiService.fetchDashboardInformation(profileId);
      widget.onDashboardInformationChanged(journals);
    } catch (e) {
      widget.onDashboardInformationChanged([]);
      _showError(e.toString());
    } finally {
      widget.onFetchingDashboardInformationChanged(false);
    }
  }

  void _onProfileChanged(String? newProfileId) {
    if (newProfileId != null && newProfileId != _selectedProfile) {
      setState(() {
        _selectedProfile = newProfileId;
        widget.onSelectedProfileChanged(newProfileId);
        widget.onDashboardInformationChanged([]);
      });
      _loadDashboardInformation(newProfileId);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _apiService.logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _showError('Error during logout: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.replaceFirst('Exception: ', '')),
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
            // Notification action
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }
}
