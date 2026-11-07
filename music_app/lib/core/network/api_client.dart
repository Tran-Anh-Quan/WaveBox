import 'dart:convert';
import 'package:http/http.dart' as http;

/// RESTful API client (JSON) cho Backend Spring Boot.
/// Kèm JWT (Spring Security) gắn vào header Authorization.
class ApiClient {
  final String baseUrl;
  String? _jwt;

  ApiClient({required this.baseUrl, String? jwt}) : _jwt = jwt;

  void setToken(String? token) => _jwt = token;
  String? get token => _jwt;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_jwt != null && _jwt!.isNotEmpty) 'Authorization': 'Bearer $_jwt',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(Uri.parse('$baseUrl$path'),
        headers: _headers, body: jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(Uri.parse('$baseUrl$path'),
        headers: _headers, body: jsonEncode(body));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) {
      if (res.statusCode >= 200 && res.statusCode < 300) return null;
      throw Exception('HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw Exception((data is Map && data['message'] != null)
        ? data['message']
        : 'HTTP ${res.statusCode}');
  }
}
