import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/app_constants.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import '../models/register_request.dart';
import 'package:logger/logger.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
  ));

  final Logger _logger = Logger();

  ApiService() {
    _dio.options.headers = {
      'Accept': 'application/json',
      'User-Agent': 'HamaldVTU_Flutter',
    };
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => _logger.d(obj),
    ));
  }

  dynamic _parseResponse(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (e) {
        _logger.e("JSON Decode Error: $e \n Data: $data");
        return null;
      }
    }
    return data;
  }

  Future<Response> login(String email, String password, String deviceId, {String appVersion = '1.0.0'}) async {
    return await _dio.post(AppConstants.login, data: {
      'email': email,
      'password': password,
      'deviceId': deviceId,
      'appVersion': appVersion,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> sendOtp(String phone) async {
    return await _dio.post('otp.php', data: {
      'action': 'send',
      'phone': phone,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> verifyOtp(String phone, String otp, String deviceId, {String action = 'verify'}) async {
    return await _dio.post('otp.php', data: {
      'action': action,
      'phone': phone,
      'otp': otp,
      'deviceId': deviceId,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> register(RegisterRequest request) async {
    return await _dio.post(AppConstants.register,
      data: request.toJson(),
      options: Options(contentType: Headers.jsonContentType));
  }

  Future<Response> verifyPin(String userId, String pin) async {
    return await _dio.post('verify-pin.php', data: {
      'userId': userId,
      'pin': pin,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> verifyIdentity(String userId, String idNumber, String idType) async {
    return await _dio.post('verify-id.php', data: {
      'userId': userId,
      'id_number': idNumber,
      'id_type': idType,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> sendResetPinOtp(String email) async {
    return await _dio.post('otp.php', data: {
      'action': 'reset_pin',
      'phone': email,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> getServiceVariations(String serviceId) async {
    return await _dio.get(AppConstants.getServicePricing, queryParameters: {
      'serviceID': serviceId,
    });
  }

  Future<Response> buyAirtime(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.buyAirtime, data: data);
  }

  Future<Response> buyData(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.buyData, data: data);
  }

  Future<Response> verifyMeter(String provider, String meterNumber, String meterType) async {
    return await _dio.post('verify-meter.php', data: {
      'serviceID': provider,
      'billersCode': meterNumber,
      'type': meterType,
    });
  }

  Future<Response> payUtility(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.payUtility, data: data);
  }

  Future<Response> verifySmartCard(String provider, String billersCode) async {
    return await _dio.post('verify-smartcard.php', data: {
      'serviceID': provider,
      'billersCode': billersCode,
    });
  }

  Future<Response> payCable(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.payCable, data: data);
  }

  Future<Response> getBanks() async {
    return await _dio.get(AppConstants.getBanks);
  }

  Future<Response> initializePayment(String userId, String amount, String email) async {
    return await _dio.post('initialize-payment.php', data: {
      'userId': userId,
      'amount': amount,
      'email': email,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> getPromos() async {
    return await _dio.get('promos.json');
  }

  Future<Response> getNews() async {
    return await _dio.get('get-news.php');
  }

  Future<Response> updateFcmToken(String userId, String token) async {
    return await _dio.post('update-fcm-token.php', data: {
      'userId': userId,
      'fcmToken': token,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> verifyAccount(String bankCode, String accountNumber) async {
    return await _dio.post(AppConstants.verifyAccount, data: {
      'bankCode': bankCode,
      'accountNumber': accountNumber,
    });
  }

  Future<Response> verifyWalletAccount(String identifier) async {
    return await _dio.get(AppConstants.verifyWalletAccount, queryParameters: {
      'query': identifier,
    });
  }

  Future<Response> performTransfer(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.performTransfer, data: data);
  }

  Future<Response> performWalletTransfer(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.walletTransfer, data: data);
  }

  Future<Response> verifySchool(String serviceId, String profileId, String type) async {
    return await _dio.post(AppConstants.verifySchool, data: {
      'serviceID': serviceId,
      'billersCode': profileId,
      'type': type,
    });
  }

  Future<Response> buySchoolPin(Map<String, dynamic> data) async {
    return await _dio.post(AppConstants.buySchoolPin, data: data);
  }

  Future<Response> getRewardHistory(String userId) async {
    return await _dio.get('get-reward-history.php', queryParameters: {'userId': userId});
  }

  Future<Response> uploadProfilePicBase64(String userId, String base64Image) async {
    return await _dio.post('u-px.php', data: {
      'userId': userId,
      'apiKey': 'd90e779410bbf9be47895aacb487ebd0',
      'image': base64Image,
    });
  }

  Future<Response> requeryElectricity(String requestId) async {
    return await _dio.get('requery-electricity.php', queryParameters: {'requestId': requestId});
  }

  Future<Response> requeryCable(String requestId) async {
    return await _dio.get('requery-cable.php', queryParameters: {'requestId': requestId});
  }

  Future<Response> getUserTickets(String userId) async {
    return await _dio.get('get-tickets.php', queryParameters: {'userId': userId});
  }

  Future<Response> getAdminStats(String adminId, String fromDate, String toDate) async {
    return await _dio.get('admin-stats.php', queryParameters: {
      'adminId': adminId,
      'fromDate': fromDate,
      'toDate': toDate,
    });
  }

  Future<Response> createTicket(String userId, String subject, String message, String priority) async {
    return await _dio.post('create-ticket.php', data: {
      'userId': userId,
      'subject': subject,
      'message': message,
      'priority': priority,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> updatePassword(String userId, String oldPass, String newPass) async {
    return await _dio.post('update-profile.php', data: {
      'userId': userId,
      'oldPassword': oldPass,
      'newPassword': newPass,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<Response> getTicketReplies(String ticketId) async {
    return await _dio.get('get-ticket-replies.php', queryParameters: {'ticketId': ticketId});
  }

  Future<Response> replyTicket(String ticketId, String userId, String message) async {
    return await _dio.post('reply-ticket.php', data: {
      'ticketId': ticketId,
      'userId': userId,
      'message': message,
    }, options: Options(contentType: Headers.formUrlEncodedContentType));
  }

  Future<List<TransactionModel>> getTransactions(String userId) async {
    try {
      final response = await _dio.get(AppConstants.getTransactions, queryParameters: {
        'userId': userId,
      });
      final data = _parseResponse(response.data);
      if (data != null && data is List) {
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      }
    } catch (e) {
      _logger.e("Error fetching transactions: $e");
    }
    return [];
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _dio.get(AppConstants.getUserProfile, queryParameters: {
        'userId': userId,
      });
      final data = _parseResponse(response.data);
      if (data != null && data is Map<String, dynamic>) {
        return UserModel.fromJson(data);
      }
    } catch (e) {
      _logger.e("Error fetching profile: $e");
    }
    return null;
  }
}
