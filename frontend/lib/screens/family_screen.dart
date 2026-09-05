import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _familyMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    setState(() => _isLoading = true);
    final members = await _apiService.getFamilyMembers();
    setState(() {
      _familyMembers = members ?? [];
      _isLoading = false;
    });
  }

  Future<void> _addMember() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    String name = '';
    String relation = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Family Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Relationship (e.g., Daughter)'),
                onChanged: (val) => relation = val,
              ),
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

    if (name.isNotEmpty && relation.isNotEmpty) {
      setState(() => _isLoading = true);
      await _apiService.addFamilyMember(name, relation, image.path);
      await _loadFamily();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family & Relationships'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addMember,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _familyMembers.length,
            itemBuilder: (context, index) {
              final member = _familyMembers[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(member['name'] ?? ''),
                subtitle: Text(member['relation_label'] ?? ''),
              );
            },
          ),
    );
  }
}
