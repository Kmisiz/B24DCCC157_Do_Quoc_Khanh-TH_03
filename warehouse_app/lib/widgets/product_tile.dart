import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/currency.dart';

/// Nhãn nhỏ dạng viên thuốc (chip) dùng cho loại sản phẩm / cảnh báo.
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Một dòng sản phẩm trong danh sách (thành phần số 2, mục 2.2).
///
/// Hiển thị tên, giá bán, loại và số lượng. Sản phẩm sắp hết hàng
/// (số lượng < 5) có nhãn cảnh báo và số lượng màu đỏ.
class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool low = product.isLowStock;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SL: ${product.quantity}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      // Số lượng màu đỏ khi sắp hết hàng.
                      color: low ? theme.colorScheme.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Giá bán: ${formatCurrency(product.price)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  InfoChip(
                    label: product.category,
                    background: theme.colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                    foreground: theme.colorScheme.primary,
                  ),
                  if (low)
                    InfoChip(
                      label: 'Sắp hết hàng',
                      background: theme.colorScheme.error.withValues(
                        alpha: 0.12,
                      ),
                      foreground: theme.colorScheme.error,
                    ),
                  if (!product.active)
                    InfoChip(
                      label: 'Ngừng kinh doanh',
                      background: Colors.grey.shade200,
                      foreground: Colors.grey.shade700,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
