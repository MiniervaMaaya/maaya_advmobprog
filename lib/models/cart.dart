import '../utils/promotion_policy.dart';

/// Product line returned for a user's cart.
class CartProduct {
  final int id;
  final String title;
  final double price;
  final double discountPercentage;
  final int quantity;
  final String thumbnail;

  const CartProduct({
    required this.id,
    required this.title,
    required this.price,
    this.discountPercentage = 0,
    required this.quantity,
    required this.thumbnail,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse('${json['id']}') ?? 0;
    return CartProduct(
      id: id,
      title: json['title'] as String? ?? 'Product',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPercentage: PromotionPolicy.discountForProduct(id),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  bool get hasDiscount => discountPercentage > 0;
  double get discountedPrice =>
      price * (1 - discountPercentage.clamp(0, 100) / 100);
}

/// Cart summary returned by the user-specific cart endpoint.
class Cart {
  final int userId;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int totalProducts;
  final int totalQuantity;

  double get discountSavings => (total - discountedTotal).clamp(0, total);

  const Cart({
    required this.userId,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    final products = (json['products'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CartProduct.fromJson)
        .where((product) => product.quantity > 0)
        .toList();
    final subtotal = products.fold<double>(
      0,
      (sum, product) => sum + product.price * product.quantity,
    );
    final discountedSubtotal = products.fold<double>(
      0,
      (sum, product) => sum + product.discountedPrice * product.quantity,
    );

    return Cart(
      userId: int.tryParse('${json['userId']}') ?? 0,
      products: products,
      total: subtotal,
      discountedTotal: discountedSubtotal,
      totalProducts:
          (json['totalProducts'] as num?)?.toInt() ?? products.length,
      totalQuantity:
          (json['totalQuantity'] as num?)?.toInt() ??
          products.fold(0, (sum, product) => sum + product.quantity),
    );
  }

  factory Cart.empty(int userId) => Cart(
    userId: userId,
    products: const [],
    total: 0,
    discountedTotal: 0,
    totalProducts: 0,
    totalQuantity: 0,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'products': products
        .map(
          (product) => {
            'id': product.id,
            'title': product.title,
            'price': product.price,
            'discountPercentage': product.discountPercentage,
            'quantity': product.quantity,
            'thumbnail': product.thumbnail,
          },
        )
        .toList(),
    'total': total,
    'discountedTotal': discountedTotal,
    'totalProducts': totalProducts,
    'totalQuantity': totalQuantity,
  };

  Cart withProducts(List<CartProduct> updatedProducts) {
    final validProducts = updatedProducts
        .where((product) => product.quantity > 0)
        .toList();
    final quantity = validProducts.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );
    final subtotal = validProducts.fold<double>(
      0,
      (sum, product) => sum + product.price * product.quantity,
    );
    final discountedSubtotal = validProducts.fold<double>(
      0,
      (sum, product) => sum + product.discountedPrice * product.quantity,
    );
    return Cart(
      userId: userId,
      products: validProducts,
      total: subtotal,
      discountedTotal: discountedSubtotal,
      totalProducts: validProducts.length,
      totalQuantity: quantity,
    );
  }
}
