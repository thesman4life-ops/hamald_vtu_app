import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/services/api_service.dart';

class SchoolScreen extends StatefulWidget {
  const SchoolScreen({super.key});

  @override
  State<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends State<SchoolScreen> {
  final _profileIdController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _phoneController = TextEditingController();

  String? _selectedExam;
  String? _selectedJambType;
  bool _isLoading = false;
  bool _isVerified = false;
  String? _verifiedName;
  double _unitPrice = 0.0;
  final _apiService = ApiService();

  final List<Map<String, dynamic>> _exams = [
    {'name': 'WAEC Result Checker', 'id': 'waec', 'vCode': 'waecdirect'},
    {'name': 'NECO Result Checker', 'id': 'neco', 'vCode': 'neco-result-checker'},
    {'name': 'NABTEB Result Checker', 'id': 'nabteb', 'vCode': 'nabteb-direct'},
    {'name': 'JAMB Profile PIN', 'id': 'jamb', 'vCode': ''},
  ];

  List<Map<String, dynamic>> _jambTypes = [];

  void _fetchPrice() async {
    if (_selectedExam == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getServiceVariations(_selectedExam!);
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      List? variations = data['plans'] ?? (data['content'] != null ? data['content']['variations'] : null) ?? data['variations'];

      if (variations != null) {
        if (_selectedExam == 'jamb') {
          _jambTypes = variations.map((e) => {
            'name': e['name'],
            'code': e['variation_code'],
            'price': double.tryParse(e['variation_amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
          }).toList();
          if (_jambTypes.isNotEmpty) {
            _selectedJambType = _jambTypes[0]['code'];
            _unitPrice = _jambTypes[0]['price'];
          }
        } else {
          final targetCode = _exams.firstWhere((e) => e['id'] == _selectedExam)['vCode'];
          final selectedVar = variations.firstWhere((e) => e['variation_code'] == targetCode, orElse: () => variations[0]);
          _unitPrice = double.tryParse(selectedVar['variation_amount'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        }
      }
    } catch (e) {
      debugPrint("Price fetch error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleVerify() async {
    if (_profileIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Profile ID')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.verifySchool('jamb', _profileIdController.text, _selectedJambType ?? 'utme-no-mock');
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      setState(() {
        _isLoading = false;
        if (data['status'] == 'success' || data['code'] == '000') {
          _isVerified = true;
          _verifiedName = data['customerName'] ?? (data['content'] != null ? data['content']['Customer_Name'] : 'Verified Student');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Verification failed')));
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _handlePurchase() {
    if (_selectedExam == 'jamb' && !_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify Profile ID first')));
      return;
    }
    if (_phoneController.text.isEmpty || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    _showConfirmDialog();
  }

  void _showConfirmDialog() {
    int qty = int.tryParse(_quantityController.text) ?? 1;
    double total = qty * _unitPrice;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirm Exam PIN Purchase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _confirmRow('Exam', _exams.firstWhere((e) => e['id'] == _selectedExam)['name']),
            if (_verifiedName != null) _confirmRow('Student', _verifiedName!),
            _confirmRow('Quantity', qty.toString()),
            _confirmRow('Total Amount', '₦${Utils.formatCurrency(total.toString())}', isBold: true),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPinDialog();
              },
              child: const Text('CONFIRM PURCHASE'),
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
    int qty = int.tryParse(_quantityController.text) ?? 1;

    final Map<String, dynamic> data = {
      'userId': auth.user!.userId,
      'serviceId': _selectedExam,
      'variationCode': _selectedExam == 'jamb' ? _selectedJambType : _exams.firstWhere((e) => e['id'] == _selectedExam)['vCode'],
      'profileId': _profileIdController.text,
      'quantity': qty.toString(),
      'amount': (qty * _unitPrice).toString(),
      'phoneNumber': _phoneController.text,
      'pin': pin,
    };

    try {
      final response = await _apiService.buySchoolPin(data);
      final res = response.data is String ? jsonDecode(response.data) : response.data;

      setState(() => _isLoading = false);
      if (res['status'] == 'success' || res['status'] == 'successful' || res['status'] == '000') {
        _showSuccessDialog(res['pin_id'] ?? res['token']);
        auth.refreshProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Transaction failed')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _showSuccessDialog(String? pin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('Purchase Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your exam PIN has been generated.'),
            if (pin != null) ...[
              const SizedBox(height: 16),
              const Text('PIN / TOKEN:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(pin, style: const TextStyle(fontSize: 18, color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(title: const Text('Exam PIN')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedExam,
              hint: const Text('Select Exam Type'),
              items: _exams.map((e) => DropdownMenuItem(value: e['id'] as String, child: Text(e['name'] as String))).toList(),
              onChanged: (v) => setState(() {
                _selectedExam = v;
                _isVerified = false;
                _fetchPrice();
              }),
              decoration: const InputDecoration(labelText: 'Exam Provider'),
            ),
            const SizedBox(height: 16),
            if (_selectedExam == 'jamb') ...[
              DropdownButtonFormField<String>(
                value: _selectedJambType,
                hint: const Text('Select JAMB Type'),
                items: _jambTypes.map((e) => DropdownMenuItem(value: e['code'] as String, child: Text(e['name'] as String))).toList(),
                onChanged: (v) => setState(() {
                  _selectedJambType = v;
                  _isVerified = false;
                  _unitPrice = _jambTypes.firstWhere((e) => e['code'] == v)['price'];
                }),
                decoration: const InputDecoration(labelText: 'JAMB Pin Type'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _profileIdController,
                decoration: InputDecoration(
                  labelText: 'JAMB Profile ID',
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
                  child: Text('Student: $_verifiedName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ),
              ],
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Recipient Phone Number'),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('₦${Utils.formatCurrency(((int.tryParse(_quantityController.text) ?? 1) * _unitPrice).toString())}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: (_selectedExam == 'jamb' && !_isVerified) ? _handleVerify : _handlePurchase,
                  child: Text((_selectedExam == 'jamb' && !_isVerified) ? 'VERIFY PROFILE' : 'BUY PIN'),
                ),
          ],
        ),
      ),
    );
  }
}
