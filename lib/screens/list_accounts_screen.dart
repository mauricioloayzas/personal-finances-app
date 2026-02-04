import 'package:flutter/material.dart';
import 'package:mifinper/screens/accounts/create_account_screen.dart';
import 'package:mifinper/screens/transactions/list_transactions_screen.dart';
import 'package:mifinper/widgets/custom_app_bar.dart';
import 'package:mifinper/widgets/main_layout.dart';
import '../services/api_service.dart';
import '../services/utils_functions.dart';

class ListAccountsScreen extends StatefulWidget {
  final String accountParentCode;
  final bool isOnlyParent;
  final bool isOnlyFinal;

  const ListAccountsScreen(
      {super.key,
      required this.accountParentCode,
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
  Map<String, dynamic>? _parentAccount;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getPageTitle(String profile) async {
    String? code = widget.accountParentCode;
    if (code.isNotEmpty) {
      final parentCode = code.substring(0, code.length - 1);
      final parentAccount =
          await _apiService.getAccountProfileDetailsByCode(profile, parentCode);
      if (mounted) {
        setState(() {
          _pageTitle = "Accounts in: ${parentAccount['name']}";
          _parentAccount = parentAccount;
        });
      }
    } else {
      setState(() {
        _pageTitle = "Accounts";
        _parentAccount = null;
      });
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: CustomAppBar(
        onDashboardInformationChanged: (journals) {},
        onFetchingDashboardInformationChanged: (isFetching) {},
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _pageTitle,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_selectedProfile != null) {
                                String newCode;
                                if (_accounts.isEmpty) {
                                  newCode = '${widget.accountParentCode}1';
                                } else {
                                  newCode = Utils().getTheNextSequenceCode(
                                      widget.accountParentCode, _accounts);
                                }

                                String accountType =
                                    _parentAccount?['type'] ?? 'asset';
                                String accountNature =
                                    _parentAccount?['nature'] ?? 'debit';

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateAccountScreen(
                                      profileId: _selectedProfile!,
                                      code: newCode,
                                      parentCode: widget.accountParentCode,
                                      accountType: accountType,
                                      accountNature: accountNature,
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
                                      content: Text(
                                          'Please select a profile first.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.add),
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
                                final account = Utils().setAccountData(_accounts[index]);
                                final accountObject =
                                    Utils().setAccountData(_accounts[index]);
                                final balance = num.tryParse(
                                        accountObject.balance.toString()) ??
                                    0;
                                final bool isPositive = Utils()
                                    .checkPositiveBalance(account, balance);

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isPositive
                                          ? Colors.blue.shade100
                                          : Colors.red.shade100,
                                      child: Icon(
                                        balance >= 0
                                            ? Icons.monetization_on
                                            : Icons.money_off,
                                        color: isPositive
                                            ? Colors.blue
                                            : Colors.red,
                                      ),
                                    ),
                                    title: Text(
                                      account.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(account.description),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Balance: ${Utils().formatCurrency(account, balance)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isPositive
                                                ? Colors.blue.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: TextButton(
                                      child: Text(
                                          !account.isFinal ? 'See' : 'Edit'),
                                      onPressed: () {
                                        if (_selectedProfile != null) {
                                          if (!account.isFinal) {
                                            String parentCodeToPass =
                                                account.code + ".";
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
                                                    ListTransactionsScreen(
                                                  accountId: _accounts[index]['id'],
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
