class TicketReplyModel {
  final String? id;
  final String? message;
  final String? senderType;
  final String? agentName;
  final String? createdAt;

  TicketReplyModel({
    this.id,
    this.message,
    this.senderType,
    this.agentName,
    this.createdAt,
  });

  factory TicketReplyModel.fromJson(Map<String, dynamic> json) {
    return TicketReplyModel(
      id: json['id']?.toString(),
      message: json['message']?.toString(),
      senderType: json['sender_type']?.toString(),
      agentName: json['agent_name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
