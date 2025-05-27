import 'package:flutter/material.dart';
import 'package:frontend/features/chat/presentation/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: const HomeScreen(),
      ),
    );
  }
}

