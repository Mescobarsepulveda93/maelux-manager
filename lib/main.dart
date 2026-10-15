import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MaeluxApp());
}

class MaeluxApp extends StatelessWidget {
  const MaeluxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MAELUX Manager',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
