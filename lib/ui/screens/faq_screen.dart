import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  final List<Map<String, String>> faqs = const [
    {
      'q': 'How do I fund my wallet?',
      'a': 'You can fund your wallet via automated bank transfer to your dedicated account number displayed on the home dashboard. Your wallet will be credited instantly.'
    },
    {
      'q': 'Are there any charges for funding?',
      'a': 'No! Hamald VTU offers 0% deposit charges on all automated wallet fundings.'
    },
    {
      'q': 'How long does data delivery take?',
      'a': 'Data and Airtime deliveries are 100% automated and take only 5-30 seconds after payment.'
    },
    {
      'q': 'What if my transaction fails but I am debited?',
      'a': 'In the rare case of a network failure, the system automatically initiates a refund within 24 hours. You can also contact support for assistance.'
    },
    {
      'q': 'How do I become a Gold or Diamond member?',
      'a': 'Membership levels are based on your total transaction volume. Spend over ₦200,000 for Gold and ₦400,000 for Diamond to unlock VIP pricing.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequently Asked Questions')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(faq['a']!, style: const TextStyle(color: Colors.black87, height: 1.5)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
