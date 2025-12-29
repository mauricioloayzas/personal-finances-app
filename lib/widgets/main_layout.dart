import 'package:flutter/material.dart';
import 'package:frontend/widgets/custom_drawer.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;

  const MainLayout({super.key, required this.child, this.appBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: const CustomDrawer(),
      body: child,
      // Opcional: si quieres un pie de página o barra de navegación inferior
      // bottomNavigationBar: const CustomBottomNavigationBar(),
    );
  }
}
