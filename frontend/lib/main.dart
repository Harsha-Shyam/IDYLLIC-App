import 'package:flutter/material.dart';
import 'screens/capture_screen.dart';
import 'screens/recall_screen.dart';
import 'screens/family_screen.dart';
import 'screens/vault_screen.dart';
import 'screens/wellbeing_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  bool isOnboarded = prefs.getBool('isOnboarded') ?? false;
  
  Widget initialScreen = LoginScreen();
  if (isLoggedIn) {
    initialScreen = isOnboarded ? const AppScreen() : OnboardingScreen();
  }

  runApp(IdyllicApp(initialScreen: initialScreen));
}

class IdyllicApp extends StatelessWidget {
  final Widget initialScreen;
  const IdyllicApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDYLLIC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    CaptureScreen(),
    RecallScreen(),
    FamilyScreen(),
    VaultScreen(),
    WellbeingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Capture',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Recall',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.family_restroom),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Vault',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'Wellbeing',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
