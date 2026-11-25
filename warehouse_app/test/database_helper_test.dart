import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:warehouse_app/data/database_helper.dart';
import 'package:warehouse_app/models/product.dart';

/// Kiểm thử lớp DatabaseHelper trên nền sqflite FFI (chạy được trên máy tính,
/// cùng một engine SQLite như trên Android).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final DatabaseHelper db = DatabaseHelper.instance;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Xóa cơ sở dữ liệu cũ để onCreate chạy lại và chèn dữ liệu mẫu.
    final String path = p.join(
      await getDatabasesPath(),
      DatabaseHelper.databaseName,
    );
    await deleteDatabase(path);
  });

  group('Dữ liệu mẫu trong onCreate', () {
    test('chèn sẵn tài khoản admin / 123456', () async {
      expect(await db.checkLogin('admin', '123456'), isTrue);
    });

    test('từ chối sai mật khẩu và sai tên đăng nhập', () async {
      expect(await db.checkLogin('admin', 'sai'), isFalse);
      expect(await db.checkLogin('khong-ton-tai', '123456'), isFalse);
    });

    test('chèn sẵn 3 sản phẩm mẫu', () async {
      final List<Product> products = await db.getAllProducts();
      expect(products.length, 3);
      expect(
        products.map((Product e) => e.name),
        containsAll(<String>['Chuột không dây', 'Bàn phím cơ', 'Sổ tay A5']),
      );
    });

    test('thống kê khớp dữ liệu mẫu', () async {
      // 150000*20 + 450000*3 + 25000*40 = 3.000.000 + 1.350.000 + 1.000.000
      expect(await db.getTotalValue(), 5350000);
      expect(await db.countProducts(), 3);
      // Chỉ "Bàn phím cơ" có số lượng 3 < 5.
      expect(await db.countLowStock(), 1);
    });
  });

  group('Vòng đời một sản phẩm', () {
    late int newId;

    test('insertProduct trả về id và ghi đúng dữ liệu', () async {
      newId = await db.insertProduct(
        const Product(
          name: 'Tai nghe Bluetooth',
          price: 250000,
          quantity: 10,
          category: 'Điện tử',
          description: 'Chống ồn chủ động',
        ),
      );
      expect(newId, greaterThan(0));

      final Product? saved = await db.getProductById(newId);
      expect(saved, isNotNull);
      expect(saved!.name, 'Tai nghe Bluetooth');
      expect(saved.price, 250000);
      expect(saved.quantity, 10);
      expect(saved.active, isTrue);
      expect(saved.stockValue, 2500000);
    });

    test('thống kê cập nhật sau khi thêm', () async {
      expect(await db.countProducts(), 4);
      expect(await db.getTotalValue(), 5350000 + 2500000);
    });

    test('updateQuantity ghi số lượng mới (Nhập thêm / Bán)', () async {
      await db.updateQuantity(newId, 11);
      expect((await db.getProductById(newId))!.quantity, 11);

      await db.updateQuantity(newId, 10);
      expect((await db.getProductById(newId))!.quantity, 10);
    });

    test('updateQuantity không cho số lượng âm', () async {
      await db.updateQuantity(newId, -3);
      expect((await db.getProductById(newId))!.quantity, 0);
      await db.updateQuantity(newId, 10);
    });

    test('countLowStock đếm đúng khi số lượng xuống dưới 5', () async {
      await db.updateQuantity(newId, 4);
      expect(await db.countLowStock(), 2);
      await db.updateQuantity(newId, 10);
      expect(await db.countLowStock(), 1);
    });

    test('deleteProduct xóa khỏi cơ sở dữ liệu', () async {
      expect(await db.deleteProduct(newId), 1);
      expect(await db.getProductById(newId), isNull);
      expect(await db.countProducts(), 3);
      expect(await db.getTotalValue(), 5350000);
    });
  });

  group('Bảng users', () {
    test('insertUser thêm được tài khoản mới', () async {
      await db.insertUser('nhanvien', 'abc123');
      expect(await db.checkLogin('nhanvien', 'abc123'), isTrue);
    });

    test('username trùng bị bỏ qua, không làm hỏng dữ liệu cũ', () async {
      await db.insertUser('admin', 'mat-khau-khac');
      expect(await db.checkLogin('admin', '123456'), isTrue);
      expect(await db.checkLogin('admin', 'mat-khau-khac'), isFalse);
    });
  });

  group('Trường hợp rỗng', () {
    test('getProductById với id không tồn tại trả về null', () async {
      expect(await db.getProductById(99999), isNull);
    });
  });
}
