import 'package:flutter/material.dart';
import 'package:frontend/core/enums.dart';
import 'package:frontend/screens/accounts/create_account_screen.dart';
import 'package:frontend/screens/accounts/edit_account_screen.dart';
import 'package:frontend/services/utils_functions.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';
import '../services/api_service.dart';

class LoanDebtsScreen extends StatefulWidget {
  const LoanDebtsScreen({super.key});

  @override
  State<LoanDebtsScreen> createState() => _LoanDebtsScreenState();
}

class _LoanDebtsScreenState extends State<LoanDebtsScreen> {
  final String _accountParentCode = "2.1.02.";
  final Utils _utils = Utils();
  final ApiService _apiService = ApiService();
  List<dynamic> _journals = [];
  bool _isFetchingJournals = true;
  String? _selectedProfile;

  List<dynamic> _money = [];

  Future<void> _getAccountsMoney(String profile) async {
    final money = await _apiService.fetchAccounts(profile, _accountParentCode);
    if (mounted) {
      setState(() {
        _money = money;
      });
    }
  }

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
            if (profileId != null) {
              _getAccountsMoney(profileId);
            } else {
              if (mounted) {
                setState(() {
                  _money = [];
                });
              }
            }
          }
        },
      ),
      child: _selectedProfile == null
          ? const Center(
              child: Text('Please select a profile to see the jorunals.'),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All your loan debts',
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
                                  code: _utils.getTheNextSequenceCode(_accountParentCode, _money),
                                  accountType: AccountType.liability.name,
                                  accountNature: AccountNature.credit.name,
                                  isFinal: true,
                                ),
                              ),
                            ).then((_) {
                              if (_selectedProfile != null) {
                                _getAccountsMoney(_selectedProfile!);
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
                    itemCount: _money.length,
                    itemBuilder: (context, index) {
                      final account = _money[index];
                      return ListTile(
                        title: Text(account['name']),
                        subtitle: Text(account['description']),
                        trailing: TextButton(
                          child: const Text('Edit'),
                          onPressed: () {
                            if (_selectedProfile != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditAccountScreen(
                                    profileId: _selectedProfile!,
                                    accountId: account['id'],
                                  ),
                                ),
                              ).then((_) {
                                if (_selectedProfile != null) {
                                  _getAccountsMoney(_selectedProfile!);
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
