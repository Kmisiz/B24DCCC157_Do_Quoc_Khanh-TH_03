import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/product.dart';
import '../widgets/product_tile.dart';
import '../widgets/stats_card.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

/// Gói dữ liệu một lần tải màn hình danh sách: danh sách + 3 chỉ số thống kê.
class _WarehouseData {
  const _WarehouseData({
    required this.products,
    required this.totalProducts,
    required this.totalValue,
    required this.lowStockCount,
  });

  final List<Product> products;
  final int totalProducts;
  final int totalValue;
  final int lowStockCount;
}

/// Màn hình 2: Danh sách sản phẩm (tương ứng MainActivity).
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  static const String routeName = '/products';

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late Future<_WarehouseData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Đọc lại toàn bộ dữ liệu từ cơ sở dữ liệu.
  ///
  /// Thống kê được tính bằng truy vấn tổng hợp (SUM/COUNT), không tính
  /// trên danh sách trong bộ nhớ.
  Future<_WarehouseData> _load() async {
    final List<Product> products = await _db.getAllProducts();
    final int totalProducts = await _db.countProducts();
    final int totalValue = await _db.getTotalValue();
    final int lowStockCount = await _db.countLowStock();

    return _WarehouseData(
      products: products,
      totalProducts: totalProducts,
      totalValue: totalValue,
      lowStockCount: lowStockCount,
    );
  }

  /// Tải lại danh sách và thống kê (vai trò của onResume bên Android).
  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  /// Mở màn hình thêm sản phẩm, tải lại danh sách khi quay về.
  Future<void> _openAddProduct() async {
    await Navigator.of(context).pushNamed(AddProductScreen.routeName);
    _reload();
  }

  /// Mở màn hình chi tiết, chỉ truyền id; màn hình chi tiết tự truy vấn lại.
  Future<void> _openDetail(int id) async {
    await Navigator.of(context).pushNamed(
      ProductDetailScreen.routeName,
      arguments: id,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kho hàng của tôi')),
      body: SafeArea(
        child: FutureBuilder<_WarehouseData>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<_WarehouseData> snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Lỗi đọc dữ liệu: ${snap.error}'));
            }

            final _WarehouseData data = snap.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // (1) Khối thống kê
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: StatsCard(
                    totalProducts: data.totalProducts,
                    totalValue: data.totalValue,
                    lowStockCount: data.lowStockCount,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Danh sách sản phẩm',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),

                // (2) Danh sách sản phẩm
                Expanded(
                  child: data.products.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: data.products.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Product product = data.products[index];
                            return ProductTile(
                              product: product,
                              onTap: () => _openDetail(product.id!),
                            );
                          },
                        ),
                ),

                // (3) Nút Thêm sản phẩm
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openAddProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm sản phẩm'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Xử lý trường hợp danh sách rỗng.
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Kho chưa có sản phẩm nào',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
