import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/services/api_service.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({super.key});

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedNetwork;
  bool _isLoading = false;
  double _discountPct = 0.0;
  final _apiService = ApiService();

  final List<Map<String, String>> _networks = [
    {'name': 'MTN', 'key': 'mtn', 'icon': 'assets/images/mtn.png'},
    {'name': 'GLO', 'key': 'glo', 'icon': 'assets/images/glo.png'},
    {'name': 'Airtel', 'key': 'airtel', 'icon': 'assets/images/airtel.png'},
    {'name': '9Mobile', 'key': 'etisalat', 'icon': 'assets/images/9mobile.png'},
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_resolveNetwork);
  }

  void _resolveNetwork() {
    String number = _phoneController.text;
    if (number.length < 4) return;
    String prefix = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (prefix.startsWith('234')) prefix = '0${prefix.substring(3)}';
    if (prefix.length < 4) return;
    prefix = prefix.substring(0, 4);

    String? detected;
    if (RegExp(r'0703|0706|0803|0806|0810|0813|0814|0816|0903|0906|0913|0916').hasMatch(prefix)) detected = 'mtn';
    else if (RegExp(r'0705|0805|0807|0811|0815|0905|0915').hasMatch(prefix)) detected = 'glo';
    else if (RegExp(r'0701|0708|0802|0808|0812|0901|0902|0904|0907|0912').hasMatch(prefix)) detected = 'airtel';
    else if (RegExp(r'0809|0817|0818|0908|0909').hasMatch(prefix)) detected = 'etisalat';

    if (detected != null && detected != _selectedNetwork) {
      setState(() {
        _selectedNetwork = detected;
        _fetchDiscount();
      });
    }
  }

  void _fetchDiscount() async {
    if (_selectedNetwork == null) return;
    try {
      final response = await _apiService.getServiceVariations(_selectedNetwork!);
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      setState(() {
        _discountPct = (data['user_discount'] ?? data['user_discount_pct'] ?? data['discount'] ?? 0.0).toDouble();
      });
    } catch (e) {
      debugPrint("Discount fetch error: $e");
    }
  }

  void _handlePurchase() async {
    if (_selectedNetwork == null || _phoneController.text.length < 11 || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields correctly')));
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.user?.transactionPin == null || auth.user!.transactionPin == '0000') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set your transaction PIN first')));
      return;
    }

    _showConfirmDialog();
  }

  void _showConfirmDialog() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    double savings = amount * (_discountPct / 100);
    double toPay = amount - savings;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirm Purchase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _confirmRow('Network', _selectedNetwork!.toUpperCase()),
            _confirmRow('Phone', _phoneController.text),
            _confirmRow('Amount', '₦${Utils.formatCurrency(amount.toString())}'),
            _confirmRow('Discount', '- ₦${Utils.formatCurrency(savings.toString())}', valueColor: Colors.green),
            const Divider(),
            _confirmRow('Total Payable', '₦${Utils.formatCurrency(toPay.toString())}', isBold: true),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPinDialog();
              },
              child: const Text('CONFIRM'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor)),
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
                _processPurchase(pin);
              }
            },
            child: const Text('PAY'),
          ),
        ],
      ),
    );
  }

  void _processPurchase(String pin) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final Map<String, dynamic> data = {
      'userId': auth.user!.userId,
      'network': _selectedNetwork,
      'amount': _amountController.text,
      'phoneNumber': _phoneController.text,
      'pin': pin,
    };

    try {
      final response = await _apiService.buyAirtime(data);
      final res = response.data is String ? jsonDecode(response.data) : response.data;

      setState(() => _isLoading = false);
      if (res['status'] == 'success') {
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
        title: const Text('Recharge Successful'),
        content: const Text('Your airtime recharge was successful.'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('DONE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy Airtime')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Network', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _networks.map((n) => GestureDetector(
                onTap: () => setState(() {
                  _selectedNetwork = n['key'];
                  _fetchDiscount();
                }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: _selectedNetwork == n['key'] ? AppColors.primaryBlue : Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: _selectedNetwork == n['key'] ? AppColors.primaryBlue.withOpacity(0.05) : null,
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.signal_cellular_alt), // Placeholder for logo
                      const SizedBox(height: 4),
                      Text(n['name']!, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                hintText: '08012345678',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₦ ',
                prefixIcon: Icon(Icons.money),
              ),
            ),
            if (_discountPct > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('You will get $_discountPct% discount', style: const TextStyle(color: Colors.green, fontSize: 12)),
              ),
            const SizedBox(height: 40),
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _handlePurchase, child: const Text('BUY AIRTIME')),
          ],
        ),
      ),
    );
  }
}
