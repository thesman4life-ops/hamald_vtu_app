import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder for notifications
    final List<Map<String, String>> notifications = [
      {'title': 'Welcome to Hamald VTU', 'body': 'Start enjoying fast and reliable recharges today.', 'time': '1 day ago'},
      {'title': 'Wallet Credited', 'body': 'Your wallet has been credited with ₦5,000.00.', 'time': '2 days ago'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(backgroundColor: AppColors.bgBlueLight, child: Icon(Icons.notifications, color: AppColors.primaryBlue)),
                    title: Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(n['body']!),
                        const SizedBox(height: 8),
                        Text(n['time']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
