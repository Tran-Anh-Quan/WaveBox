import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_repository.dart';

/// ViewModel (MVVM) cho auth: giữ token JWT + profile,
/// không chứa code giao diện hay gọi HTTP trực tiếp.
class AuthViewModel extends ChangeNotifier {
  final AuthRepository repo;
  String? token;
  String? email;
  String? displayName;
  String? photoUrl;
  bool loading = false;
  String? error;
  bool isRegisterMode = false;

  AuthViewModel({required this.repo});

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
      if (token != null && token!.isNotEmpty) repo.api.setToken(token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    if (token != null) await p.setString('jwt', token!);
    if (email != null) await p.setString('email', email!);
    if (displayName != null) await p.setString('displayName', displayName!);
  }

  Future<bool> loginEmail(String emailInput, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      token = await repo.loginEmail(emailInput, password);
      email = emailInput;
      displayName = emailInput.split('@').first;
      await _persist();
      return true;
    } catch (e) {
      error = _friendly(e);
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
      token = await repo.registerEmail(emailInput, password, name);
      email = emailInput;
      displayName = name;
      await _persist();
      return true;
    } catch (e) {
      error = _friendly(e);
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
      token = await repo.loginGoogle();
      await _persist();
      return true;
    } catch (e) {
      error = _friendly(e);
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
      return true;
    } catch (e) {
      error = _friendly(e);
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

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Connection refused') || s.contains('Failed host')) {
      return 'Không kết nối được Backend. Kiểm tra server Spring Boot đang chạy + baseUrl.';
    }
    return s.replaceFirst('Exception: ', '');
  }
}
