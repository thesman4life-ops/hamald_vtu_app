import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../data/models/ticket_reply_model.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';

class TicketDetailsScreen extends StatefulWidget {
  final String ticketId;
  final String subject;
  final String status;

  const TicketDetailsScreen({
    super.key,
    required this.ticketId,
    required this.subject,
    required this.status,
  });

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final _messageController = TextEditingController();
  final _apiService = ApiService();
  List<TicketReplyModel> _replies = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReplies();
  }

  Future<void> _loadReplies() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getTicketReplies(widget.ticketId);
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data is List) {
        setState(() {
          _replies = data.map((e) => TicketReplyModel.fromJson(e)).toList();
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Load replies error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final auth = context.read<AuthProvider>();
    try {
      final response = await _apiService.replyTicket(widget.ticketId, auth.user!.userId!, message);
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data['status'] == 'success') {
        _messageController.clear();
        _loadReplies();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send reply')));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isClosed = widget.status.toLowerCase() == 'closed';

    return Scaffold(
      appBar: AppBar(title: Text(widget.subject)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _replies.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _replies.length,
                    itemBuilder: (context, index) {
                      final reply = _replies[index];
                      bool isStaff = reply.senderType?.toLowerCase() == 'staff';
                      return _buildChatBubble(reply, isStaff);
                    },
                  ),
          ),
          if (!isClosed) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(TicketReplyModel reply, bool isStaff) {
    return Align(
      alignment: isStaff ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isStaff ? Colors.grey.shade200 : AppColors.primaryBlue,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isStaff ? 0 : 16),
            bottomRight: Radius.circular(isStaff ? 16 : 0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isStaff)
              Text(
                reply.agentName ?? 'Hamald Support',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            Text(
              reply.message ?? '',
              style: TextStyle(color: isStaff ? Colors.black87 : Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              reply.createdAt ?? '',
              style: TextStyle(fontSize: 9, color: isStaff ? Colors.black54 : Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}
