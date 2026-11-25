# Ứng dụng Quản lý kho hàng (Flutter + SQLite)

Bản triển khai bằng Flutter của đề bài *"Ứng dụng Quản lý kho hàng - lưu trữ dữ liệu bằng
cơ sở dữ liệu SQLite"*. Dữ liệu được lưu trong SQLite thuần qua gói `sqflite`
(không dùng Room, Firebase hay API).

> **Lưu ý về ràng buộc đề bài:** đề gốc yêu cầu Android native với Java + XML,
> `Intent` và `SQLiteOpenHelper`. Bản này giữ nguyên **toàn bộ nghiệp vụ, lược đồ
> cơ sở dữ liệu và danh sách phương thức DAO**, nhưng thay nền tảng bằng Flutter/Dart.

## Chạy thử

```bash
flutter pub get
flutter run            # cần máy ảo / thiết bị Android
flutter test           # 19 test cho model và lớp truy cập dữ liệu
```

## Cấu trúc mã nguồn

```
lib/
├── main.dart                        # MaterialApp, theme, khai báo route
├── models/product.dart              # Lớp Product (tên, giá, số lượng, loại, trạng thái, mô tả)
├── data/database_helper.dart        # Thay cho DatabaseHelper extends SQLiteOpenHelper
├── screens/
│   ├── login_screen.dart            # Màn hình 1 - LoginActivity
│   ├── product_list_screen.dart     # Màn hình 2 - MainActivity
│   ├── add_product_screen.dart      # Màn hình 3 - AddProductActivity
│   └── product_detail_screen.dart   # Màn hình 4 - ProductDetailActivity
├── widgets/
│   ├── stats_card.dart              # Khối thống kê kho
│   └── product_tile.dart            # Một dòng sản phẩm + nhãn chip
└── utils/currency.dart              # Định dạng số có dấu phân cách hàng nghìn
```

## Cơ sở dữ liệu

`warehouse.db`, phiên bản 1, tạo bảng và chèn dữ liệu mẫu trong `onCreate`.

| Bảng | Cột |
|---|---|
| `users` | `id` INTEGER PK AUTOINCREMENT, `username` TEXT NOT NULL UNIQUE, `password` TEXT NOT NULL |
| `products` | `id` INTEGER PK AUTOINCREMENT, `name` TEXT NOT NULL, `price` INTEGER NOT NULL, `quantity` INTEGER NOT NULL, `category` TEXT NOT NULL, `active` INTEGER NOT NULL, `description` TEXT |

Dữ liệu mẫu: tài khoản `admin` / `123456`; 3 sản phẩm (Chuột không dây, Bàn phím cơ,
Sổ tay A5) với `active = 1`.

### Các phương thức của `DatabaseHelper`

| Đề bài | Triển khai |
|---|---|
| `checkLogin(username, password)` | `Future<bool> checkLogin(String, String)` |
| `insertUser(username, password)` | `Future<int> insertUser(String, String)` |
| `insertProduct(Product p)` | `Future<int> insertProduct(Product)` |
| `getAllProducts()` | `Future<List<Product>> getAllProducts()` |
| `getProductById(int id)` | `Future<Product?> getProductById(int)` |
| `updateQuantity(int id, int quantity)` | `Future<int> updateQuantity(int, int)` |
| `deleteProduct(int id)` | `Future<int> deleteProduct(int)` |
| `getTotalValue()` | `Future<int> getTotalValue()` - `SUM(price * quantity)` |
| `countLowStock()` | `Future<int> countLowStock()` - `COUNT(*) WHERE quantity < 5` |
| *(bổ sung)* | `Future<int> countProducts()` - tổng số sản phẩm cho khối thống kê |

Mọi truy vấn đều tham số hóa bằng `?` + `whereArgs`/`arguments`.

## Ánh xạ khái niệm Android -> Flutter

| Android | Flutter trong dự án này |
|---|---|
| `Activity` | Màn hình (`StatefulWidget`) đăng ký theo route |
| `Intent.putExtra("id", id)` | `Navigator.pushNamed(..., arguments: id)` + `onGenerateRoute` |
| `startActivity()` + `finish()` | `Navigator.pushReplacementNamed()` sau khi đăng nhập |
| `onResume()` tải lại dữ liệu | `await Navigator.push(...)` rồi gọi `_reload()` |
| `SQLiteOpenHelper.onCreate` | `openDatabase(version: 1, onCreate: ...)` |
| `Cursor` | `List<Map<String, Object?>>`, không cần đóng thủ công |
| `ListView` + `BaseAdapter` | `ListView.builder` |
| `Spinner` | `DropdownButtonFormField<String>` |
| `Switch` | `SwitchListTile` |
| `EditText.setError()` | `Form` + `TextFormField.validator` |
| `Toast` | `SnackBar` |

## Nghiệp vụ đã cài đặt

- Đăng nhập kiểm tra bằng truy vấn bảng `users`; chặn khi bỏ trống; sai thì báo
  *"Sai tên đăng nhập hoặc mật khẩu"* và ở lại màn hình; đúng thì thay thế màn hình
  nên nút Back không quay lại đăng nhập.
- Danh sách hiển thị tên, giá bán, loại, số lượng; sản phẩm có `quantity < 5` hiện
  nhãn *"Sắp hết hàng"* và số lượng màu đỏ.
- Khối thống kê: tổng số sản phẩm, tổng giá trị kho `SUM(price * quantity)`, số sản
  phẩm sắp hết hàng; tải lại sau mỗi lần thêm, xóa hoặc đổi số lượng.
- Thêm sản phẩm: chặn tên rỗng, giá bán `<= 0` hoặc không phải số, số lượng âm hoặc
  không phải số nguyên; lưu xong quay về danh sách và cập nhật thống kê.
- Chi tiết: nhận id, truy vấn lại theo id; Nhập thêm 1 / Bán 1 ghi thẳng xuống cơ sở
  dữ liệu; bán khi số lượng bằng 0 thì báo *"Hết hàng"* và không giảm nữa; xóa sản
  phẩm có hỏi xác nhận rồi quay lại danh sách.
- Tắt hẳn ứng dụng rồi mở lại, dữ liệu thêm/sửa/xóa vẫn được giữ nguyên.

## Ghi chú kỹ thuật

- `WidgetsFlutterBinding.ensureInitialized()` được gọi trước khi mở cơ sở dữ liệu.
- `sqflite_common_ffi` chỉ dùng để chạy thử nhanh trên Windows/Linux và cho `flutter test`;
  trên Android ứng dụng dùng `sqflite` gốc.
- Mật khẩu lưu dạng văn bản thuần theo yêu cầu đề bài ("không yêu cầu mã hóa");
  sản phẩm thật cần băm mật khẩu (bcrypt/argon2).
- Khi đổi lược đồ bảng, gỡ cài đặt ứng dụng hoặc xóa `warehouse.db` để `onCreate`
  chạy lại, vì phiên bản cơ sở dữ liệu vẫn giữ là 1.
