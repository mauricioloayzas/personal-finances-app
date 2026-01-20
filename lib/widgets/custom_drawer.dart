import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/screens/list_accounts_screen.dart';
import 'package:frontend/screens/transactions/another_transaction.dart';

class CustomDrawer extends StatelessWidget {
  final _storage = const FlutterSecureStorage();
  const CustomDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'idToken');
    await _storage.delete(key: 'sub');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.orange,
            ),
            child: Text(
              'Menú',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.money),
            title: const Text('Cash'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ListAccountsScreen(
                    accountParentCode: "1.1.01.",
                    isOnlyParent: false,
                    isOnlyFinal: true,
                  )
                )
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Credit Cards Debts'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ListAccountsScreen(
                            accountParentCode: "2.1.01.",
                            isOnlyParent: false,
                            isOnlyFinal: true,
                          )));
            },
          ),
          ListTile(
            leading: const Icon(Icons.house),
            title: const Text('Loan Debts'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ListAccountsScreen(
                          accountParentCode: "2.1.02.",
                          isOnlyParent: false,
                          isOnlyFinal: true,
                        )),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('Incomes'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ListAccountsScreen(
                          accountParentCode: "4.",
                          isOnlyParent: true,
                          isOnlyFinal: false,
                        )),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.food_bank),
            title: const Text('Exprenses'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ListAccountsScreen(
                          accountParentCode: "5.",
                          isOnlyParent: true,
                          isOnlyFinal: false,
                        )),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_sharp),
            title: const Text('Another Transactions'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AnotherTransaction()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              _logout(context);
            },
          ),
        ],
      ),
    );
  }
}
