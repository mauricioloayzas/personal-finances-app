import 'package:flutter/material.dart';
import 'package:frontend/core/enums.dart';
import 'package:frontend/screens/accounts/create_account_screen.dart';
import 'package:frontend/screens/accounts/edit_account_screen.dart';
import 'package:frontend/screens/list_accounts_screen.dart';
import 'package:frontend/screens/transactions/another_transaction.dart';
import 'package:frontend/services/utils_functions.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';
import 'package:intl/intl.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _dashboardInformation = [];
  bool _isFetchingDashboardInformation = true;
  String? _selectedProfile;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      appBar: CustomAppBar(
        onDashboardInformationChanged: (dashboardInformation) {
          if (mounted) {
            setState(() {
              _dashboardInformation = dashboardInformation;
            });
          }
        },
        onFetchingDashboardInformationChanged: (isFetching) {
          if (mounted) {
            setState(() {
              _isFetchingDashboardInformation = isFetching;
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
          : _isFetchingDashboardInformation
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _dashboardInformation.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Text('No dashboardInformation yet.'),
                          TextButton(
                            child: const Text('You can init setting the cash'),
                            onPressed: () {
                              Navigator.pushNamed(context, '/cash');
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
                                'Here is your resume:',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                onPressed: () => {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const AnotherTransaction()
                                    ),
                                  )
                                },
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _dashboardInformation.length,
                            itemBuilder: (context, index) {
                              final account = _dashboardInformation[index];
                              final balance = num.tryParse(account['balance'].toString()) ?? 0;
                              final bool isPositive = Utils().checkPositiveBalance(account, balance);

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isPositive ? Colors.blue.shade100 : Colors.red.shade100,
                                    child: Icon(
                                      balance >= 0 ? Icons.account_balance_wallet : Icons.warning_amber_rounded,
                                      color: isPositive ? Colors.blue : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    account['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  // OPCIÓN 2: Balance anidado en el subtitle
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(account['code']),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Value: ${Utils().formatCurrency(account, balance)}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isPositive ? Colors.blue.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: TextButton(
                                    child: const Text('Edit'),
                                    onPressed: () => _navigateToListChildAccount(account),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
    );
  }

  void _navigateToListChildAccount(dynamic account) {
    if (_selectedProfile != null) {
      String parentCodeToPass = account['code'] + ".";
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
      ).then((_) {
        // Aquí podrías refrescar la lista si fuera necesario
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile first.')),
      );
    }
  }
}