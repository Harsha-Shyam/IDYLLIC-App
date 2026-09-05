import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Use host machine IP so physical phone on same WiFi can connect
  static const String baseUrl = 'http://172.17.209.230:3000';

  Future<String?> captureMemory(String audioPath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/memories/capture'));
      
      // Mock user header
      request.headers['x-user-id'] = '00000000-0000-0000-0000-000000000001';
      request.headers['Authorization'] = 'Bearer mocked-token';
      
      // Attach audio file
      var file = await http.MultipartFile.fromPath('audio', audioPath);
      request.files.add(file);

      var response = await request.send().timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 201) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        return json['memory_id'];
      } else {
        print('Failed to capture memory: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network or API Error: $e');
      return null;
    }
  }
}
