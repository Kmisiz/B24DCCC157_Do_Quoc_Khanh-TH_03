import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database_helper.dart';
import '../models/product.dart';

/// Màn hình 3: Thêm sản phẩm (tương ứng AddProductActivity).
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  static const String routeName = '/add';

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _category = kCategories.first;
  bool _active = true; // (5) Đang kinh doanh - mặc định bật
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Kiểm tra dữ liệu rồi lưu sản phẩm vào cơ sở dữ liệu.
  Future<void> _saveProduct() async {
    // validator của Form đóng vai trò setError bên Android.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final Product product = Product(
      name: _nameController.text.trim(),
      price: int.parse(_priceController.text.trim()),
      quantity: int.parse(_quantityController.text.trim()),
      category: _category,
      active: _active,
      description: _descriptionController.text.trim(),
    );

    await DatabaseHelper.instance.insertProduct(product);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm "${product.name}" vào kho')),
    );
    // Trả về true để màn hình danh sách biết cần tải lại.
    Navigator.of(context).pop(true);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tên sản phẩm không được để trống';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Giá bán không được để trống';
    final int? price = int.tryParse(text);
    if (price == null) return 'Giá bán phải là số';
    if (price <= 0) return 'Giá bán phải lớn hơn 0';
    return null;
  }

  String? _validateQuantity(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Số lượng không được để trống';
    final int? quantity = int.tryParse(text);
    if (quantity == null) return 'Số lượng phải là số nguyên';
    if (quantity < 0) return 'Số lượng không được âm';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm sản phẩm')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              // (1) Tên sản phẩm
              _label('Tên sản phẩm'),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                validator: _validateName,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: Tai nghe Bluetooth',
                ),
              ),
              const SizedBox(height: 16),

              // (2) Giá bán - chỉ nhập số
              _label('Giá bán (VNĐ)'),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textInputAction: TextInputAction.next,
                validator: _validatePrice,
                decoration: const InputDecoration(
                  hintText: 'Chỉ nhập số, ví dụ: 250000',
                ),
              ),
              const SizedBox(height: 16),

              // (3) Số lượng - chỉ nhập số nguyên
              _label('Số lượng'),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                textInputAction: TextInputAction.next,
                validator: _validateQuantity,
                decoration: const InputDecoration(
                  hintText: 'Chỉ nhập số nguyên, ví dụ: 10',
                ),
              ),
              const SizedBox(height: 16),

              // (4) Loại sản phẩm
              _label('Loại sản phẩm'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: kCategories
                    .map(
                      (String c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 8),

              // (5) Đang kinh doanh
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Đang kinh doanh',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: _active,
                onChanged: (bool value) => setState(() => _active = value),
              ),
              const SizedBox(height: 8),

              // (6) Mô tả - nhiều dòng, không bắt buộc
              _label('Mô tả'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Nhập mô tả (nhiều dòng)...',
                ),
              ),
              const SizedBox(height: 24),

              // (7) Nút Lưu sản phẩm
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _saveProduct,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lưu sản phẩm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
