import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../data/app_database.dart';
import '../../../models/catalog.dart';
import '../data/auth_repository.dart';

/// ViewModel (MVVM) cho auth: giữ token JWT + profile,
/// không chứa code giao diện hay gọi HTTP trực tiếp.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;
  /// DB cục bộ để cache profile (bảng `users`) sau khi đăng ký / đăng nhập.
  final AppDatabase? db;
  String? token;
  String? uid;
  String? email;
  String? displayName;
  String? photoUrl;
  bool loading = false;
  String? error;
  bool isRegisterMode = false;

  AuthViewModel({required this.repo, this.db});

  bool get isLoggedIn => token != null && token!.isNotEmpty;

  void toggleMode() {
    isRegisterMode = !isRegisterMode;
    error = null;
    notifyListeners();
  }

  Future<void> loadSaved() async {
    try {
      final p = await SharedPreferences.getInstance();
      token = p.getString('jwt');
      email = p.getString('email');
      displayName = p.getString('displayName');
      photoUrl = p.getString('photoUrl');
      if (token != null && token!.isNotEmpty) repo.api.setToken(token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    if (token != null) await p.setString('jwt', token!);
    if (email != null) await p.setString('email', email!);
    if (displayName != null) await p.setString('displayName', displayName!);
    if (photoUrl != null) await p.setString('photoUrl', photoUrl!);
  }

  Future<bool> loginEmail(String emailInput, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final invalid = validateEmailPassword(emailInput, password);
      if (invalid != null) {
        error = invalid;
        return false;
      }
      final session = await repo.loginEmail(emailInput.trim(), password);
      token = session.token;
      email = session.email ?? emailInput.trim();
      displayName = session.displayName ?? email!.split('@').first;
      photoUrl = session.photoUrl;
      uid = session.uid;
      await _persist();
      await _cacheUser();
      return true;
    } catch (e) {
      error = friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> registerEmail(String emailInput, String password, String name) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final invalid = validateEmailPassword(emailInput, password);
      if (invalid != null) {
        error = invalid;
        return false;
      }
      if (name.trim().isEmpty) {
        error = 'Vui lòng nhập tên hiển thị';
        return false;
      }
      final session =
          await repo.registerEmail(emailInput.trim(), password, name.trim());
      token = session.token;
      email = session.email ?? emailInput.trim();
      displayName = session.displayName ?? name.trim();
      photoUrl = session.photoUrl;
      uid = session.uid;
      await _persist();
      await _cacheUser();
      return true;
    } catch (e) {
      error = friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> loginGoogle() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final session = await repo.loginGoogle();
      token = session.token;
      email = session.email;
      displayName = session.displayName;
      photoUrl = session.photoUrl;
      uid = session.uid;
      await _persist();
      await _cacheUser();
      return true;
    } catch (e) {
      error = friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String name) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await repo.updateProfile(displayName: name);
      displayName = name;
      await _persist();
      await _cacheUser();
      return true;
    } catch (e) {
      error = friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await repo.logout();
    final p = await SharedPreferences.getInstance();
    await p.remove('jwt');
    token = null;
    notifyListeners();
  }

  /// Ghi profile vào bảng `users` cục bộ để hiển thị offline (UC 8.3).
  Future<void> _cacheUser() async {
    final database = db;
    final mail = email;
    if (database == null || mail == null || mail.isEmpty) return;
    try {
      await database.upsertUser(AppUser(
        id: uid ?? token ?? mail,
        email: mail,
        displayName: displayName ?? mail.split('@').first,
        photoUrl: photoUrl,
      ));
    } catch (_) {
      // Cache profile lỗi không được làm hỏng luồng đăng nhập.
    }
  }

  /// Kiểm tra dữ liệu form phía client trước khi gọi API.
  /// Trả về null nếu hợp lệ, ngược lại trả về thông báo lỗi.
  static String? validateEmailPassword(String email, String password) {
    final e = email.trim();
    if (e.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(e)) {
      return 'Email không hợp lệ';
    }
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (password.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  /// Chuyển lỗi kỹ thuật (HTTP / socket) thành thông báo tiếng Việt dễ hiểu.
  static String friendlyError(Object e) {
    if (e is ApiException) return _fromApiException(e);
    final s = e.toString().replaceFirst('Exception: ', '').trim();
    if (s.contains('SocketException') ||
        s.contains('Connection refused') ||
        s.contains('Failed host') ||
        s.contains('Connection timed out')) {
      return 'Không kết nối được Backend. Kiểm tra server Spring Boot đang chạy + baseUrl.';
    }
    if (s.contains('TimeoutException')) {
      return 'Backend phản hồi quá lâu. Kiểm tra mạng rồi thử lại.';
    }
    // Lỗi từ ApiClient cũ hoặc test double: dạng "HTTP 401: ..."
    final m = RegExp(r'^HTTP (\d{3}):\s*(.*)$').firstMatch(s);
    if (m != null) {
      return _fromApiException(ApiException(int.parse(m.group(1)!), m.group(2)!));
    }
    return _canonicalMessage(s) ?? s;
  }

  static String _fromApiException(ApiException e) {
    switch (e.statusCode) {
      case 400:
        return _canonicalMessage(e.message) ?? 'Dữ liệu gửi lên không hợp lệ';
      case 401:
        return 'Sai email hoặc mật khẩu';
      case 403:
        return 'Không có quyền truy cập';
      case 404:
        return _canonicalMessage(e.message) ?? 'Không tìm thấy tài nguyên';
      case 409:
        return _canonicalMessage(e.message) ?? 'Email đã được đăng ký';
      case 500:
        return 'Lỗi máy chủ (500). Vui lòng thử lại sau.';
      default:
        if (e.statusCode >= 500) {
          return 'Lỗi máy chủ (${e.statusCode}). Vui lòng thử lại sau.';
        }
        return _canonicalMessage(e.message) ?? e.message;
    }
  }

  /// Chuẩn hoá message không dấu/khác dấu từ backend về thông báo tiếng Việt có dấu.
  static String? _canonicalMessage(String raw) {
    final key = _fold(raw);
    const map = {
      'email da duoc dang ky': 'Email đã được đăng ký',
      'email da ton tai': 'Email đã được đăng ký',
      'sai email hoac mat khau': 'Sai email hoặc mật khẩu',
      'email khong hop le': 'Email không hợp lệ',
      'mat khau phai co it nhat 6 ky tu': 'Mật khẩu phải có ít nhất 6 ký tự',
      'khong tim thay user': 'Không tìm thấy tài khoản',
      'chua dang nhap': 'Chưa đăng nhập',
      'thieu google idtoken': 'Không lấy được Google idToken',
    };
    for (final entry in map.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Bỏ dấu tiếng Việt + hạ chữ thường để so khớp message không dấu.
  static String _fold(String s) {
    const map = <String, String>{
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a', 'â': 'a', 'ầ': 'a',
      'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ă': 'a', 'ằ': 'a', 'ắ': 'a',
      'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ê': 'e', 'ề': 'e',
      'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o', 'ô': 'o', 'ồ': 'o',
      'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ơ': 'o', 'ờ': 'o', 'ớ': 'o',
      'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u', 'ưừ': 'u', 'ứ': 'u',
      'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'đ': 'd',
    };
    final b = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      b.write(map[ch] ?? ch);
    }
    return b.toString();
  }
}
