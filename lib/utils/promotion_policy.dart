class PromotionPolicy {
  static const Map<int, double> _selectedDiscounts = {
    1: 10,
    5: 15,
    10: 20,
    15: 10,
    20: 25,
    25: 15,
    30: 20,
  };

  static double discountForProduct(int productId) =>
      _selectedDiscounts[productId] ?? 0;

  const PromotionPolicy._();
}
