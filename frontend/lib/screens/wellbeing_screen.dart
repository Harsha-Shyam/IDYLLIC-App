import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WellbeingScreen extends StatefulWidget {
  const WellbeingScreen({super.key});

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    setState(() => _isLoading = true);
    final routines = await _apiService.getRoutines();
    setState(() {
      _routines = routines ?? [];
      _isLoading = false;
    });
  }

  Future<void> _addRoutine() async {
    String label = '';
    String type = 'water';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Routine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Routine Name (e.g. Drink Water)'),
                onChanged: (val) => label = val,
              ),
              DropdownButton<String>(
                value: type,
                items: <String>['water', 'meal', 'medication', 'custom']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => type = val);
                },
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (label.isNotEmpty) {
      setState(() => _isLoading = true);
      await _apiService.addRoutine(label, type, '* * * * *');
      await _loadRoutines();
    }
  }

  Future<void> _confirmRoutine(String routineId) async {
    await _apiService.confirmRoutine(routineId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Great job! Routine completed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellbeing & Routines'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addRoutine,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _routines.length,
            itemBuilder: (context, index) {
              final routine = _routines[index];
              return ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.deepPurple),
                title: Text(routine['label'] ?? ''),
                subtitle: Text(routine['routine_type'] ?? ''),
                trailing: ElevatedButton(
                  onPressed: () => _confirmRoutine(routine['routine_id']),
                  child: const Text('Done'),
                ),
              );
            },
          ),
    );
  }
}
