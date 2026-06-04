class SupportTicketModel {
  final String? id;
  final String? subject;
  final String? message;
  final String? status;
  final String? createdAt;

  SupportTicketModel({
    this.id,
    this.subject,
    this.message,
    this.status,
    this.createdAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id']?.toString(),
      subject: json['subject']?.toString(),
      message: json['message']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }
}
