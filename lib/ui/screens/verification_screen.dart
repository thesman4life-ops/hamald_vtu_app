import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../widgets/pin_pad_dialog.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String? _selectedIdType;
  final _idNumberController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _resultData;
  final ApiService _apiService = ApiService();

  final List<Map<String, String>> _idTypes = [
    {'name': 'NIN', 'code': 'nin'},
    {'name': 'BVN', 'code': 'bvn'},
    {'name': "Voter's Card", 'code': 'voter'},
    {'name': "Driver's License", 'code': 'driver_license'},
  ];

  void _handleVerify() async {
    if (_selectedIdType == null || _idNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final auth = context.read<AuthProvider>();
    double balance = double.tryParse(auth.user?.walletBalance?.replaceAll(',', '') ?? '0') ?? 0;
    
    if (balance < 200) {
      _showInsufficientBalanceDialog(balance);
      return;
    }

    _showConfirmationDialog();
  }

  void _showInsufficientBalanceDialog(double balance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Balance'),
        content: Text('Verification costs ₦200.00. Your current balance is ₦${Utils.formatCurrency(balance.toString())}.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are about to verify an identity. A fee of ₦200.00 will be deducted.'),
            const SizedBox(height: 16),
            _detailRow('ID Type', _selectedIdType!),
            _detailRow('ID Number', _idNumberController.text),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _authorizeTransaction();
            },
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _authorizeTransaction() async {
    final auth = context.read<AuthProvider>();
    
    // Check for biometrics or use PIN
    bool authorized = false;
    if (auth.biometricEnabled) {
      authorized = await auth.authenticateWithBiometrics();
    }

    if (authorized) {
      _startVerification();
    } else {
      // Show PIN Pad
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => PinPadDialog(
            onSuccess: (pin) => _startVerification(),
          ),
        );
      }
    }
  }

  void _startVerification() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final idCode = _idTypes.firstWhere((element) => element['name'] == _selectedIdType)['code'];

    try {
      final response = await _apiService.verifyIdentity(
        auth.user!.userId!,
        _idNumberController.text.trim(),
        idCode!,
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data['status'] == 'success') {
        setState(() {
          _resultData = data['data'];
        });
        auth.refreshProfile(); // Refresh balance
      } else {
        _showErrorDialog('Verification Failed', data['message'] ?? 'Service provider error');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Unable to process verification. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KYC Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Verify your identity instantly. This service attracts a ₦200 fee.', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),

                DropdownButtonFormField<String>(
                  value: _selectedIdType,
                  decoration: const InputDecoration(
                    labelText: 'Select ID Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: _idTypes.map((t) => DropdownMenuItem(value: t['name'], child: Text(t['name']!))).toList(),
                  onChanged: (v) => setState(() => _selectedIdType = v),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _idNumberController,
                  decoration: const InputDecoration(
                    labelText: 'ID Number / NIN / BVN',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('VERIFY IDENTITY'),
                  ),
                ),

                if (_resultData != null) ...[
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text('Verification Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_resultData!['photo'] != null || _resultData!['image'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_resultData!['photo'] ?? _resultData!['image']),
                              width: 80,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_resultData!['first_name'] ?? ""} ${_resultData!['last_name'] ?? ""}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('DOB: ${_resultData!['dob'] ?? _resultData!['birthdate'] ?? "N/A"}'),
                              Text('Gender: ${(_resultData!['gender'] ?? "N/A").toString().toUpperCase()}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
