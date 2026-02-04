import 'package:flutter/material.dart';
import 'package:mifinper/widgets/custom_app_bar.dart';
import 'package:mifinper/widgets/main_layout.dart';
import '../../services/api_service.dart';
import '../../services/utils_functions.dart';

import 'package:mifinper/screens/accounts/edit_account_screen.dart';
import 'package:mifinper/screens/transactions/transaction_screen.dart';

import '../../models/account_data.dart';
import '../../core/enums.dart';

class ListTransactionsScreen extends StatefulWidget {
  final String accountId;

  const ListTransactionsScreen({super.key, required this.accountId});

  @override
  State<ListTransactionsScreen> createState() => _ListTransactionsScreenState();
}

class _ListTransactionsScreenState extends State<ListTransactionsScreen> {
  final ApiService _apiService = ApiService();
  String? _selectedProfile;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String _pageTitle = "Transactions";
  AccountData? _accountData;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getAccountDetails(String profile) async {
    final accountDetails =
        await _apiService.getAccountProfileDetails(profile, widget.accountId);
    if (mounted) {
      setState(() {
        _accountData = Utils().setAccountData(accountDetails);
        _pageTitle = _accountData!.name;
      });
    }
  }

  Future<void> _getTransactions(String profile) async {
    setState(() {
      _isLoading = true;
    });
    final transactions =
        await _apiService.fetchJournalMovements(profile, widget.accountId);
    if (mounted) {
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } else {}
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
              _getTransactions(profileId);
              _getAccountDetails(profileId);
            } else {
              if (mounted) {
                setState(() {
                  _transactions = [];
                });
              }
            }
          }
        },
      ),
      child: _selectedProfile == null
          ? const Center(
              child: Text('Please select a profile to see the transactions.'),
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
                    if (_accountData != null) _buildButtons(),
                    _transactions.isEmpty
                        ? const Center(child: Text('No transactions yet.'))
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
                                num amount = 0;
                                bool isPositive = false;

                                final details =
                                    transaction['details'] as List<dynamic>?;
                                if (details != null) {
                                  final detail = details.firstWhere(
                                    (d) =>
                                        d['account_id'].toString() ==
                                        widget.accountId,
                                    orElse: () => null,
                                  );

                                  if (detail != null) {
                                    final creditValue = num.tryParse(
                                            detail['credit_value']
                                                    ?.toString() ??
                                                '0') ??
                                        0;
                                    final debitValue = num.tryParse(
                                            detail['debit_value']?.toString() ??
                                                '0') ??
                                        0;
                                    bool isDebit = true;
                                    if (debitValue > 0) {
                                      amount = debitValue;
                                    } else {
                                      amount = creditValue;
                                      isDebit = !isDebit;
                                    }

                                    isPositive = Utils()
                                        .checkPositiveBalanceInTransaction(
                                            _accountData!.type,
                                            amount,
                                            isDebit);
                                  }
                                }

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: !isPositive
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                      child: Icon(
                                        isPositive
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: !isPositive
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      transaction['description'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Date: ${Utils().formatDate(transaction['date'])}'),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Amount: ${Utils().formatCurrencyFromNumber(amount)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: !isPositive
                                                ? Colors.red.shade700
                                                : Colors.green.shade700,
                                          ),
                                        ),
                                      ],
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

  Widget _buildButtons() {
    final accountType =
        AccountType.values.byName(_accountData!.type.toLowerCase());
    final isAssetOrLiability = accountType == AccountType.asset ||
        accountType == AccountType.liability;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            child: const Text('Edit'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditAccountScreen(
                    accountId: widget.accountId,
                    profileId: _selectedProfile!,
                  ),
                ),
              );
            },
          ),
          if (isAssetOrLiability)
            ElevatedButton(
              child: const Text('Adjust'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAccountScreen(
                      accountId: widget.accountId,
                      profileId: _selectedProfile!,
                    ),
                  ),
                );
              },
            ),
          ElevatedButton(
            child: const Text('Add Transaction'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionScreen(
                    accountId: widget.accountId,
                    profileId: _selectedProfile!,
                    onlyCash: false,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
