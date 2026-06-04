import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/services/api_service.dart';

enum LoginStatus { success, newDevice, error, loading }

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _balanceHidden = false;
  bool _biometricEnabled = false;
  String? _savedEmail;
  String? _savedPassword;

  UserModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get balanceHidden => _balanceHidden;
  bool get biometricEnabled => _biometricEnabled;
  String? get savedEmail => _savedEmail;

  final ApiService _apiService = ApiService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String keyUserJson = 'user_json';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyBalanceHidden = 'balance_hidden';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keySavedEmail = 'saved_email';
  static const String keySavedPassword = 'saved_password';

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(keyIsLoggedIn) ?? false;
    _balanceHidden = prefs.getBool(keyBalanceHidden) ?? false;
    _biometricEnabled = prefs.getBool(keyBiometricEnabled) ?? false;
    _savedEmail = prefs.getString(keySavedEmail);
    _savedPassword = prefs.getString(keySavedPassword);

    final userJson = prefs.getString(keyUserJson);
    if (userJson != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<LoginStatus> login(String email, String password, String deviceId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password, deviceId);
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['status'] == 'new_device') {
        _isLoading = false;
        // Temporarily store user phone for OTP verification if needed
        _user = UserModel(phone: data['phone']);
        notifyListeners();
        return LoginStatus.newDevice;
      }

      final userModel = UserModel.fromJson(data);

      if (userModel.isSuccess) {
        _user = userModel;
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyUserJson, jsonEncode(userModel.toJson()));
        await prefs.setBool(keyIsLoggedIn, true);
        await prefs.setString(keySavedEmail, email);
        if (_biometricEnabled) {
          await prefs.setString(keySavedPassword, password);
        }

        await refreshProfile();

        _isLoading = false;
        notifyListeners();
        return LoginStatus.success;
      } else {
        _isLoading = false;
        notifyListeners();
        return LoginStatus.error;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return LoginStatus.error;
    }
  }

  Future<bool> verifyDeviceOtp(String identifier, String otp, String deviceId) async {
    try {
      debugPrint("Verifying OTP for $identifier with code $otp");
      final response = await _apiService.verifyOtp(identifier, otp, deviceId, action: 'verify');
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      debugPrint("OTP Response: $data");
      return data['status'] == 'success';
    } catch (e) {
      debugPrint("OTP Verification error: $e");
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled, {String? password}) async {
    _biometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyBiometricEnabled, enabled);
    if (enabled && password != null) {
      await prefs.setString(keySavedPassword, password);
    } else if (!enabled) {
      await prefs.remove(keySavedPassword);
    }
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    // Keep saved email and biometric settings, but clear session
    await prefs.remove(keyUserJson);
    await prefs.remove(keyIsLoggedIn);
    notifyListeners();
  }

  void toggleBalanceVisibility() async {
    _balanceHidden = !_balanceHidden;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyBalanceHidden, _balanceHidden);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_user?.userId == null) return;
    try {
      final updatedUser = await _apiService.getUserProfile(_user!.userId!);
      final transactions = await _apiService.getTransactions(_user!.userId!);

      if (updatedUser != null) {
        _user = updatedUser.copyWith(transactions: transactions);
      } else {
        _user = _user?.copyWith(transactions: transactions);
      }

      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyUserJson, jsonEncode(_user!.toJson()));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Refresh profile error: $e");
    }
  }
}
