import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../data/models/support_ticket_model.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'ticket_details_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _messageController = TextEditingController();
  String _selectedIssue = 'General Support';
  String _selectedPriority = 'medium';
  final List<String> _issues = ['Airtime', 'Data', 'Electricity', 'Cable TV', 'Exam Pins', 'Fund Transfer', 'Wallet/Funding', 'Account/Profile', 'General Support'];
  final List<String> _priorities = ['low', 'medium', 'high'];
  
  final _apiService = ApiService();
  List<SupportTicketModel> _tickets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    try {
      final response = await _apiService.getUserTickets(auth.user!.userId!);
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data is List) {
        setState(() {
          _tickets = data.map((e) => SupportTicketModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint("Load tickets error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _launchWhatsApp() async {
    final auth = context.read<AuthProvider>();
    final userName = auth.user?.fullName ?? "User";
    final message = "Hello Hamald Concepts, my name is $userName. I need assistance with the Hamald VTU App.";
    final url = "whatsapp://send?phone=2349065057232&text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _handleSubmitTicket() async {
    if (_messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please explain your issue')));
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.createTicket(
        auth.user!.userId!,
        _selectedIssue,
        _messageController.text.trim(),
        _selectedPriority,
      );
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket opened successfully!')));
        _messageController.clear();
        _loadTickets();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open ticket')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support Desk')),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Need Help?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),

              _supportCard(Icons.chat_bubble, 'Chat with Us', 'Message us on WhatsApp', _launchWhatsApp, Colors.green),
              _supportCard(Icons.email, 'Email Support', 'support@hamaldtechltd.com.ng', () => launchUrl(Uri.parse('mailto:support@hamaldtechltd.com.ng')), Colors.red),

              const SizedBox(height: 32),
              const Text('My Support Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              if (_isLoading && _tickets.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (_tickets.isEmpty)
                const Center(child: Text("You have no support tickets", style: TextStyle(color: Colors.grey)))
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return _buildTicketCard(ticket);
                  },
                ),

              const SizedBox(height: 40),
              const Text('Open a New Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedIssue,
                items: _issues.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                onChanged: (v) => setState(() => _selectedIssue = v!),
                decoration: const InputDecoration(labelText: 'Issue Category'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _selectedPriority = v!),
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Explain your issue...', alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmitTicket,
                  child: const Text('SUBMIT TICKET'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket) {
    Color statusColor = Colors.grey;
    if (ticket.status?.toLowerCase() == 'open') statusColor = Colors.orange;
    if (ticket.status?.toLowerCase() == 'replied') statusColor = Colors.blue;
    if (ticket.status?.toLowerCase() == 'closed') statusColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailsScreen(
          ticketId: ticket.id!,
          subject: ticket.subject!,
          status: ticket.status!,
        ))),
        title: Text(ticket.subject ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ID: #${ticket.id} • ${ticket.createdAt ?? ""}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
          child: Text(
            (ticket.status ?? "OPEN").toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _supportCard(IconData icon, String title, String subtitle, VoidCallback onTap, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}

  Widget _supportCard(IconData icon, String title, String subtitle, VoidCallback onTap, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
