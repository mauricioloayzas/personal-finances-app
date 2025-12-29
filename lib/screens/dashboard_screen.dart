import 'package:flutter/material.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _accounts = [];
  bool _isFetchingAccounts = true;
  String? _selectedProfile;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: CustomAppBar(
        onAccountsChanged: (accounts) {
          if (mounted) {
            setState(() {
              _accounts = accounts;
            });
          }
        },
        onFetchingAccountsChanged: (isFetching) {
          if (mounted) {
            setState(() {
              _isFetchingAccounts = isFetching;
            });
          }
        },
        onSelectedProfileChanged: (profileId) {
          if (mounted) {
            setState(() {
              _selectedProfile = profileId;
            });
          }
        },
      ),
      child: _selectedProfile == null
          ? const Center(
              child: Text('Please select a profile to see the accounts.'),
            )
          : _isFetchingAccounts
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _accounts.isEmpty
                  ? const Center(
                      child: Text('No accounts found for this profile.'),
                    )
                  : ListView.builder(
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) {
                        final account = _accounts[index];
                        return ListTile(
                          title: Text(account['name']),
                          subtitle: Text(account['code']),
                          trailing: Text(
                            '${account['nature']} ${account['type']}',
                          ),
                        );
                      },
                    ),
    );
  }
}
