import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/services/api_service.dart';
import '../../data/models/cable_plan.dart';

class CableScreen extends StatefulWidget {
  const CableScreen({super.key});

  @override
  State<CableScreen> createState() => _CableScreenState();
}

class _CableScreenState extends State<CableScreen> {
  final _smartCardController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedProvider;
  CablePlan? _selectedPlan;
  List<CablePlan> _plans = [];
  bool _isLoading = false;
  bool _isVerified = false;
  String? _verifiedCustomerName;
  final _apiService = ApiService();

  final List<Map<String, String>> _providers = [
    {'name': 'DSTV', 'id': 'dstv'},
    {'name': 'GOTV', 'id': 'gotv'},
    {'name': 'StarTimes', 'id': 'startimes'},
    {'name': 'Showmax', 'id': 'showmax'},
  ];

  void _fetchPlans() async {
    if (_selectedProvider == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getServiceVariations(_selectedProvider!);
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      List? variations;
      if (data['plans'] != null) {
        variations = data['plans'];
      } else if (data['content'] != null && data['content']['varations'] != null) {
        variations = data['content']['varations'];
      }

      final variationsList = variations;
      if (variationsList != null && variationsList is List) {
        setState(() {
          _plans = variationsList.map((e) => CablePlan.fromJson(e)).toList();
          _selectedPlan = null;
        });
      }
    } catch (e) {
      debugPrint("Cable plans error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleVerify() async {
    if (_selectedProvider == null || _smartCardController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select provider and enter Smartcard number')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.verifySmartCard(_selectedProvider!, _smartCardController.text);
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      setState(() {
        _isLoading = false;
        if (data['status'] == 'success' || data['status'] == '200') {
          _isVerified = true;
          _verifiedCustomerName = data['customerName'] ?? data['name'] ?? 'Verified Customer';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify Smartcard first')));
      return;
    }
    if (_selectedPlan == null || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a plan and enter phone number')));
      return;
    }
    _showConfirmDialog();
  }

  void _showConfirmDialog() {
    double amount = double.tryParse(_selectedPlan!.originalPrice) ?? 0;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirm Cable Subscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _confirmRow('Provider', _providers.firstWhere((p) => p['id'] == _selectedProvider)['name']!),
            _confirmRow('Customer', _verifiedCustomerName ?? ''),
            _confirmRow('Plan', _selectedPlan!.name),
            _confirmRow('Smartcard', _smartCardController.text),
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
      'smartCardNumber': _smartCardController.text,
      'variationCode': _selectedPlan!.variationCode,
      'amount': _selectedPlan!.originalPrice,
      'phoneNumber': _phoneController.text,
      'pin': pin,
    };

    try {
      final response = await _apiService.payCable(data);
      final res = response.data is String ? jsonDecode(response.data) : response.data;

      setState(() => _isLoading = false);
      if (res['status'] == 'success' || res['status'] == '000') {
        _showSuccessDialog();
        auth.refreshProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Transaction failed')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('Subscription Successful'),
        content: const Text('Your cable subscription has been processed successfully.'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('DONE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cable TV')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              hint: const Text('Select Provider'),
              items: _providers.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']!))).toList(),
              onChanged: (v) => setState(() {
                _selectedProvider = v;
                _isVerified = false;
                _plans = [];
                _fetchPlans();
              }),
              decoration: const InputDecoration(labelText: 'Cable Provider'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _smartCardController,
              decoration: InputDecoration(
                labelText: 'Smartcard / IUC Number',
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
                child: Text('Customer: $_verifiedCustomerName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<CablePlan>(
              value: _selectedPlan,
              hint: const Text('Select Plan'),
              items: _plans.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} - ₦${Utils.formatCurrency(p.originalPrice)}'))).toList(),
              onChanged: (v) => setState(() => _selectedPlan = v),
              decoration: const InputDecoration(labelText: 'Subscription Plan'),
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
                  child: Text(_isVerified ? 'PAY NOW' : 'VERIFY SMARTCARD'),
                ),
          ],
        ),
      ),
    );
  }
}
