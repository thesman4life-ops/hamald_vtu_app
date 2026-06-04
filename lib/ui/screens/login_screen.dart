import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'pin_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _obscurePassword = true;

  late AnimationController _blobController;
  late AnimationController _entranceController;
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _formAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.savedEmail != null) {
        _emailController.text = auth.savedEmail!;
      }
    });
  }

  @override
  void dispose() {
    _blobController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final status = await authProvider.login(
      _emailController.text,
      _passwordController.text,
      'FLUTTER_DEVICE_ID', 
    );

    if (status == LoginStatus.success) {
      if (mounted) {
        _checkPinAndBiometrics();
      }
    } else if (status == LoginStatus.newDevice) {
      if (mounted) {
        _showOtpDialog();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials or connection error')),
        );
      }
    }
  }

  void _checkPinAndBiometrics() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    bool pinNeedsSetup = user.transactionPin == null ||
                         user.transactionPin!.isEmpty ||
                         user.transactionPin == 'null' ||
                         user.transactionPin == '0000';

    if (pinNeedsSetup) {
      _showPinSetupPrompt();
    } else if (!auth.biometricEnabled) {
      _showBiometricActivationDialog();
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  void _showOtpDialog() {
    final auth = context.read<AuthProvider>();
    final phone = auth.user?.phone ?? 'your phone';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Device Detected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A verification code has been sent to $phone. Please enter it below:',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return Container(
                  width: 40,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              String otp = _otpControllers.map((c) => c.text).join();
              if (otp.length == 6) {
                final success = await auth.verifyDeviceOtp(
                  auth.user?.phone ?? _emailController.text, 
                  otp,
                  'FLUTTER_DEVICE_ID',
                );
                if (success) {
                  Navigator.pop(context);
                  _handleLogin(); 
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid or expired OTP')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );
  }

  void _showPinSetupPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Setup Transaction PIN'),
        content: const Text('You haven\'t set up a transaction PIN yet. Security is important for your transactions.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showBiometricActivationDialog();
            },
            child: const Text('LATER'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
              if (mounted) _checkPinAndBiometrics();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            child: const Text('SETUP NOW'),
          ),
        ],
      ),
    );
  }

  void _showBiometricActivationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enable Biometrics'),
        content: const Text('Would you like to use fingerprint/face ID for faster login next time?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
            child: const Text('SKIP'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final success = await auth.authenticateWithBiometrics();
              if (success) {
                await auth.setBiometricEnabled(true, password: _passwordController.text);
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            child: const Text('ENABLE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Stack(
        children: [
          // Animated Background Blobs
          AnimatedBuilder(
            animation: _blobController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -50 + (20 * math.sin(_blobController.value * 2 * math.pi)),
                    left: -100 + (30 * math.cos(_blobController.value * 2 * math.pi)),
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100 + (40 * math.cos(_blobController.value * 2 * math.pi)),
                    right: -100 + (20 * math.sin(_blobController.value * 2 * math.pi)),
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        
                        // Entrance Animation for Logo
                        FadeTransition(
                          opacity: _logoAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(_logoAnimation),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(Icons.flash_on, color: AppColors.primaryBlue, size: 60),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Login to your Hamald VTU account',
                                  style: TextStyle(fontSize: 16, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 48),

                        // Entrance Animation for Form
                        FadeTransition(
                          opacity: _formAnimation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0).animate(_formAnimation),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _emailController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Email Address',
                                      hintStyle: const TextStyle(color: Colors.white60),
                                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                                      fillColor: Colors.white.withOpacity(0.05),
                                      filled: true,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Colors.white10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Password',
                                      hintStyle: const TextStyle(color: Colors.white60),
                                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                      fillColor: Colors.white.withOpacity(0.05),
                                      filled: true,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Colors.white10),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (authProvider.biometricEnabled)
                                        InkWell(
                                          onTap: () async {
                                            final success = await authProvider.authenticateWithBiometrics();
                                            if (success) {
                                              final prefs = await SharedPreferences.getInstance();
                                              final pass = prefs.getString('saved_password');
                                              if (pass != null) {
                                                _passwordController.text = pass;
                                                _handleLogin();
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.fingerprint, color: Colors.white, size: 28),
                                          ),
                                        )
                                      else
                                        const SizedBox(),
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  authProvider.isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : ElevatedButton(
                                          onPressed: _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: AppColors.primaryBlue,
                                            minimumSize: const Size(double.infinity, 56),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            elevation: 0,
                                          ),
                                          child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: Colors.white70),
                              children: [
                                TextSpan(
                                  text: "Register Now",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Quick Links
                FadeTransition(
                  opacity: _formAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Row(
                      children: [
                        _quickLink(Icons.info_outline, "Version 1.0"),
                        _quickLink(Icons.code, "About Dev"),
                        _quickLink(Icons.chat_bubble_outline, "Support"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickLink(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

  Widget _quickLink(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
