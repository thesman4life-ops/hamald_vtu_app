import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final spent = user?.totalSpent ?? 0.0;
    final level = user?.userLevel ?? "Bronze";

    double nextGoal = 100000;
    String nextLevel = "Silver";
    if (spent < 100000) { nextGoal = 100000; nextLevel = "Silver"; }
    else if (spent < 200000) { nextGoal = 200000; nextLevel = "Gold"; }
    else if (spent < 400000) { nextGoal = 400000; nextLevel = "Diamond"; }

    double progress = (spent / nextGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Membership Tiers')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primaryBlue, AppColors.secondaryBlue]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(level.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text('Current Status', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(value: progress, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white)),
                  const SizedBox(height: 12),
                  Text('₦${Utils.formatCurrency(spent.toString())} / ₦${Utils.formatCurrency(nextGoal.toString())}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Spend ₦${Utils.formatCurrency((nextGoal - spent).toString())} more to unlock $nextLevel', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _tierCard('Bronze', 'Standard pricing for all services.', Colors.brown, level == 'Bronze'),
            _tierCard('Silver', 'Get 1% off all data and airtime purchases.', Colors.grey, level == 'Silver'),
            _tierCard('Gold', 'Get 2% off all services + cheaper cable TV.', Colors.amber, level == 'Gold'),
            _tierCard('Diamond', 'VIP pricing + dedicated support priority.', Colors.cyan, level == 'Diamond'),
          ],
        ),
      ),
    );
  }

  Widget _tierCard(String title, String desc, Color color, bool isCurrent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(Icons.stars, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc),
        trailing: isCurrent ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: const Text('CURRENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ) : null,
      ),
    );
  }
}
