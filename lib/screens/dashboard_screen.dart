import 'package:flutter/material.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _journals = [];
  bool _isFetchingJournals = true;
  String? _selectedProfile;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: CustomAppBar(
        onJournalsChanged: (journals) {
          if (mounted) {
            setState(() {
              _journals = journals;
            });
          }
        },
        onFetchingJournalsChanged: (isFetching) {
          if (mounted) {
            setState(() {
              _isFetchingJournals = isFetching;
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
          : _isFetchingJournals
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _journals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text('No journals yet.'),
                          TextButton(
                            child: const Text('You can init setting the cash'),
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, '/cash');
                            },
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _journals.length,
                      itemBuilder: (context, index) {
                        final account = _journals[index];
                        return ListTile(
                          title: Text(account['descriptions']),
                          subtitle: Text(account['details']),
                          trailing: Text('date'),
                        );
                      },
                    ),
    );
  }
}
