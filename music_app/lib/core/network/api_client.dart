import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lỗi trả về từ backend: giữ lại HTTP status để ViewModel map sang thông báo tiếng Việt.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
  bool get isBadRequest => statusCode == 400;

  @override
  String toString() => message;
}

/// RESTful API client (JSON) cho Backend Spring Boot.
/// Kèm JWT (Spring Security) gắn vào header Authorization.
class ApiClient {
  final String baseUrl;
  final Duration timeout;
  String? _jwt;

  /// Dùng chung một client cho mọi request.
  ///
  /// `http.get(...)` tạo một [http.Client] mới cho mỗi lần gọi → mỗi lần là
  /// một TCP connection + TLS handshake mới. Với app gọi API liên tục (đồng bộ,
  /// tải danh sách) thì phần này tốn thời gian và độ trễ đáng kể.
  final http.Client _client = http.Client();

  ApiClient({required this.baseUrl, String? jwt, this.timeout = const Duration(seconds: 15)})
      : _jwt = jwt;

  void setToken(String? token) => _jwt = token;
  String? get token => _jwt;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_jwt != null && _jwt!.isNotEmpty) 'Authorization': 'Bearer $_jwt',
      };

  Future<dynamic> get(String path) async {
    final res = await _client
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(timeout);
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
        .timeout(timeout);
    return _decode(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await _client
        .put(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
        .timeout(timeout);
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _client
        .delete(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(timeout);
    return _decode(res);
  }

  void dispose() => _client.close();

  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) {
      if (res.statusCode >= 200 && res.statusCode < 300) return null;
      throw ApiException(res.statusCode, 'HTTP ${res.statusCode}');
    }
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      throw ApiException(res.statusCode, 'HTTP ${res.statusCode}: phản hồi không hợp lệ');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final msg = (data is Map && data['message'] != null)
        ? data['message'].toString()
        : 'HTTP ${res.statusCode}';
    throw ApiException(res.statusCode, msg);
  }
}
