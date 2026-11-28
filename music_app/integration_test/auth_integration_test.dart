import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:music_app/core/network/api_client.dart';
import 'package:music_app/features/auth/data/auth_repository.dart';
import 'package:music_app/features/auth/view/login_screen.dart';
import 'package:music_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kiểm thử tích hợp UC 8.x trên thiết bị Android thật (emulator).
/// Chạy backend mock ở máy host; emulator truy cập qua 10.0.2.2:8080.
///
/// Lệnh chạy:
///   python mock_backend.py
///   cd music_app && flutter test integration_test/auth_integration_test.dart \
///     -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Đẩy LoginScreen bằng Navigator.push để lệnh Navigator.pop sau khi
  /// đăng nhập thành công không làm trống cây widget trong test.
  Widget buildApp(AuthViewModel vm) {
    return ChangeNotifierProvider<AuthViewModel>.value(
      value: vm,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openLoginScreen(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String buttonLabel) async {
    await tester.ensureVisible(find.widgetWithText(FilledButton, buttonLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, buttonLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('đăng ký trên thiết bị thật với backend thật', (tester) async {
    final vm = AuthViewModel(
        repo: AuthRepository(api: ApiClient(baseUrl: baseUrl)));

    await tester.pumpWidget(buildApp(vm));
    await tester.pumpAndSettle();
    await openLoginScreen(tester);

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản'), findsOneWidget);

    final email = 'device_${DateTime.now().millisecondsSinceEpoch}@example.com';

    await tester.enterText(
        find.widgetWithText(TextField, 'Tên hiển thị'), 'Nguoi Dung');
    await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextField, 'Mật khẩu'), 'matkhau123');
    await tester.pump();

    await submit(tester, 'Đăng ký');

    expect(vm.isLoggedIn, isTrue,
        reason: 'đăng ký trên thiết bị thật thất bại: ${vm.error}');
    expect(vm.email, email);
    expect(vm.token, isNotNull);

    // Token phải được lưu xuống SharedPreferences trên thiết bị
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('jwt'), vm.token);
    expect(prefs.getString('email'), email);
  });

  testWidgets('đăng nhập trên thiết bị thật với backend thật', (tester) async {
    // Tạo tài khoản sẵn qua API rồi thao tác đăng nhập trên UI
    final email = 'devicelogin_${DateTime.now().millisecondsSinceEpoch}@example.com';
    await ApiClient(baseUrl: baseUrl).post('/api/auth/register', {
      'email': email,
      'password': 'matkhau123',
      'displayName': 'Nguoi Dung',
    });

    final vm = AuthViewModel(
        repo: AuthRepository(api: ApiClient(baseUrl: baseUrl)));

    await tester.pumpWidget(buildApp(vm));
    await tester.pumpAndSettle();
    await openLoginScreen(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
    await tester.enterText(
        find.widgetWithText(TextField, 'Mật khẩu'), 'matkhau123');
    await tester.pump();

    await submit(tester, 'Đăng nhập');

    expect(vm.isLoggedIn, isTrue,
        reason: 'đăng nhập trên thiết bị thật thất bại: ${vm.error}');
    expect(vm.email, email);
  });

  testWidgets('đăng nhập sai mật khẩu hiện lỗi trên thiết bị thật',
      (tester) async {
    final vm = AuthViewModel(
        repo: AuthRepository(api: ApiClient(baseUrl: baseUrl)));

    await tester.pumpWidget(buildApp(vm));
    await tester.pumpAndSettle();
    await openLoginScreen(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Email'),
        'khongco@tronghe.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Mật khẩu'), 'matkhau123');
    await tester.pump();

    await submit(tester, 'Đăng nhập');

    expect(vm.isLoggedIn, isFalse);
    expect(find.textContaining('Sai email hoặc mật khẩu'), findsOneWidget);
  });
}
