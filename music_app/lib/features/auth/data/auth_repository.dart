import '../../../core/network/api_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Kết quả xác thực: JWT + thông tin user trả về từ backend.
class AuthSession {
  final String token;
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  const AuthSession({
    required this.token,
    this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });
}

/// Repository xác thực theo bảng công nghệ:
/// - Đăng ký / Đăng nhập Email/password -> Backend Spring Boot (Spring Security + JWT)
/// - Đăng nhập Google Sign-In -> lấy idToken ở app, gửi về Backend xác minh token
class AuthRepository {
  final ApiClient api;

  AuthRepository({required this.api});

  Future<AuthSession> registerEmail(
      String email, String password, String displayName) async {
    final data = await api.post('/api/auth/register', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    return _toSession(data, 'Backend không trả về token JWT sau đăng ký');
  }

  Future<AuthSession> loginEmail(String email, String password) async {
    final data = await api.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    return _toSession(data, 'Backend không trả về token JWT');
  }

  Future<AuthSession> loginGoogle() async {
    // google_sign_in v7: dùng singleton instance + authenticate()
    await GoogleSignIn.instance.initialize();
    final account = await GoogleSignIn.instance.authenticate();
    final String? idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Không lấy được Google idToken');
    }
    // Backend xác minh token Google rồi cấp JWT nội bộ
    final data = await api.post('/api/auth/google', {'idToken': idToken});
    return _toSession(data, 'Backend không xác minh được Google token');
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    await api.put('/api/auth/profile', {
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
  }

  Future<void> logout() async {
    api.setToken(null);
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  /// Đọc token + user từ response backend, gắn token vào ApiClient.
  AuthSession _toSession(dynamic data, String missingTokenMessage) {
    final map = data is Map ? data : const {};
    final token = map['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception(missingTokenMessage);
    }
    api.setToken(token);
    final user = map['user'];
    final u = user is Map ? user : const {};
    return AuthSession(
      token: token,
      uid: (u['uuid'] ?? u['id'])?.toString(),
      email: u['email']?.toString(),
      displayName: u['displayName']?.toString(),
      photoUrl: u['photoUrl']?.toString(),
    );
  }
}
