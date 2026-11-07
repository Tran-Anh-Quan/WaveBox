import '../../../core/network/api_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Repository xác thực theo bảng công nghệ:
/// - Đăng ký / Đăng nhập Email/password -> Backend Spring Boot (Spring Security + JWT)
/// - Đăng nhập Google Sign-In -> lấy idToken ở app, gửi về Backend xác minh token
class AuthRepository {
  final ApiClient api;

  AuthRepository({required this.api});

  Future<String> registerEmail(String email, String password, String displayName) async {
    final data = await api.post('/api/auth/register', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
    final token = (data is Map ? data['token'] : null) as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Backend không trả về token JWT sau đăng ký');
    }
    api.setToken(token);
    return token;
  }

  Future<String> loginEmail(String email, String password) async {
    final data = await api.post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    final token = (data is Map ? data['token'] : null) as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Backend không trả về token JWT');
    }
    api.setToken(token);
    return token;
  }

  Future<String> loginGoogle() async {
    // google_sign_in v7: dùng singleton instance + authenticate()
    await GoogleSignIn.instance.initialize();
    final account = await GoogleSignIn.instance.authenticate();
    final String? idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Không lấy được Google idToken');
    }
    // Backend xác minh token Google rồi cấp JWT nội bộ
    final data = await api.post('/api/auth/google', {'idToken': idToken});
    final token = (data is Map ? data['token'] : null) as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Backend không xác minh được Google token');
    }
    api.setToken(token);
    return token;
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
}
