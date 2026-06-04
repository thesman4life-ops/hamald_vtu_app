import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../core/app_colors.dart';
import '../../core/utils.dart';
import '../widgets/transaction_item.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = "";
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Airtime", "Data", "Utility", "Cable", "Wallet"];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final allTransactions = auth.user?.transactions ?? [];

    final filteredTransactions = allTransactions.where((t) {
      bool matchesSearch = t.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? true;
      bool matchesFilter = _selectedFilter == "All" ||
                          (t.type?.toLowerCase().contains(_selectedFilter.toLowerCase()) ?? false);
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: _filters.map((f) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _selectedFilter == f,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = f);
                      },
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshProfile(),
        child: filteredTransactions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No transactions found', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) => TransactionItem(
                  transaction: filteredTransactions[index],
                  onTap: () => _showTransactionDetails(context, filteredTransactions[index]),
                ),
              ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionModel t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text('₦${Utils.formatCurrency(t.amount ?? '0')}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text(t.status?.toUpperCase() ?? 'SUCCESSFUL', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _detailRow('Service', t.type ?? 'Transaction'),
              _detailRow('Description', t.description ?? ''),
              _detailRow('Date', t.date ?? ''),
              _detailRow('Reference', t.reference ?? t.id ?? ''),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
