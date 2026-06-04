import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/models/register_request.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _obscurePassword = true;
  bool _isLoading = false;
  final _apiService = ApiService();

  bool _isValidPassword(String password) {
    if (password.length < 6) return false;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    return hasUppercase && hasDigits && hasLowercase && hasSpecialCharacters;
  }

  void _handleRegister() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    if (!_isValidPassword(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be 6+ chars with A, a, 0-9, and @#\$')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.sendOtp(_phoneController.text.trim());
      setState(() => _isLoading = false);

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data['status'] == 'success') {
        _showOtpDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to send OTP')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('OTP Verification', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the 6-digit code sent to ${_phoneController.text}', style: const TextStyle(color: Colors.white70)),
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
    try {
      final response = await _apiService.verifyOtp(_phoneController.text.trim(), otp, 'FLUTTER_DEVICE_ID', action: 'verify');
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data['status'] == 'success') {
        Navigator.pop(context); // Close dialog
        _completeRegistration();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Invalid or expired OTP')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification failed')));
    }
  }

  void _completeRegistration() async {
    setState(() => _isLoading = true);
    final request = RegisterRequest(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      referralCode: _referralController.text.trim(),
      deviceId: 'FLUTTER_DEVICE_ID',
    );

    try {
      final response = await _apiService.register(request);
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['status'] == 'success') {
        // Log in immediately
        if (mounted) {
          final auth = context.read<AuthProvider>();
          await auth.login(request.email, request.password, 'FLUTTER_DEVICE_ID');
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Registration failed')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed due to connection error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Join Hamald VTU', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Register now and enjoy fast, reliable recharges', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 16),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'Email Address', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 16),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _referralController, decoration: const InputDecoration(hintText: 'Referral Code (Optional)', prefixIcon: Icon(Icons.card_giftcard))),
            const SizedBox(height: 32),
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _handleRegister, child: const Text('REGISTER')),
            const SizedBox(height: 24),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
