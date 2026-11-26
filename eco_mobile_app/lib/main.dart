import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_nav_screen.dart';

void main() {
  runApp(const EcoProjectApp());
}

class EcoProjectApp extends StatelessWidget {
  const EcoProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoProject',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavScreen(),
    );
  }
}
