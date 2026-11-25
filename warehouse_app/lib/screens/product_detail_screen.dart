import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/product.dart';
import '../utils/currency.dart';
import '../widgets/product_tile.dart';

/// Màn hình 4: Chi tiết sản phẩm (tương ứng ProductDetailActivity).
///
/// Nhận id qua arguments của route (thay cho Intent extra) và truy vấn lại
/// cơ sở dữ liệu theo id để hiển thị thông tin.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  static const String routeName = '/detail';

  final int productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Product? _product;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  /// Truy vấn lại sản phẩm theo id.
  Future<void> _loadProduct() async {
    final Product? product = await _db.getProductById(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = product;
      _loading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// (5) Nhập thêm 1: tăng số lượng, ghi vào cơ sở dữ liệu rồi hiển thị lại.
  Future<void> _addOne() async {
    final Product? product = _product;
    if (product == null || _busy) return;

    setState(() => _busy = true);
    await _db.updateQuantity(product.id!, product.quantity + 1);
    await _loadProduct();
    if (!mounted) return;
    setState(() => _busy = false);
    _showMessage('Đã nhập thêm 1 ${product.name}');
  }

  /// (6) Bán 1: giảm số lượng; nếu đang bằng 0 thì báo "Hết hàng".
  Future<void> _sellOne() async {
    final Product? product = _product;
    if (product == null || _busy) return;

    if (product.quantity <= 0) {
      _showMessage('Hết hàng');
      return;
    }

    setState(() => _busy = true);
    await _db.updateQuantity(product.id!, product.quantity - 1);
    await _loadProduct();
    if (!mounted) return;
    setState(() => _busy = false);
    _showMessage('Đã bán 1 ${product.name}');
  }

  /// (8) Xóa sản phẩm khỏi cơ sở dữ liệu rồi quay lại danh sách.
  Future<void> _deleteProduct() async {
    final Product? product = _product;
    if (product == null || _busy) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Xóa "${product.name}" khỏi kho?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _db.deleteProduct(product.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa "${product.name}"')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _product == null
                ? const Center(child: Text('Không tìm thấy sản phẩm'))
                : _buildContent(_product!),
      ),
    );
  }

  Widget _buildContent(Product product) {
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // (1) Tên và loại sản phẩm
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    InfoChip(
                      label: product.category,
                      background:
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                      foreground: theme.colorScheme.primary,
                    ),
                    if (!product.active)
                      InfoChip(
                        label: 'Ngừng kinh doanh',
                        background: Colors.grey.shade200,
                        foreground: Colors.grey.shade700,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // (2) Giá bán, có dấu phân cách hàng nghìn
                Text(
                  formatCurrency(product.price),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const Divider(height: 28),

                // (3) Số lượng tồn và giá trị tồn kho
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Số lượng tồn kho',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: <Widget>[
                              Text(
                                '${product.quantity}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: product.isLowStock
                                      ? theme.colorScheme.error
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (product.isLowStock)
                                InfoChip(
                                  label: product.isOutOfStock
                                      ? 'Hết hàng'
                                      : 'Sắp hết hàng',
                                  background: theme.colorScheme.error
                                      .withValues(alpha: 0.12),
                                  foreground: theme.colorScheme.error,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Giá trị tồn kho',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatCurrency(product.stockValue),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // (4) Mô tả
                Text(
                  'Mô tả',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description.isEmpty
                      ? '(Không có mô tả)'
                      : product.description,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // (5)(6) Nhập thêm 1 / Bán 1
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : _addOne,
                  child: const Text('+ Nhập thêm 1'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF57C00),
                  ),
                  onPressed: _busy ? null : _sellOne,
                  child: const Text('- Bán 1'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // (7) Quay lại
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quay lại'),
          ),
        ),
        const SizedBox(height: 12),

        // (8) Xóa sản phẩm
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: _busy ? null : _deleteProduct,
            child: const Text('Xóa sản phẩm'),
          ),
        ),
      ],
    );
  }
}
