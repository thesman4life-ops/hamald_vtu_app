class DataPlan {
  final String planId;
  final String planName;
  final String amount;
  final String originalPrice;
  final String duration;

  DataPlan({
    required this.planId,
    required this.planName,
    required this.amount,
    required this.originalPrice,
    required this.duration,
  });

  factory DataPlan.fromJson(Map<String, dynamic> json) {
    return DataPlan(
      planId: json['plan_id'] ?? json['variation_code'] ?? '',
      planName: json['plan_name'] ?? json['name'] ?? '',
      amount: json['amount'] ?? json['variation_amount'] ?? '0',
      originalPrice: json['original_price'] ?? json['amount'] ?? '0',
      duration: json['duration'] ?? '',
    );
  }
}
