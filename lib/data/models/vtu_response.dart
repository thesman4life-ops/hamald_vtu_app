class VTUResponse {
  final String? status;
  final String? message;
  final String? transactionId;
  final String? token;
  final String? units;

  VTUResponse({
    this.status,
    this.message,
    this.transactionId,
    this.token,
    this.units,
  });

  factory VTUResponse.fromJson(Map<String, dynamic> json) {
    return VTUResponse(
      status: json['status']?.toString(),
      message: json['message']?.toString(),
      transactionId: (json['transactionId'] ?? json['requestId'] ?? json['reference'])?.toString(),
      token: json['token']?.toString() ?? json['purchased_code']?.toString(),
      units: json['units']?.toString(),
    );
  }

  bool get isSuccess => status?.toLowerCase() == 'success' || status == '000';
}
