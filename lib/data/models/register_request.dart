class RegisterRequest {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String referralCode;
  final String deviceId;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.referralCode,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phone,
      'password': password,
      'referralCode': referralCode,
      'deviceId': deviceId,
    };
  }
}
