import 'package:flutter/material.dart';
import 'package:frontend/core/enums.dart';
import 'package:frontend/screens/accounts/create_account_screen.dart';
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
                  : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'All your transactions',
                              style: TextStyle(fontSize: 20),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (_selectedProfile != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateAccountScreen(
                                        profileId: _selectedProfile!,
                                        code: "1.01.01.010",
                                        accountType: AccountType.asset.name,
                                        accountNature: AccountNature.debit.name,
                                        isFinal: true,
                                      ),
                                    ),
                                  ).then((_) {
                                    if (_selectedProfile != null) {
                                      
                                    }
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please select a profile first.')),
                                  );
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _journals.length,
                          itemBuilder: (context, index) {
                            final account = _journals[index];
                            return ListTile(
                              title: Text(account['description']),
                              subtitle: Text(account['date']),
                              trailing: Text(account['date']),
                            );
                          },
                        ),
                      )
                    ],
                  ),
    );
  }
}
