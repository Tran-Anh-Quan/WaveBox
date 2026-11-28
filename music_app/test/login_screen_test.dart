import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/network/api_client.dart';
import 'package:music_app/features/auth/data/auth_repository.dart';
import 'package:music_app/features/auth/view/login_screen.dart';
import 'package:music_app/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// API giả lập trả về đúng format backend Spring Boot, để test UI
/// (validate, hiển thị lỗi, điều hướng sau khi thành công).
/// Phần giao tiếp HTTP thật được kiểm chứng ở test/auth_flow_test.dart.
class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'http://fake.local');
  final Map<String, String> users = {};

  @override
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    if (path == '/api/auth/register') {
      final email = (body['email'] as String).toLowerCase();
      if (users.containsKey(email)) {
        throw Exception('HTTP 409: Email da duoc dang ky');
      }
      users[email] = body['password'] as String;
      return {
        'token': 'jwt-$email',
        'user': {'email': email, 'displayName': body['displayName']},
      };
    }
    if (path == '/api/auth/login') {
      final email = (body['email'] as String).toLowerCase();
      if (users[email] != body['password']) {
        throw Exception('HTTP 401: Sai email hoac mat khau');
      }
      return {
        'token': 'jwt-$email',
        'user': {'email': email},
      };
    }
    throw Exception('HTTP 404');
  }

  @override
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    return {'user': body};
  }
}

/// Test màn hình Login/Register (UC 8.x).
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AuthViewModel buildVm([FakeApiClient? api]) {
    final client = api ?? FakeApiClient();
    return AuthViewModel(repo: AuthRepository(api: client));
  }

  Widget buildApp(AuthViewModel vm) {
    return ChangeNotifierProvider<AuthViewModel>.value(
      value: vm,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('bấm "Chưa có tài khoản? Đăng ký" chuyển sang form đăng ký',
      (tester) async {
    final vm = buildVm();
    await tester.pumpWidget(buildApp(vm));

    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Tên hiển thị'), findsOneWidget);
  });

  testWidgets('đăng ký qua UI thành công thì quay lại màn hình trước',
      (tester) async {
    final api = FakeApiClient();
    final vm = buildVm(api);
    var popped = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: vm,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                  popped = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Tên hiển thị'), 'Test UI');
    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'ui@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Mật khẩu'), 'matkhau123');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký'));
    await tester.pumpAndSettle();

    expect(vm.isLoggedIn, isTrue, reason: 'lỗi hiển thị: ${vm.error}');
    expect(vm.email, 'ui@example.com');
    expect(vm.displayName, 'Test UI');
    expect(popped, isTrue, reason: 'phải quay lại màn hình trước');
  });

  testWidgets('đăng ký trùng email hiện thông báo lỗi trên UI', (tester) async {
    final api = FakeApiClient();
    final vm = buildVm(api);
    // Đẩy LoginScreen bằng Navigator.push để sau khi đăng ký thành công
    // lệnh Navigator.pop trong màn hình không làm trống cây widget.
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
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
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();

    Future<void> fill(String email) async {
      await tester.enterText(
          find.widgetWithText(TextField, 'Tên hiển thị'), 'Test UI');
      await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
      await tester.enterText(
          find.widgetWithText(TextField, 'Mật khẩu'), 'matkhau123');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng ký'));
      await tester.pumpAndSettle();
    }

    // Lần 1: đăng ký mới -> thành công, màn hình tự đóng lại
    await fill('trung@example.com');
    expect(vm.isLoggedIn, isTrue);

    // Lần 2: mở lại màn hình và đăng ký lại cùng email -> phải báo lỗi
    // (vm.isRegisterMode vẫn giữ nguyên nên không cần bấm lại nút chuyển mode)
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await fill('trung@example.com');
    expect(vm.error, contains('đã được đăng ký'));
    expect(find.textContaining('đã được đăng ký'), findsOneWidget);
  });

  testWidgets('đăng nhập sai mật khẩu hiện thông báo lỗi trên UI',
      (tester) async {
    final api = FakeApiClient();
    final vm = buildVm(api);
    await tester.pumpWidget(buildApp(vm));

    api.users['sai@example.com'] = 'matkhau123';

    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'sai@example.com');
    await tester.enterText(
        find.widgetWithText(TextField, 'Mật khẩu'), 'sai-mat-khau');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(vm.isLoggedIn, isFalse);
    expect(find.textContaining('Sai email hoặc mật khẩu'), findsOneWidget);
  });

  testWidgets('bấm "Đăng nhập" khi form trống hiện lỗi validate, không gọi API',
      (tester) async {
    final vm = buildVm();
    await tester.pumpWidget(buildApp(vm));

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(vm.isLoggedIn, isFalse);
    expect(find.textContaining('Vui lòng nhập email'), findsOneWidget);
  });

  testWidgets('mật khẩu dưới 6 ký tự bị chặn ngay trên UI', (tester) async {
    final vm = buildVm();
    await tester.pumpWidget(buildApp(vm));

    await tester.enterText(
        find.widgetWithText(TextField, 'Email'), 'a@b.com');
    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu'), '123');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(vm.isLoggedIn, isFalse);
    expect(vm.error, contains('6 ký tự'));
    // Khớp chính xác để không đếm nhầm hint "Tối thiểu 6 ký tự" của ô mật khẩu.
    expect(find.text('Mật khẩu phải có ít nhất 6 ký tự'), findsOneWidget);
  });
}
