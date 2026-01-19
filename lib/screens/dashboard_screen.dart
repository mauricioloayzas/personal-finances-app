import 'package:flutter/material.dart';
import 'package:frontend/core/enums.dart';
import 'package:frontend/screens/accounts/create_account_screen.dart';
import 'package:frontend/screens/accounts/edit_account_screen.dart';
import 'package:frontend/widgets/custom_app_bar.dart';
import 'package:frontend/widgets/main_layout.dart';
import 'package:intl/intl.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _journals = [];
  bool _isFetchingJournals = true;
  String? _selectedProfile;

  // Función auxiliar para dar formato de moneda
  String _formatCurrency(dynamic value) {
    final number = num.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(number);
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
                                'All your transactions',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                onPressed: () => _navigateToCreateAccount(),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _journals.length,
                            itemBuilder: (context, index) {
                              final account = _journals[index];
                              final balance = num.tryParse(account['value'].toString()) ?? 0;

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: balance >= 0 ? Colors.blue.shade100 : Colors.red.shade100,
                                    child: Icon(
                                      balance >= 0 ? Icons.account_balance_wallet : Icons.warning_amber_rounded,
                                      color: balance >= 0 ? Colors.blue : Colors.red,
                                    ),
                                  ),
                                  title: Text(
                                    account['description'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  // OPCIÓN 2: Balance anidado en el subtitle
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(DateFormat('y-MM-dd HH:mm:ss').format(DateTime.parse(account['date']))),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Value: ${_formatCurrency(account['value'])}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: balance >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: TextButton(
                                    child: const Text('Edit'),
                                    onPressed: () => _navigateToEditAccount(account),
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

  void _navigateToCreateAccount() {
    if (_selectedProfile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAccountScreen(
            profileId: _selectedProfile!,
            code: "1.01.01.010",
            parentCode: "1.1.01.",
            accountType: AccountType.asset.name,
            accountNature: AccountNature.debit.name,
            isFinal: true,
          ),
        ),
      );
    }
  }

  void _navigateToEditAccount(dynamic account) {
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
        // Aquí podrías refrescar la lista si fuera necesario
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile first.')),
      );
    }
  }
}