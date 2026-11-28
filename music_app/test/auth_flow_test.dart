import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/network/api_client.dart';
import 'package:music_app/features/auth/data/auth_repository.dart';
import 'package:music_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test luồng đăng nhập / đăng ký (UC 8.x) chạy thật với backend mock
/// đang lắng nghe ở http://127.0.0.1:8080 (emulator dùng 10.0.2.2:8080).
void main() {
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL_TEST',
    defaultValue: 'http://127.0.0.1:8080',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AuthViewModel buildVm() {
    final api = ApiClient(baseUrl: baseUrl);
    return AuthViewModel(repo: AuthRepository(api: api));
  }

  test('backend mock đang chạy và trả /api/health', () async {
    final res = await ApiClient(baseUrl: baseUrl).get('/api/health');
    expect(res, isA<Map>());
    expect((res as Map)['status'], 'UP');
  });

  test('đăng ký email lần đầu thành công, lưu token + profile', () async {
    final vm = buildVm();
    final email = 'newuser_${DateTime.now().millisecondsSinceEpoch}@example.com';

    final ok = await vm.registerEmail(email, 'matkhau123', 'Nguyen Van A');

    expect(ok, isTrue, reason: 'lỗi: ${vm.error}');
    expect(vm.error, isNull);
    expect(vm.isLoggedIn, isTrue);
    expect(vm.token, isNotNull);
    expect(vm.token!.isNotEmpty, isTrue);
    expect(vm.email, email);
    expect(vm.displayName, 'Nguyen Van A');

    // Token phải được gửi kèm cho các request sau
    expect(vm.repo.api.token, vm.token);
  });

  test('đăng ký trùng email báo lỗi rõ ràng', () async {
    final vm = buildVm();
    final email = 'dup_${DateTime.now().millisecondsSinceEpoch}@example.com';

    expect(await vm.registerEmail(email, 'matkhau123', 'A'), isTrue);
    expect(await vm.registerEmail(email, 'matkhau123', 'B'), isFalse);
    expect(vm.error, contains('đã được đăng ký'));
  });

  test('đăng nhập email đúng thông tin trả token', () async {
    final vm = buildVm();
    final email = 'login_${DateTime.now().millisecondsSinceEpoch}@example.com';
    expect(await vm.registerEmail(email, 'matkhau123', 'B'), isTrue);

    final vm2 = buildVm();
    final ok = await vm2.loginEmail(email, 'matkhau123');

    expect(ok, isTrue, reason: 'lỗi: ${vm2.error}');
    expect(vm2.isLoggedIn, isTrue);
    expect(vm2.email, email);
    // Backend trả về displayName đã đăng ký -> app dùng luôn tên đó.
    expect(vm2.displayName, 'B');
  });

  test('đăng nhập sai mật khẩu báo lỗi, không đăng nhập', () async {
    final vm = buildVm();
    final email = 'wrongpw_${DateTime.now().millisecondsSinceEpoch}@example.com';
    expect(await vm.registerEmail(email, 'matkhau123', 'C'), isTrue);

    final vm2 = buildVm();
    final ok = await vm2.loginEmail(email, 'sai-mat-khau');

    expect(ok, isFalse);
    expect(vm2.isLoggedIn, isFalse);
    expect(vm2.error, isNotNull);
  });

  test('đăng nhập tài khoản chưa tồn tại báo lỗi', () async {
    final vm = buildVm();
    final ok = await vm.loginEmail('khong.tone@tao.com', 'matkhau123');
    expect(ok, isFalse);
    expect(vm.error, isNotNull);
  });

  test('token được lưu và khôi phục lại sau khi mở lại app', () async {
    final vm = buildVm();
    final email = 'persist_${DateTime.now().millisecondsSinceEpoch}@example.com';
    expect(await vm.registerEmail(email, 'matkhau123', 'D'), isTrue);
    final token = vm.token;

    // App khởi động lại -> loadSaved()
    final vm2 = buildVm();
    await vm2.loadSaved();

    expect(vm2.isLoggedIn, isTrue);
    expect(vm2.token, token);
    expect(vm2.email, email);
    expect(vm2.repo.api.token, token);
  });

  test('đăng xuất xoá token cục bộ', () async {
    final vm = buildVm();
    final email = 'logout_${DateTime.now().millisecondsSinceEpoch}@example.com';
    expect(await vm.registerEmail(email, 'matkhau123', 'E'), isTrue);

    await vm.logout();

    expect(vm.isLoggedIn, isFalse);
    expect(vm.token, isNull);
    expect(vm.repo.api.token, isNull);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('jwt'), isNull);
  });

  test('cập nhật hồ sơ gửi Bearer token và lưu lại tên', () async {
    final vm = buildVm();
    final email = 'profile_${DateTime.now().millisecondsSinceEpoch}@example.com';
    expect(await vm.registerEmail(email, 'matkhau123', 'Ten Cu'), isTrue);

    final ok = await vm.updateProfile('Ten Moi');

    expect(ok, isTrue, reason: 'lỗi: ${vm.error}');
    expect(vm.displayName, 'Ten Moi');
  });

  test('validate: email sai định dạng và mật khẩu ngắn bị chặn trước khi gọi API',
      () async {
    final vm = buildVm();

    expect(await vm.loginEmail('khong-phai-email', 'matkhau123'), isFalse);
    expect(vm.error, contains('Email'));

    expect(await vm.loginEmail('a@b.com', '123'), isFalse);
    expect(vm.error, contains('6 ký tự'));

    expect(await vm.registerEmail('a@b.com', 'matkhau123', '   '), isFalse);
    expect(vm.error, contains('tên hiển thị'));
  });

  test('đăng nhập Google: backend xác minh idToken và cấp JWT', () async {
    final api = ApiClient(baseUrl: baseUrl);
    // Mô phỏng bước app gửi idToken lên backend sau khi đã đăng nhập Google.
    final data = await api.post('/api/auth/google', {'idToken': 'fake-google-id-token'});
    expect(data, isA<Map>());
    expect((data as Map)['token'], isNotEmpty);
  });
}
