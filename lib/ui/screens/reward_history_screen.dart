import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';

class RewardHistoryScreen extends StatelessWidget {
  const RewardHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Reward & Credit History')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.primaryBlue,
              child: Row(
                children: [
                  _summaryItem('Outstanding', '₦${Utils.formatCurrency(user?.outstandingDebt.toString() ?? "0")}', Colors.red.shade100),
                  const Spacer(),
                  _summaryItem('Credit Limit', '₦${Utils.formatCurrency(user?.creditLimit.toString() ?? "0")}', Colors.green.shade100),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Icon(Icons.history_edu, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No credit history found', style: TextStyle(color: Colors.grey)),
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Rewards and Credit are based on your membership level and transaction frequency. Keep using Hamald VTU to unlock more rewards!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
