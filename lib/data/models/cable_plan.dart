class CablePlan {
  final String variationCode;
  final String name;
  final String originalPrice;
  final String amount;

  CablePlan({
    required this.variationCode,
    required this.name,
    required this.originalPrice,
    required this.amount,
  });

  factory CablePlan.fromJson(Map<String, dynamic> json) {
    return CablePlan(
      variationCode: json['variation_code'] ?? '',
      name: json['name'] ?? '',
      originalPrice: json['original_price'] ?? json['variation_amount'] ?? '0',
      amount: json['variation_amount'] ?? '0',
    );
  }
}
