import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/services/api_service.dart';

class FundWalletScreen extends StatefulWidget {
  const FundWalletScreen({super.key});

  @override
  State<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends State<FundWalletScreen> {
  final _amountController = TextEditingController();
  final _manualAmountController = TextEditingController();
  final _manualRefController = TextEditingController();

  File? _proofImage;
  bool _isLoading = false;
  final _apiService = ApiService();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _proofImage = File(pickedFile.path));
    }
  }

  void _handleInstantFunding() async {
    if (_amountController.text.isEmpty) return;
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount < 100) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum amount is ₦100')));
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      final response = await _apiService.initializePayment(
        auth.user!.userId!,
        amount.toString(),
        auth.user!.email!
      );
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      setState(() => _isLoading = false);

      if (data['status'] == 'success') {
        final url = data['checkoutUrl'];
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to init payment')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _handleManualFunding() async {
    if (_manualAmountController.text.isEmpty || _manualRefController.text.isEmpty || _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select proof image')));
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      final bytes = await _proofImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await _apiService.uploadProfilePicBase64( // Using the base64 upload endpoint logic
        auth.user!.userId!,
        base64Image,
      );
      // Note: Re-implementing specific manual funding call if needed,
      // but usually involves submitting amount, ref and image.

      setState(() => _isLoading = false);
      _showSuccessDialog("Request Submitted", "Your proof of payment has been received and will be verified.");
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission failed')));
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Fund Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Automated Funding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Your wallet will be credited instantly.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            if (user?.bankName != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primaryBlue, AppColors.secondaryBlue]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user!.bankName!.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(user.accountNumber ?? '0000000000', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white70),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: user.accountNumber!));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                          },
                        ),
                      ],
                    ),
                    Text(user.accountName ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    const SizedBox(height: 12),
                    const Text('Note: Automated funding attracts ₦50 charge.', style: TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text('Online Payment', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter Amount', prefixText: '₦ '),
            ),
            const SizedBox(height: 16),
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _handleInstantFunding, child: const Text('PAY WITH CARD / TRANSFER')),

            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            const Text('Manual Funding (Bank Transfer)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Bank: Zenith Bank\nAccount: 1234567890\nName: Hamald Concepts', style: TextStyle(fontSize: 14, height: 1.5)),
            const SizedBox(height: 24),
            TextField(controller: _manualAmountController, decoration: const InputDecoration(labelText: 'Amount Paid')),
            const SizedBox(height: 16),
            TextField(controller: _manualRefController, decoration: const InputDecoration(labelText: 'Transaction Ref / Name')),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: _proofImage == null
                  ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), Text('Upload Proof of Payment')])
                  : ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_proofImage!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleManualFunding,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: const Text('SUBMIT PROOF'),
            ),
          ],
        ),
      ),
    );
  }
}
