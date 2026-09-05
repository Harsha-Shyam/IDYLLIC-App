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

  Future<String?> recallMemory(String query) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/memories/recall'),
        headers: {
          'x-user-id': '00000000-0000-0000-0000-000000000001',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'query': query}),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        return json['answer'];
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<List<dynamic>?> getFamilyMembers() async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/family'),
        headers: {'x-user-id': '00000000-0000-0000-0000-000000000001'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<bool> addFamilyMember(String name, String relation, String imagePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/family/add'));
      request.headers['x-user-id'] = '00000000-0000-0000-0000-000000000001';
      request.fields['name'] = name;
      request.fields['relation_label'] = relation;
      request.files.add(await http.MultipartFile.fromPath('photo', imagePath));
      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<List<dynamic>?> getVaultDocuments() async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/vault'),
        headers: {'x-user-id': '00000000-0000-0000-0000-000000000001'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<bool> uploadVaultDocument(String label, String type, String filePath) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/vault/upload'));
      request.headers['x-user-id'] = '00000000-0000-0000-0000-000000000001';
      request.fields['label'] = label;
      request.fields['document_type'] = type;
      request.files.add(await http.MultipartFile.fromPath('document', filePath));
      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<List<dynamic>?> getRoutines() async {
    try {
      var response = await http.get(
        Uri.parse('$baseUrl/routines'),
        headers: {'x-user-id': '00000000-0000-0000-0000-000000000001'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<bool> addRoutine(String label, String type, String cron) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/routines/add'),
        headers: {
          'x-user-id': '00000000-0000-0000-0000-000000000001',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'label': label, 'routine_type': type, 'schedule_cron': cron}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> confirmRoutine(String routineId) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/routines/confirm'),
        headers: {
          'x-user-id': '00000000-0000-0000-0000-000000000001',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'routine_id': routineId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
