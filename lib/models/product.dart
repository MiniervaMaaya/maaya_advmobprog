import '../utils/promotion_policy.dart';

class Product {
  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String brand;
  final String thumbnail;
  final List<String> images;

  bool get hasDiscount => discountPercentage > 0;
  double get discountedPrice =>
      price * (1 - discountPercentage.clamp(0, 100) / 100);

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.brand,
    required this.thumbnail,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    return Product(
      id: id,
      title: json['title'] as String? ?? 'Product',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPercentage: PromotionPolicy.discountForProduct(id),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      brand: json['brand'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}
