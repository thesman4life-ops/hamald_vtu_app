import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../data/models/user_model.dart';

class FundAccountDialog extends StatelessWidget {
  final UserModel? user;
  const FundAccountDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet, size: 50, color: AppColors.primaryBlue),
            const SizedBox(height: 16),
            const Text(
              "Fund Your Wallet",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Transfer funds to your dedicated account below to fund your wallet instantly.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _infoBox("Bank Name", user?.bankName ?? "N/A"),
            const SizedBox(height: 12),
            _infoBox("Account Number", user?.accountNumber ?? "N/A", canCopy: true, context: context),
            const SizedBox(height: 12),
            _infoBox("Account Name", user?.accountName ?? "N/A"),
            const SizedBox(height: 24),
            const Text(
              "Note: 0% Deposit Charge! What you transfer is what you get.",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, {bool canCopy = false, BuildContext? context}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: AppColors.primaryBlue),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                if (context != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label copied!")));
                }
              },
            ),
        ],
      ),
    );
  }
}
