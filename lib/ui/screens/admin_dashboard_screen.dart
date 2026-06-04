import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  Map<String, dynamic>? _stats;
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final df = DateFormat('yyyy-MM-dd');
    try {
      final response = await _apiService.getAdminStats(
        auth.user!.userId!,
        df.format(_fromDate),
        df.format(_toDate),
      );
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data['status'] == 'success') {
        setState(() => _stats = data);
      }
    } catch (e) {
      debugPrint("Load admin stats error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else _toDate = picked;
      });
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Filters
              Row(
                children: [
                  Expanded(
                    child: _dateButton('From', _fromDate, () => _selectDate(context, true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateButton('To', _toDate, () => _selectDate(context, false)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isLoading && _stats == null)
                const Center(child: CircularProgressIndicator())
              else if (_stats != null) ...[
                const Text('Platform Liquidity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _statCard('VTPass Bal', _stats!['vtpassBalance'], Colors.blue),
                    _statCard('Squad Bal', _stats!['squadBalance'], Colors.purple),
                    _statCard('CDH Bal', _stats!['cdhBalance'], Colors.orange),
                    _statCard('Float', _stats!['walletFloat'], Colors.green),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Periodic Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _statRow('Total Sales', '₦${Utils.formatCurrency(_stats!['totalSales']?.toString() ?? "0")}', Icons.trending_up, Colors.green),
                _statRow('Total Profit', '₦${Utils.formatCurrency(_stats!['totalProfit']?.toString() ?? "0")}', Icons.account_balance_wallet, Colors.teal),
                const SizedBox(height: 12),
                _statRow('Total Users', _stats!['totalUsers'].toString(), Icons.people, Colors.blue),
                _statRow('Successful Trans', _stats!['successfulTransactions'].toString(), Icons.check_circle, Colors.green),
                _statRow('Failed Trans', _stats!['failedTransactions'].toString(), Icons.error, Colors.red),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateButton(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(
            '₦${Utils.formatCurrency(value?.toString() ?? "0")}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}
