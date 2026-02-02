import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:near_share/features/auth/presentation/pages/landing_page.dart';
import 'package:near_share/features/home/presentation/pages/main_scaffold.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If user is authenticated or is a guest, show the home/browsing UI
    if (authProvider.user != null) {
      return const MainScaffold();
    }

    // Otherwise, show the Landing Page
    return const LandingPage();
  }
}
