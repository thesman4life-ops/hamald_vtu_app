import 'transaction_model.dart';

class UserModel {
  final String? status;
  final String? userId;
  final String? email;
  final String? walletBalance;
  final String? fullName;
  final String? message;
  final String? profilePic;
  final String? transactionPin;
  final String? phone;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final bool otpRequired;
  final String? userLevel;
  final double creditLimit;
  final double outstandingDebt;
  final double totalSpent;
  final List<TransactionModel> transactions;

  UserModel({
    this.status,
    this.userId,
    this.email,
    this.walletBalance,
    this.fullName,
    this.message,
    this.profilePic,
    this.transactionPin,
    this.phone,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.otpRequired = false,
    this.userLevel,
    this.creditLimit = 0.0,
    this.outstandingDebt = 0.0,
    this.totalSpent = 0.0,
    this.transactions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Helper to get nested or alternate fields
    String? getString(List<String> keys) {
      for (var key in keys) {
        if (json[key] != null) return json[key].toString();
      }
      return null;
    }

    var virtualAccount = json['virtual_account'] ?? json['bank_details'] ?? json['virtualAccount'];
    var transList = <TransactionModel>[];
    if (json['transactions'] != null && json['transactions'] is List) {
      transList = (json['transactions'] as List).map((i) => TransactionModel.fromJson(i)).toList();
    }

    return UserModel(
      status: getString(['status', 'code', 'Status', 'response_code']),
      userId: getString(['userId', 'id', 'user_id', 'userid']),
      email: getString(['email', 'Email', 'user_email']),
      walletBalance: getString(['walletBalance', 'balance', 'wallet_balance']),
      fullName: getString(['fullName', 'full_name', 'name', 'fullname']),
      message: getString(['message', 'msg', 'info', 'remarks']),
      profilePic: getString(['profile_pic', 'profilePic', 'image', 'user_image']),
      transactionPin: getString(['transaction_pin', 'pin', 'transactionPin']),
      phone: getString(['phone', 'phone_number', 'mobile']),
      bankName: getString(['bankName', 'bank_name', 'Bank_Name']) ?? (virtualAccount != null ? virtualAccount['bank_name'] : null),
      accountNumber: getString(['accountNumber', 'account_number', 'Account_Number']) ?? (virtualAccount != null ? virtualAccount['account_number'] : null),
      accountName: getString(['accountName', 'account_name', 'Account_Name']) ?? (virtualAccount != null ? virtualAccount['account_name'] : null),
      otpRequired: json['otp_required'] ?? (json['status'] == 'new_device'),
      userLevel: json['userLevel']?.toString(),
      creditLimit: (json['creditLimit'] ?? 0.0).toDouble(),
      outstandingDebt: (json['outstandingDebt'] ?? 0.0).toDouble(),
      totalSpent: (json['total_spent'] ?? 0.0).toDouble(),
      transactions: transList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'userId': userId,
      'email': email,
      'walletBalance': walletBalance,
      'fullName': fullName,
      'profile_pic': profilePic,
      'transaction_pin': transactionPin,
      'phone': phone,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'userLevel': userLevel,
      'creditLimit': creditLimit,
      'outstandingDebt': outstandingDebt,
      'total_spent': totalSpent,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  UserModel copyWith({
    String? status,
    String? userId,
    String? email,
    String? walletBalance,
    String? fullName,
    String? message,
    String? profilePic,
    String? transactionPin,
    String? phone,
    String? bankName,
    String? accountNumber,
    String? accountName,
    bool? otpRequired,
    String? userLevel,
    double? creditLimit,
    double? outstandingDebt,
    double? totalSpent,
    List<TransactionModel>? transactions,
  }) {
    return UserModel(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      walletBalance: walletBalance ?? this.walletBalance,
      fullName: fullName ?? this.fullName,
      message: message ?? this.message,
      profilePic: profilePic ?? this.profilePic,
      transactionPin: transactionPin ?? this.transactionPin,
      phone: phone ?? this.phone,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      otpRequired: otpRequired ?? this.otpRequired,
      userLevel: userLevel ?? this.userLevel,
      creditLimit: creditLimit ?? this.creditLimit,
      outstandingDebt: outstandingDebt ?? this.outstandingDebt,
      totalSpent: totalSpent ?? this.totalSpent,
      transactions: transactions ?? this.transactions,
    );
  }

  bool get isSuccess {
    if (status == null) return false;
    String s = status!.toLowerCase();
    return s.contains('success') || s.contains('verified') || s == '1' || s == 'true' || s == '000' || s == '200' || s == 'new_device';
  }
}
