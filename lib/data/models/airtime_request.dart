class AirtimeRequest {
  final String userId;
  final String network;
  final String amount;
  final String phoneNumber;
  final String pin;
  final bool saveBeneficiary;

  AirtimeRequest({
    required this.userId,
    required this.network,
    required this.amount,
    required this.phoneNumber,
    required this.pin,
    this.saveBeneficiary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'network': network,
      'amount': amount,
      'phoneNumber': phoneNumber,
      'pin': pin,
      'saveBeneficiary': saveBeneficiary,
    };
  }
}
