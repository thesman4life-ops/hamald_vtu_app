import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/services/api_service.dart';

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});

  @override
  State<UtilityScreen> createState() => _UtilityScreenState();
}

class _UtilityScreenState extends State<UtilityScreen> {
  final _meterController = TextEditingController();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedProvider;
  String? _selectedMeterType;
  bool _isLoading = false;
  bool _isVerified = false;
  String? _verifiedCustomerName;
  String? _verifiedAddress;
  final _apiService = ApiService();

  final List<Map<String, String>> _providers = [
    {'name': 'Aba Electric', 'id': 'aba-electric'},
    {'name': 'Abuja Electric (AEDC)', 'id': 'abuja-electric'},
    {'name': 'Benin Electric', 'id': 'benin-electric'},
    {'name': 'Eko Electric', 'id': 'eko-electric'},
    {'name': 'Enugu Electric (EEDC)', 'id': 'enugu-electric'},
    {'name': 'Ibadan Electric', 'id': 'ibadan-electric'},
    {'name': 'Ikeja Electric', 'id': 'ikeja-electric'},
    {'name': 'Jos Electric', 'id': 'jos-electric'},
    {'name': 'Kaduna Electric', 'id': 'kaduna-electric'},
    {'name': 'Kano Electric', 'id': 'kano-electric'},
    {'name': 'Port Harcourt Electric', 'id': 'portharcourt-electric'},
    {'name': 'Yola Electric', 'id': 'yola-electric'},
  ];

  void _handleVerify() async {
    if (_selectedProvider == null || _selectedMeterType == null || _meterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all verification fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.verifyMeter(_selectedProvider!, _meterController.text, _selectedMeterType!.toLowerCase());
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _isVerified = true;
          _verifiedCustomerName = data['customerName'] ?? data['name'];
          _verifiedAddress = data['address'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Verification failed')));
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error during verification')));
    }
  }

  void _handlePay() {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify meter first')));
      return;
    }
    if (_amountController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter amount and phone number')));
      return;
    }
    _showConfirmDialog();
  }

  void _showConfirmDialog() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirm Utility Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _confirmRow('Provider', _providers.firstWhere((p) => p['id'] == _selectedProvider)['name']!),
            _confirmRow('Customer', _verifiedCustomerName ?? ''),
            _confirmRow('Meter No', _meterController.text),
            _confirmRow('Amount', '₦${Utils.formatCurrency(amount.toString())}', isBold: true),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPinDialog();
              },
              child: const Text('CONFIRM PAYMENT'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  void _showPinDialog() {
    final List<TextEditingController> pins = List.generate(4, (_) => TextEditingController());
    final List<FocusNode> nodes = List.generate(4, (_) => FocusNode());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) => SizedBox(
            width: 40,
            child: TextField(
              controller: pins[i],
              focusNode: nodes[i],
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              decoration: const InputDecoration(counterText: ''),
              onChanged: (v) {
                if (v.isNotEmpty && i < 3) nodes[i+1].requestFocus();
                if (v.isEmpty && i > 0) nodes[i-1].requestFocus();
              },
            ),
          )),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              String pin = pins.map((e) => e.text).join();
              if (pin.length == 4) {
                Navigator.pop(context);
                _processPayment(pin);
              }
            },
            child: const Text('PAY'),
          ),
        ],
      ),
    );
  }

  void _processPayment(String pin) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final Map<String, dynamic> data = {
      'userId': auth.user!.userId,
      'provider': _selectedProvider,
      'meterNumber': _meterController.text,
      'type': _selectedMeterType?.toLowerCase(),
      'amount': _amountController.text,
      'phoneNumber': _phoneController.text,
      'pin': pin,
    };

    try {
      final response = await _apiService.payUtility(data);
      final res = response.data is String ? jsonDecode(response.data) : response.data;

      setState(() => _isLoading = false);
      if (res['status'] == 'success') {
        _showSuccessDialog(res['token']);
        auth.refreshProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Transaction failed')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _showSuccessDialog(String? token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your electricity payment was successful.'),
            if (token != null && token.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('TOKEN:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(token, style: const TextStyle(fontSize: 20, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('DONE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Electricity Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              hint: const Text('Select Provider'),
              items: _providers.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']!))).toList(),
              onChanged: (v) => setState(() { _selectedProvider = v; _isVerified = false; }),
              decoration: const InputDecoration(labelText: 'Distribution Company'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMeterType,
              hint: const Text('Meter Type'),
              items: ['Prepaid', 'Postpaid'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() { _selectedMeterType = v; _isVerified = false; }),
              decoration: const InputDecoration(labelText: 'Meter Type'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _meterController,
              decoration: InputDecoration(
                labelText: 'Meter Number',
                suffixIcon: IconButton(icon: const Icon(Icons.check_circle_outline), onPressed: _handleVerify),
              ),
              onChanged: (_) => setState(() => _isVerified = false),
            ),
            if (_isVerified) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer: $_verifiedCustomerName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    if (_verifiedAddress != null) Text('Address: $_verifiedAddress', style: const TextStyle(fontSize: 12, color: Colors.green)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₦ '),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 40),
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _isVerified ? _handlePay : _handleVerify,
                  child: Text(_isVerified ? 'PAY NOW' : 'VERIFY METER'),
                ),
          ],
        ),
      ),
    );
  }
}
