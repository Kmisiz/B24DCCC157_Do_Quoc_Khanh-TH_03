import 'package:flutter/material.dart';

import '../utils/currency.dart';

/// Khối thống kê kho ở đầu màn hình danh sách (thành phần số 1, mục 2.2).
///
/// Hiển thị tổng số sản phẩm, tổng giá trị kho và số sản phẩm sắp hết hàng.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.totalProducts,
    required this.totalValue,
    required this.lowStockCount,
  });

  final int totalProducts;
  final int totalValue;
  final int lowStockCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Thống kê kho',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _StatItem(value: '$totalProducts', label: 'Sản phẩm'),
              const SizedBox(width: 16),
              _StatItem(
                value: formatCurrency(totalValue),
                label: 'Giá trị kho',
                flex: 2,
              ),
              const SizedBox(width: 16),
              _StatItem(value: '$lowStockCount', label: 'Sắp hết hàng'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    this.flex = 1,
  });

  final String value;
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
