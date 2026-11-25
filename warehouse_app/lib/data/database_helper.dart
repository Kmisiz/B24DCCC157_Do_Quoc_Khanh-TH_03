import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';

/// Lớp truy cập cơ sở dữ liệu SQLite.
///
/// Tương đương `DatabaseHelper extends SQLiteOpenHelper` bên Android:
/// - `getDatabasesPath()` + `openDatabase()` thay cho constructor của helper.
/// - `onCreate` tạo bảng và chèn dữ liệu mẫu, đúng như `onCreate(SQLiteDatabase)`.
/// - `onUpgrade` xử lý nâng cấp phiên bản.
///
/// Toàn bộ dữ liệu được đọc/ghi trực tiếp từ cơ sở dữ liệu; `List<Product>`
/// chỉ dùng để chứa kết quả truy vấn đem lên giao diện.
class DatabaseHelper {
  static const String databaseName = 'warehouse.db';
  static const int databaseVersion = 1;

  static const String tableUsers = 'users';
  static const String tableProducts = 'products';

  /// Singleton: cả ứng dụng dùng chung một kết nối.
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final String path = p.join(await getDatabasesPath(), databaseName);
    return openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ---------------------------------------------------------------------
  // Tạo bảng + dữ liệu mẫu
  // ---------------------------------------------------------------------

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableProducts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        category TEXT NOT NULL,
        active INTEGER NOT NULL,
        description TEXT
      )
    ''');

    // Tài khoản mẫu: admin / 123456 (đề bài không yêu cầu mã hóa mật khẩu).
    await db.insert(tableUsers, <String, Object?>{
      'username': 'admin',
      'password': '123456',
    });

    // 3 sản phẩm mẫu theo mục 2.2 của đề bài.
    const List<Product> seed = <Product>[
      Product(
        name: 'Chuột không dây',
        price: 150000,
        quantity: 20,
        category: 'Điện tử',
        description: 'Chuột quang không dây 2.4GHz',
      ),
      Product(
        name: 'Bàn phím cơ',
        price: 450000,
        quantity: 3,
        category: 'Điện tử',
        description: 'Bàn phím cơ switch xanh, có đèn nền',
      ),
      Product(
        name: 'Sổ tay A5',
        price: 25000,
        quantity: 40,
        category: 'Văn phòng phẩm',
        description: 'Sổ tay bìa cứng 200 trang',
      ),
    ];

    final Batch batch = db.batch();
    for (final Product product in seed) {
      batch.insert(tableProducts, product.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Phiên bản hiện tại là 1 nên chưa có bước nâng cấp nào.
  }

  // ---------------------------------------------------------------------
  // Bảng users
  // ---------------------------------------------------------------------

  /// Trả về true nếu có dòng khớp trong bảng `users`.
  ///
  /// Dùng truy vấn tham số hóa (dấu ? + whereArgs) để tránh SQL injection.
  Future<bool> checkLogin(String username, String password) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tableUsers,
      columns: <String>['id'],
      where: 'username = ? AND password = ?',
      whereArgs: <Object?>[username, password],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  /// Thêm tài khoản mới vào bảng `users`.
  Future<int> insertUser(String username, String password) async {
    final Database db = await database;
    return db.insert(
      tableUsers,
      <String, Object?>{'username': username, 'password': password},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // ---------------------------------------------------------------------
  // Bảng products
  // ---------------------------------------------------------------------

  /// Thêm sản phẩm, trả về id vừa thêm.
  Future<int> insertProduct(Product product) async {
    final Database db = await database;
    return db.insert(tableProducts, product.toMap());
  }

  /// Lấy toàn bộ sản phẩm để hiển thị danh sách.
  Future<List<Product>> getAllProducts() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tableProducts,
      orderBy: 'id DESC',
    );
    return rows.map(Product.fromMap).toList();
  }

  /// Lấy một sản phẩm theo id. Trả về null nếu không tồn tại.
  Future<Product?> getProductById(int id) async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      tableProducts,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  /// Cập nhật số lượng (dùng cho Nhập thêm / Bán).
  Future<int> updateQuantity(int id, int quantity) async {
    final Database db = await database;
    return db.update(
      tableProducts,
      <String, Object?>{'quantity': quantity < 0 ? 0 : quantity},
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Xóa sản phẩm theo id.
  Future<int> deleteProduct(int id) async {
    final Database db = await database;
    return db.delete(
      tableProducts,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  // ---------------------------------------------------------------------
  // Thống kê (tính bằng truy vấn tổng hợp, không tính trên List)
  // ---------------------------------------------------------------------

  /// Tổng giá trị kho: SUM(price * quantity).
  Future<int> getTotalValue() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT SUM(price * quantity) AS total FROM $tableProducts',
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  /// Số sản phẩm sắp hết hàng: COUNT với quantity < 5.
  Future<int> countLowStock() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $tableProducts WHERE quantity < ?',
      <Object?>[kLowStockThreshold],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Tổng số sản phẩm trong kho.
  Future<int> countProducts() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM $tableProducts',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }
}
