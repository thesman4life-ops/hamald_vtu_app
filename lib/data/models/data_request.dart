class DataRequest {
  final String userId;
  final String network;
  final String planId;
  final String amount;
  final String phoneNumber;
  final String pin;
  final bool saveBeneficiary;

  DataRequest({
    required this.userId,
    required this.network,
    required this.planId,
    required this.amount,
    required this.phoneNumber,
    required this.pin,
    this.saveBeneficiary = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'network': network,
      'planId': planId,
      'amount': amount,
      'phoneNumber': phoneNumber,
      'pin': pin,
      'saveBeneficiary': saveBeneficiary,
    };
  }
}
