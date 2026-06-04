class BankModel {
  final String name;
  final String code;

  BankModel({required this.name, required this.code});

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}
