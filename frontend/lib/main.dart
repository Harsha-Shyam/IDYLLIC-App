import 'package:flutter/material.dart';
import 'screens/capture_screen.dart';

void main() {
  runApp(const IdyllicApp());
}

class IdyllicApp extends StatelessWidget {
  const IdyllicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDYLLIC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CaptureScreen(),
    );
  }
}
