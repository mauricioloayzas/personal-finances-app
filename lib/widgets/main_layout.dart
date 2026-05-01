import 'package:flutter/material.dart';
import 'package:mifinper/widgets/custom_drawer.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final String? profileId;

  const MainLayout({super.key, required this.child, this.appBar, this.profileId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: CustomDrawer(profileId: profileId),
      body: child,
    );
  }
}
