import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodel/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: dark
              ? AppTheme.playerGradient
              : const LinearGradient(
                  colors: [Color(0xFFEDE9FE), Color(0xFFF6F3FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: vm.toggleMode,
                          child: Text(vm.isRegisterMode
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Đăng ký'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: AppTheme.gradientBox(radius: 24),
                        child: const Icon(Icons.graphic_eq_rounded,
                            color: Colors.white, size: 42),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      vm.isRegisterMode ? 'Tạo tài khoản' : 'Chào mừng trở lại',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      vm.isRegisterMode
                          ? 'Đăng ký để đồng bộ playlist, yêu thích và lịch sử trên mọi thiết bị'
                          : 'Đăng nhập để mở khóa nội dung online và đồng bộ dữ liệu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: dark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                          height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.softCard(context, radius: 24),
                      child: Column(
                        children: [
                          if (vm.isRegisterMode)
                            TextField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Tên hiển thị',
                                hintText: 'Ví dụ: Minh Anh',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                            ),
                          if (vm.isRegisterMode) const SizedBox(height: 12),
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'ban@example.com',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _pass,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              hintText: 'Tối thiểu 6 ký tự',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          if (vm.error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(vm.error!,
                                        style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: vm.loading
                                  ? null
                                  : () async {
                                      final ok = vm.isRegisterMode
                                          ? await vm.registerEmail(
                                              _email.text.trim(),
                                              _pass.text,
                                              _name.text.trim())
                                          : await vm.loginEmail(
                                              _email.text.trim(), _pass.text);
                                      if (ok && context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(vm.loading
                                    ? 'Đang xử lý...'
                                    : (vm.isRegisterMode
                                        ? 'Đăng ký'
                                        : 'Đăng nhập')),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: vm.loading
                                  ? null
                                  : () async {
                                      final ok = await vm.loginGoogle();
                                      if (ok && context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                              icon: const Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 22),
                              label:
                                  const Text('Tiếp tục với Google'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Chưa chạy backend vẫn dùng được nhạc offline trên máy.',
                      style: TextStyle(
                          fontSize: 11,
                          color: dark ? Colors.white38 : Colors.black38),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
