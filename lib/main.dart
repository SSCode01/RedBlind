import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const StackSyncApp());
}

class StackSyncApp extends StatelessWidget {
  const StackSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StackSync',

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF8B0000),
        primaryColor: const Color(0xFFB11226),
        fontFamily: 'Inter', // Optional if you add custom font
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB11226),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}
