import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    setState(() => _isLoading = true);
    final docs = await _apiService.getVaultDocuments();
    setState(() {
      _documents = docs ?? [];
      _isLoading = false;
    });
  }

  Future<void> _uploadDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result == null || result.files.single.path == null) return;

    String label = '';
    String type = 'other'; // identity, legal, medical

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Secure Upload'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Document Name'),
                onChanged: (val) => label = val,
              ),
              DropdownButton<String>(
                value: type,
                items: <String>['identity', 'legal', 'medical', 'other']
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
              child: const Text('Upload'),
            ),
          ],
        );
      },
    );

    if (label.isNotEmpty) {
      setState(() => _isLoading = true);
      await _apiService.uploadVaultDocument(label, type, result.files.single.path!);
      await _loadVault();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Vault'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadDocument,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _documents.length,
            itemBuilder: (context, index) {
              final doc = _documents[index];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(doc['label'] ?? ''),
                subtitle: Text(doc['document_type'] ?? ''),
              );
            },
          ),
    );
  }
}
