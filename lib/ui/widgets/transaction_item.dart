import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/models/transaction_model.dart';
import 'package:intl/intl.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = transaction.status?.toLowerCase() ?? 'pending';
    Color statusColor = AppColors.pendingYellow;
    if (status.contains('success') || status == 'delivered') {
      statusColor = AppColors.successGreen;
    } else if (status.contains('fail') || status == 'rejected') {
      statusColor = AppColors.errorRed;
    }

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
        child: const Icon(Icons.receipt_long, color: AppColors.primaryBlue),
      ),
      title: Text(
        transaction.type?.toUpperCase() ?? 'TRANSACTION',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        transaction.date ?? '',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₦${transaction.amount}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
