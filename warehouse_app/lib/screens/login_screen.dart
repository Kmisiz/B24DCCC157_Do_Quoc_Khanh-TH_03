import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import 'product_list_screen.dart';

/// Màn hình 1: Đăng nhập (tương ứng LoginActivity).
///
/// Kiểm tra tài khoản bằng truy vấn bảng `users` trong cơ sở dữ liệu,
/// không gán cứng trong mã nguồn của màn hình.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  /// Màn hình gốc của ứng dụng.
  static const String routeName = '/';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// Thông báo lỗi (thành phần số 3) - null nghĩa là chưa có lỗi nên ẩn đi.
  String? _errorMessage;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Kiểm tra đăng nhập với bảng `users`.
  Future<void> _checkLogin() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;

    // Không cho phép đăng nhập khi bỏ trống.
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final bool ok = await DatabaseHelper.instance.checkLogin(
      username,
      password,
    );

    if (!mounted) return;

    if (ok) {
      // Thay thế màn hình hiện tại để nút Back không quay lại đăng nhập
      // (tương đương startActivity + finish() bên Android).
      Navigator.of(context).pushReplacementNamed(ProductListScreen.routeName);
    } else {
      setState(() {
        _loading = false;
        _errorMessage = 'Sai tên đăng nhập hoặc mật khẩu';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo tròn "SP"
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Text(
                      'SP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Quản lý kho hàng',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đăng nhập để tiếp tục',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // (1) Tên đăng nhập
                const Text(
                  'Tên đăng nhập',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tên đăng nhập',
                  ),
                ),
                const SizedBox(height: 16),

                // (2) Mật khẩu - ẩn ký tự khi nhập
                const Text(
                  'Mật khẩu',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _checkLogin(),
                  decoration: const InputDecoration(
                    hintText: 'Nhập mật khẩu',
                  ),
                ),

                // (3) Thông báo lỗi - chỉ hiện khi có lỗi
                if (_errorMessage != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),

                // (4) Nút Đăng nhập
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading ? null : _checkLogin,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Đăng nhập'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tài khoản mẫu: admin / 123456',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
