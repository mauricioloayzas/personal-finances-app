import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
              // Navegar a Cuentas
              Navigator.pushNamed(context, '/cash');
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Credit Cards Debts'),
            onTap: () {
              // Navegar a Configuración
              Navigator.pushNamed(context, '/cash');
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Loan Debts'),
            onTap: () {
              // Navegar a Configuración
              Navigator.pushNamed(context, '/cash');
            },
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on_sharp),
            title: const Text('Transactions'),
            onTap: () {
              // Navegar a Configuración
              Navigator.pushNamed(context, '/cash');
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
