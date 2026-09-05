import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecallScreen extends StatefulWidget {
  const RecallScreen({super.key});

  @override
  State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  String _answer = '';
  bool _isLoading = false;

  void _askQuestion() async {
    if (_controller.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _answer = '';
    });

    final answer = await _apiService.recallMemory(_controller.text);

    setState(() {
      _isLoading = false;
      _answer = answer ?? 'Failed to recall memory.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recall Memory'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Ask about your memories...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _askQuestion,
                ),
              ),
              onSubmitted: (_) => _askQuestion(),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_answer.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _answer,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
