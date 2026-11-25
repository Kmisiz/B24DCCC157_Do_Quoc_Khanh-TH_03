import 'package:intl/intl.dart';

final NumberFormat _decimal = NumberFormat.decimalPattern('vi');

/// Định dạng số có dấu phân cách hàng nghìn: 450000 -> "450.000".
String formatNumber(num value) => _decimal.format(value);

/// Định dạng tiền kèm đơn vị: 450000 -> "450.000 đ".
String formatCurrency(num value) => '${_decimal.format(value)} đ';
