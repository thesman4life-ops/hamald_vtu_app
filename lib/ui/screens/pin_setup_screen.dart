import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isResetMode;
  const PinSetupScreen({super.key, this.isResetMode = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResetModeInternal = false;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _isResetModeInternal = widget.isResetMode;
  }

  void _handleSavePin() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    String newPin = _newPinController.text;
    String confirmPin = _confirmPinController.text;

    bool hasExistingPin = user.transactionPin != null &&
                          user.transactionPin!.isNotEmpty &&
                          user.transactionPin != '0000';

    if (hasExistingPin && !_isResetModeInternal) {
      if (_currentPinController.text != user.transactionPin) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Current PIN is incorrect')));
        return;
      }
    }

    if (newPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
      return;
    }

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.updatePin(user.userId!, newPin);
      setState(() => _isLoading = false);

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN updated successfully')));
        await auth.refreshProfile();
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to update PIN')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _handleForgotPin() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.email == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.sendResetPinOtp(auth.user!.email!);
      setState(() => _isLoading = false);
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['status'] == 'success') {
        _showOtpDialog(auth.user!.email!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending OTP')));
    }
  }

  void _showOtpDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('Verify Identity', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the 6-digit code sent to $email', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 35,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(counterText: '', enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54))),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () async {
              String otp = _otpControllers.map((c) => c.text).join();
              if (otp.length == 6) {
                _verifyOtp(otp);
              }
            },
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );
  }

  void _verifyOtp(String otp) async {
    final auth = context.read<AuthProvider>();
    try {
      final response = await _apiService.verifyOtp(auth.user!.email!, otp, 'FLUTTER_DEVICE_ID', action: 'verify');
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data['status'] == 'success') {
        Navigator.pop(context);
        setState(() => _isResetModeInternal = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Identity verified. Set new PIN.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    bool hasExistingPin = user?.transactionPin != null &&
                          user!.transactionPin!.isNotEmpty &&
                          user.transactionPin != '0000';

    String title = "Set Transaction PIN";
    String subtitle = "Create a 4-digit PIN to secure your transactions";
    if (hasExistingPin && !_isResetModeInternal) {
      title = "Change Transaction PIN";
      subtitle = "Update your security PIN for transactions";
    } else if (_isResetModeInternal) {
      title = "Reset Transaction PIN";
      subtitle = "Set a new 4-digit security PIN";
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            if (hasExistingPin && !_isResetModeInternal) ...[
              TextField(
                controller: _currentPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(hintText: 'Current 4-Digit PIN', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(hintText: 'New 4-Digit PIN', prefixIcon: Icon(Icons.security)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(hintText: 'Confirm New PIN', prefixIcon: Icon(Icons.check_circle_outline)),
            ),
            const SizedBox(height: 16),
            if (hasExistingPin && !_isResetModeInternal)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _handleForgotPin, child: const Text('Forgot PIN?')),
              ),
            const SizedBox(height: 32),
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _handleSavePin,
                  child: Text(_isResetModeInternal ? 'RESET PIN' : (hasExistingPin ? 'UPDATE PIN' : 'SAVE PIN')),
                ),
          ],
        ),
      ),
    );
  }
}
