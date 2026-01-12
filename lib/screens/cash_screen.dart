import 'package:flutter/material.dart';
import 'package:frontend/core/enums.dart';
import 'package:frontend/screens/accounts/create_account_screen.dart';
import 'package:frontend/screens/accounts/edit_account_screen.dart';
import 'package:frontend/services/utils_functions.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class CashScreen extends StatefulWidget {
  const CashScreen({super.key});

  @override
  State<CashScreen> createState() => _CashScreenState();
}

class _CashScreenState extends State<CashScreen> {
  final String _accountParentCode = "1.1.01.";
  final Utils _utils = Utils();
  final ApiService _apiService = ApiService();
  String? _selectedProfile;
  List<dynamic> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getAccounts(String profile) async {
    setState(() {
      _isLoading = true;
    });
    final accounts = await _apiService.fetchAccounts(profile, _accountParentCode);
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic value) {
    final number = num.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(number);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: CustomAppBar(
        onJournalsChanged: (journals) {},
        onFetchingJournalsChanged: (isFetching) {},
        onSelectedProfileChanged: (profileId) {
          if (mounted) {
            setState(() {
              _selectedProfile = profileId;
            });
            if (profileId != null) {
              _getAccounts(profileId);
            } else {
              if (mounted) {
                setState(() {
                  _accounts = [];
                });
              }
            }
          }
        },
      ),
      child: _selectedProfile == null
          ? const Center(
              child: Text('Please select a profile to see the accounts.'),
            )
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All your direct money',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (_selectedProfile != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateAccountScreen(
                                      profileId: _selectedProfile!,
                                      code: _utils.getTheNextSequenceCode(_accountParentCode, _accounts),
                                      accountType: AccountType.asset.name,
                                      accountNature: AccountNature.debit.name,
                                      isFinal: true,
                                    ),
                                  ),
                                ).then((_) {
                                  if (_selectedProfile != null) {
                                    _getAccounts(_selectedProfile!);
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
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                    _accounts.isEmpty
                        ? const Center(child: Text('No accounts yet.'))
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _accounts.length,
                              itemBuilder: (context, index) {
                                final account = _accounts[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    title: Text(
                                      account['name'],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(account['description']),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Value: ${_formatCurrency(account['balance'])}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
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
                                              _getAccounts(_selectedProfile!);
                                            }
                                          });
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Please select a profile first.')),
                                          );
                                        }
                                      },
                                    ),
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
