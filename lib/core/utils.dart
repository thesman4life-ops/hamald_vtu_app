import 'package:intl/intl.dart';

class Utils {
  static String formatCurrency(dynamic amount) {
    if (amount == null) return "0.00";
    double value = 0.0;
    if (amount is String) {
      value = double.tryParse(amount.replaceAll(',', '').replaceAll('₦', '').trim()) ?? 0.0;
    } else if (amount is num) {
      value = amount.toDouble();
    }
    return NumberFormat("#,##0.00").format(value);
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Enter phone number';
    if (value.length < 11) return 'Invalid phone number';
    return null;
  }
}
