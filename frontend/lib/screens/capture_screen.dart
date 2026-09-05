import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services/api_service.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _audioRecorder = Record();
  bool _isRecording = false;
  String? _audioPath;
  bool _isUploading = false;
  String? _successMessage;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/memory_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          path: path,
          encoder: AudioEncoder.aacLc, // good default
          bitRate: 128000,
        );
        
        setState(() {
          _isRecording = true;
          _audioPath = path;
          _successMessage = null;
        });
      }
    } catch (e) {
      print('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      
      if (path != null) {
        await _uploadMemory(path);
      }
    } catch (e) {
      print('Failed to stop recording: $e');
    }
  }

  Future<void> _uploadMemory(String path) async {
    setState(() {
      _isUploading = true;
    });
    
    final apiService = ApiService();
    final memoryId = await apiService.captureMemory(path);
    
    setState(() {
      _isUploading = false;
      if (memoryId != null) {
        _successMessage = 'Memory saved successfully! (ID: $memoryId)';
      } else {
        _successMessage = 'Failed to save memory. Please try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Memory'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isUploading)
              const CircularProgressIndicator()
            else if (_successMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isRecording ? 'Tap to Stop' : 'Tap to Record Memory',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
