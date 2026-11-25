/// Danh sách loại sản phẩm (dùng cho Spinner / DropdownButtonFormField).
const List<String> kCategories = <String>[
  'Điện tử',
  'Thực phẩm',
  'Văn phòng phẩm',
  'Gia dụng',
  'Khác',
];

/// Ngưỡng cảnh báo sắp hết hàng: số lượng < 5.
const int kLowStockThreshold = 5;

/// Lớp biểu diễn một sản phẩm trong kho.
///
/// Tương ứng 1-1 với bảng `products` trong cơ sở dữ liệu SQLite.
class Product {
  /// Mã sản phẩm. `null` khi chưa được ghi vào cơ sở dữ liệu.
  final int? id;
  final String name;

  /// Giá bán (VNĐ), luôn lớn hơn 0.
  final int price;

  /// Số lượng tồn kho, không âm.
  final int quantity;
  final String category;

  /// true: đang kinh doanh, false: ngừng kinh doanh.
  final bool active;
  final String description;

  const Product({
    this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.category,
    this.active = true,
    this.description = '',
  });

  /// Giá trị tồn kho của riêng sản phẩm này = giá bán x số lượng.
  int get stockValue => price * quantity;

  /// Sắp hết hàng khi số lượng dưới 5.
  bool get isLowStock => quantity < kLowStockThreshold;

  /// Hết hàng hoàn toàn.
  bool get isOutOfStock => quantity <= 0;

  /// Chuyển thành Map để ghi xuống cơ sở dữ liệu (thay cho ContentValues).
  ///
  /// Không đưa `id` vào Map khi thêm mới để SQLite tự sinh AUTOINCREMENT.
  Map<String, Object?> toMap({bool includeId = false}) {
    return <String, Object?>{
      if (includeId && id != null) 'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'category': category,
      'active': active ? 1 : 0,
      'description': description,
    };
  }

  /// Dựng đối tượng từ một dòng truy vấn (thay cho việc đọc Cursor).
  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      price: (map['price'] as int?) ?? 0,
      quantity: (map['quantity'] as int?) ?? 0,
      category: (map['category'] as String?) ?? kCategories.last,
      active: ((map['active'] as int?) ?? 1) == 1,
      description: (map['description'] as String?) ?? '',
    );
  }

  Product copyWith({
    int? id,
    String? name,
    int? price,
    int? quantity,
    String? category,
    bool? active,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      active: active ?? this.active,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, qty: $quantity)';
}
