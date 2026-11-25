import 'package:flutter_test/flutter_test.dart';
import 'package:warehouse_app/models/product.dart';

void main() {
  group('Product', () {
    const Product keyboard = Product(
      id: 2,
      name: 'Bàn phím cơ',
      price: 450000,
      quantity: 3,
      category: 'Điện tử',
      description: 'Switch xanh',
    );

    test('stockValue = price * quantity', () {
      expect(keyboard.stockValue, 1350000);
    });

    test('isLowStock đúng khi số lượng < 5', () {
      expect(keyboard.isLowStock, isTrue);
      expect(keyboard.copyWith(quantity: 5).isLowStock, isFalse);
      expect(keyboard.copyWith(quantity: 4).isLowStock, isTrue);
    });

    test('isOutOfStock đúng khi số lượng = 0', () {
      expect(keyboard.copyWith(quantity: 0).isOutOfStock, isTrue);
      expect(keyboard.copyWith(quantity: 1).isOutOfStock, isFalse);
    });

    test('toMap không kèm id khi thêm mới', () {
      final Map<String, Object?> map = keyboard.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map['active'], 1);
      expect(map['price'], 450000);
    });

    test('fromMap/toMap chuyển đổi qua lại đúng', () {
      final Product parsed = Product.fromMap(keyboard.toMap(includeId: true));
      expect(parsed.id, keyboard.id);
      expect(parsed.name, keyboard.name);
      expect(parsed.price, keyboard.price);
      expect(parsed.quantity, keyboard.quantity);
      expect(parsed.category, keyboard.category);
      expect(parsed.active, keyboard.active);
      expect(parsed.description, keyboard.description);
    });

    test('fromMap xử lý active = 0 và description null', () {
      final Product parsed = Product.fromMap(<String, Object?>{
        'id': 9,
        'name': 'Nồi cơm',
        'price': 500000,
        'quantity': 2,
        'category': 'Gia dụng',
        'active': 0,
        'description': null,
      });
      expect(parsed.active, isFalse);
      expect(parsed.description, '');
    });
  });
}
