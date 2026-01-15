import 'package:flutter/material.dart';
import 'package:frontend/screens/accounts/edit_account_screen.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ListAccountsScreen extends StatefulWidget {
  final String? accountParentCode;
  final bool isOnlyParent;
  final bool isOnlyFinal;

  const ListAccountsScreen(
      {super.key,
      this.accountParentCode,
      this.isOnlyParent = false,
      this.isOnlyFinal = false});

  @override
  State<ListAccountsScreen> createState() => _ListAccountsScreenState();
}

class _ListAccountsScreenState extends State<ListAccountsScreen> {
  final ApiService _apiService = ApiService();
  String? _selectedProfile;
  String _pageTitle = "Account in: ";
  List<dynamic> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getPageTitle(String profile) async {
    String? code = widget.accountParentCode;
    if (code != null) {
      final parentCode = code.substring(0, code.length - 1);
      final parentAccount =
          await _apiService.getAccountProfileDetailsByCode(profile, parentCode);
      if (mounted) {
        _pageTitle = _pageTitle + parentAccount['name'];
      }
    }
  }

  Future<void> _getAccounts(String profile) async {
    setState(() {
      _isLoading = true;
    });
    // Fetch all accounts without a parent code filter
    final accounts = await _apiService.fetchAccounts(
        profile, widget.accountParentCode,
        isOnlyParent: widget.isOnlyParent, isOnlyFinal: widget.isOnlyFinal);
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
              _getPageTitle(profileId);
            } else {
              if (mounted) {
                setState(() {
                  _accounts = [];
                  _pageTitle = "Account in: ";
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
                      child: Text(
                        _pageTitle,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _accounts.isEmpty
                        ? const Center(child: Text('No accounts yet.'))
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _accounts.length,
                              itemBuilder: (context, index) {
                                final account = _accounts[index];
                                final balance = num.tryParse(
                                        account['balance'].toString()) ??
                                    0;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: balance >= 0
                                          ? Colors.blue.shade100
                                          : Colors.red.shade100,
                                      child: Icon(
                                        balance >= 0
                                            ? Icons.monetization_on
                                            : Icons.money_off,
                                        color: balance >= 0
                                            ? Colors.blue
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      account['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(account['description']),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Balance: ${_formatCurrency(balance)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: balance >= 0
                                                ? Colors.blue.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: TextButton(
                                      child: Text(
                                          !account['final'] ? 'See' : 'Edit'),
                                      onPressed: () {
                                        if (_selectedProfile != null) {
                                          if (!account['final']) {
                                            String parentCodeToPass =
                                                account['code'] + ".";
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ListAccountsScreen(
                                                        accountParentCode:
                                                            parentCodeToPass,
                                                        isOnlyParent: true,
                                                        isOnlyFinal: false,
                                                      )),
                                            );
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditAccountScreen(
                                                  profileId: _selectedProfile!,
                                                  accountId: account['id'],
                                                ),
                                              ),
                                            ).then((_) {
                                              if (_selectedProfile != null) {
                                                _getAccounts(_selectedProfile!);
                                              }
                                            });
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
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
