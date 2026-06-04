import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/services/api_service.dart';
import '../../data/models/bank_model.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isWalletTransfer = false;
  bool _isLoading = false;
  bool _isVerified = false;
  String? _verifiedName;
  BankModel? _selectedBank;
  List<BankModel> _banks = [];
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchBanks();
  }

  void _fetchBanks() async {
    try {
      final response = await _apiService.getBanks();
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data['data'] != null) {
        setState(() {
          _banks = (data['data'] as List).map((e) => BankModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("Banks error: $e");
    }
  }

  void _handleVerify() async {
    if (_accountController.text.isEmpty || (!_isWalletTransfer && _selectedBank == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = _isWalletTransfer
        ? await _apiService.verifyWalletAccount(_accountController.text)
        : await _apiService.verifyAccount(_selectedBank!.code, _accountController.text);

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success') {
          _isVerified = true;
          _verifiedName = _isWalletTransfer ? data['message'] : data['account_name'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Verification failed')));
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _handleTransfer() {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify recipient first')));
      return;
    }
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter amount')));
      return;
    }
    _showConfirmDialog();
  }

  void _showConfirmDialog() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    double fee = _isWalletTransfer ? 0 : (amount > 50000 ? 100 : 50);
    double total = amount + fee;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isWalletTransfer ? 'Confirm Wallet Transfer' : 'Confirm Bank Transfer', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _confirmRow('Recipient', _verifiedName ?? ''),
            _confirmRow('Account', _accountController.text),
            _confirmRow('Bank', _isWalletTransfer ? 'Hamald Wallet' : _selectedBank!.name),
            _confirmRow('Amount', '₦${Utils.formatCurrency(amount.toString())}'),
            _confirmRow('Fee', '₦${Utils.formatCurrency(fee.toString())}'),
            const Divider(),
            _confirmRow('Total Payable', '₦${Utils.formatCurrency(total.toString())}', isBold: true),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPinDialog();
              },
              child: const Text('CONFIRM TRANSFER'),
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
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
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
                _processTransfer(pin);
              }
            },
            child: const Text('SEND'),
          ),
        ],
      ),
    );
  }

  void _processTransfer(String pin) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final Map<String, dynamic> data = {
      'userId': auth.user!.userId,
      'amount': _amountController.text,
      'accountNumber': _accountController.text,
      'bankCode': _isWalletTransfer ? '' : _selectedBank!.code,
      'bankName': _isWalletTransfer ? 'Hamald Wallet' : _selectedBank!.name,
      'pin': pin,
    };

    try {
      final response = _isWalletTransfer
        ? await _apiService.performWalletTransfer(data)
        : await _apiService.performTransfer(data);

      final res = response.data is String ? jsonDecode(response.data) : response.data;

      setState(() => _isLoading = false);
      if (res['status'] == 'success') {
        _showSuccessDialog();
        auth.refreshProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Transfer failed')));
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
        title: const Text('Transfer Successful'),
        content: const Text('Your funds have been transferred successfully.'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('DONE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Money')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _isWalletTransfer = false; _isVerified = false; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isWalletTransfer ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('To Bank', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() { _isWalletTransfer = true; _isVerified = false; }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isWalletTransfer ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('To Wallet', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (!_isWalletTransfer) ...[
              DropdownButtonFormField<BankModel>(
                value: _selectedBank,
                hint: const Text('Select Bank'),
                items: _banks.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                onChanged: (v) => setState(() { _selectedBank = v; _isVerified = false; }),
                decoration: const InputDecoration(labelText: 'Recipient Bank'),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _accountController,
              decoration: InputDecoration(
                labelText: _isWalletTransfer ? 'Recipient Email or Phone' : 'Account Number',
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
                child: Text('Recipient: $_verifiedName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₦ '),
            ),
            const SizedBox(height: 40),
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _isVerified ? _handleTransfer : _handleVerify,
                  child: Text(_isVerified ? 'SEND MONEY' : 'VERIFY RECIPIENT'),
                ),
          ],
        ),
      ),
    );
  }
}
