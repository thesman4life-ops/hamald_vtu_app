import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/services/api_service.dart';
import '../../data/models/data_plan.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _phoneController = TextEditingController();
  String? _selectedNetwork;
  String? _selectedCategory;
  DataPlan? _selectedPlan;
  bool _isLoading = false;
  final _apiService = ApiService();

  Map<String, List<DataPlan>> _categorizedPlans = {};
  final List<Map<String, String>> _networks = [
    {'name': 'MTN', 'key': 'mtn-data'},
    {'name': 'GLO', 'key': 'glo-data'},
    {'name': 'Airtel', 'key': 'airtel-data'},
    {'name': '9Mobile', 'key': 'etisalat-data'},
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
    if (RegExp(r'0703|0706|0803|0806|0810|0813|0814|0816|0903|0906|0913|0916').hasMatch(prefix)) detected = 'mtn-data';
    else if (RegExp(r'0705|0805|0807|0811|0815|0905|0915').hasMatch(prefix)) detected = 'glo-data';
    else if (RegExp(r'0701|0708|0802|0808|0812|0901|0902|0904|0907|0912').hasMatch(prefix)) detected = 'airtel-data';
    else if (RegExp(r'0809|0817|0818|0908|0909').hasMatch(prefix)) detected = 'etisalat-data';

    if (detected != null && detected != _selectedNetwork) {
      setState(() {
        _selectedNetwork = detected;
        _fetchPlans();
      });
    }
  }

  void _fetchPlans() async {
    if (_selectedNetwork == null) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getServiceVariations(_selectedNetwork!);
      final data = response.data is String ? jsonDecode(response.data) : response.data;

      if (data['categorized_plans'] != null) {
        Map<String, dynamic> cats = data['categorized_plans'];
        _categorizedPlans = cats.map((key, value) => MapEntry(
          key,
          (value as List).map((e) => DataPlan.fromJson(e)).toList()
        ));

        setState(() {
          _selectedCategory = _categorizedPlans.keys.first;
          _selectedPlan = null;
        });
      }
    } catch (e) {
      debugPrint("Plans fetch error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePurchase() {
    if (_selectedPlan == null || _phoneController.text.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a plan and enter phone number')));
      return;
    }
    _showConfirmDialog();
  }

  void _showConfirmDialog() {
    double faceValue = double.tryParse(_selectedPlan!.originalPrice) ?? 0;
    double toPay = double.tryParse(_selectedPlan!.amount) ?? 0;
    double savings = faceValue - toPay;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirm Data Purchase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _confirmRow('Network', _selectedNetwork!.split('-')[0].toUpperCase()),
            _confirmRow('Plan', _selectedPlan!.planName),
            _confirmRow('Phone', _phoneController.text),
            _confirmRow('Face Value', '₦${Utils.formatCurrency(faceValue.toString())}'),
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
      'planId': _selectedPlan!.planId,
      'amount': _selectedPlan!.originalPrice,
      'phoneNumber': _phoneController.text,
      'pin': pin,
    };

    try {
      final response = await _apiService.buyData(data);
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
        title: const Text('Purchase Successful'),
        content: const Text('Your data bundle has been processed successfully.'),
        actions: [
          ElevatedButton(onPressed: () => Navigator.popUntil(context, (route) => route.isFirst), child: const Text('DONE')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buy Data')),
      body: _isLoading && _categorizedPlans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        _fetchPlans();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: _selectedNetwork == n['key'] ? AppColors.primaryBlue : Colors.grey.shade300, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: _selectedNetwork == n['key'] ? AppColors.primaryBlue.withOpacity(0.05) : null,
                        ),
                        child: Text(n['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_categorizedPlans.isNotEmpty) ...[
                    const Text('Select Category', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categorizedPlans.keys.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() {
                        _selectedCategory = v;
                        _selectedPlan = null;
                      }),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    const Text('Select Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.0,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _categorizedPlans[_selectedCategory]?.length ?? 0,
                      itemBuilder: (context, index) {
                        final plan = _categorizedPlans[_selectedCategory]![index];
                        final isSelected = _selectedPlan == plan;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedPlan = plan),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300, width: 2),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected ? AppColors.primaryBlue.withOpacity(0.05) : Colors.white,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(plan.planName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                Text('₦${Utils.formatCurrency(plan.amount)}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 40),
                  _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(onPressed: _handlePurchase, child: const Text('BUY DATA')),
                ],
              ),
            ),
    );
  }
}
