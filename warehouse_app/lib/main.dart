import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/add_product_screen.dart';
import 'screens/login_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_list_screen.dart';

/// Màu chủ đạo theo bản phác thảo giao diện trong đề bài.
const Color kPrimaryColor = Color(0xFF00796B);

void main() {
  // Bắt buộc gọi trước khi mở cơ sở dữ liệu trong main().
  WidgetsFlutterBinding.ensureInitialized();

  // Trên Windows/Linux, sqflite cần nền tảng FFI (chỉ phục vụ chạy thử nhanh
  // trên máy tính; trên Android/iOS dùng sqflite gốc, không cần bước này).
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      primary: kPrimaryColor,
      error: const Color(0xFFD32F2F),
    );

    return MaterialApp(
      title: 'Quản lý kho hàng',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: const StadiumBorder(),
            side: BorderSide(color: colorScheme.primary),
            foregroundColor: colorScheme.primary,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      // Màn hình gốc '/' là Đăng nhập, nên nút Back tại đây sẽ thoát ứng
      // dụng chứ không rơi vào màn hình khác.
      initialRoute: LoginScreen.routeName,
      routes: <String, WidgetBuilder>{
        LoginScreen.routeName: (_) => const LoginScreen(),
        ProductListScreen.routeName: (_) => const ProductListScreen(),
        AddProductScreen.routeName: (_) => const AddProductScreen(),
      },

      // Route chi tiết nhận id qua arguments (thay cho Intent.putExtra).
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == ProductDetailScreen.routeName) {
          final int productId = settings.arguments as int;
          return MaterialPageRoute<bool>(
            builder: (_) => ProductDetailScreen(productId: productId),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
