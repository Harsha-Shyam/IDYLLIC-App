import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // To navigate to AppScreen
import '../services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedIllness = 'General Memory Loss';
  String _selectedFrequency = 'Every 1 Hour';

  final List<String> _illnesses = [
    'General Memory Loss',
    'Alzheimer\'s Disease',
    'Dementia',
    'Brain Injury',
    'Other'
  ];

  final List<String> _frequencies = [
    'Every 1 Hour',
    'Every 3 Hours',
    'Daily (Morning & Evening)',
  ];

  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboarded', true);
    await prefs.setString('illness', _selectedIllness);
    await prefs.setString('reminderFrequency', _selectedFrequency);

    // Schedule loud notifications based on selection
    NotificationService().scheduleAlarms(_selectedFrequency);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AppScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: Text("Let's Get Started"),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "What condition are you managing?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedIllness,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _illnesses.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: (newVal) {
                setState(() {
                  _selectedIllness = newVal!;
                });
              },
            ),
            SizedBox(height: 32),
            Text(
              "How often should we remind you to check your wellbeing routines?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _frequencies.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: (newVal) {
                setState(() {
                  _selectedFrequency = newVal!;
                });
              },
            ),
            SizedBox(height: 48),
            ElevatedButton(
              onPressed: _completeOnboarding,
              child: Text("Continue to App", style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
