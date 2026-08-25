class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id']?.toString() ?? '',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        price: (m['price'] is num) ? (m['price'] as num).toDouble() : 0.0,
        imageUrl: m['imageUrl'] ?? '',
      );
}
