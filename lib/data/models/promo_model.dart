class PromoModel {
  final String title;
  final String subtitle;
  final String imageUrl;

  PromoModel({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? '',
    );
  }
}
