import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// Post-auth shell: bottom navigation with Home, Tips, Progress, and Profile.
class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
