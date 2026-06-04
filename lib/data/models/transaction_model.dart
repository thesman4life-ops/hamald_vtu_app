import 'dart:convert';

class TransactionModel {
  final String? id;
  final String? type;
  final String? amount;
  final String? status;
  final String? date;
  final String? description;
  final String? reference;

  TransactionModel({
    this.id,
    this.type,
    this.amount,
    this.status,
    this.date,
    this.description,
    this.reference,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String? getString(List<String> keys) {
      for (var key in keys) {
        if (json[key] != null) return json[key].toString();
      }
      return null;
    }

    return TransactionModel(
      id: getString(['id', 'transaction_id', 'order_id']),
      type: getString(['type', 'service_type', 'service']),
      amount: getString(['amount', 'total_amount']),
      status: getString(['status', 'trans_status']),
      date: getString(['date', 'created_at', 'timestamp']),
      description: getString(['description', 'details', 'narration']),
      reference: getString(['reference', 'trans_ref', 'ref']),
    );
  }

  Map<String, String>? getDetails() {
    if (description == null || description!.isEmpty) return null;
    try {
      String jsonStr = description!.trim();
      if (!jsonStr.startsWith("{") || !jsonStr.endsWith("}")) {
        int start = jsonStr.indexOf("{");
        int end = jsonStr.lastIndexOf("}");
        if (start != -1 && end != -1 && end > start) {
          jsonStr = jsonStr.substring(start, end + 1);
        } else {
          return null;
        }
      }
      return Map<String, String>.from(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  bool get isInflow {
    final t = type?.toLowerCase() ?? "";
    final d = description?.toLowerCase() ?? "";
    return t.contains("fund") || t.contains("deposit") ||
           t.contains("refund") || t.contains("bonus") ||
           t.contains("topup") || t.contains("credit") ||
           t.contains("top-up") || t.contains("inflow") ||
           d.contains("fund") || d.contains("deposit") ||
           d.contains("refund") || d.contains("bonus") ||
           d.contains("credit") || d.contains("topup") ||
           d.contains("inflow");
  }

  bool get isSuccess {
    final s = status?.toLowerCase() ?? "";
    return s == "success" || s == "successful" || s == "000" || s == "approved";
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'status': status,
      'date': date,
      'description': description,
      'reference': reference,
    };
  }
}
