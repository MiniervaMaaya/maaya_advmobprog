import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';
import 'cart_screen.dart';

class DetailScreen extends StatefulWidget {
  final Product product;

  const DetailScreen({super.key, required this.product});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isAdding = false;

  Future<void> _addToCart() async {
    final userId = context.read<UserService>().currentUser?.id;
    if (userId == null) return;
    final navigator = Navigator.of(context);
    setState(() => _isAdding = true);
    try {
      final cart = await context.read<CartService>().addProduct(
        userId,
        widget.product,
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            content: Text('${widget.product.title} added to cart'),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                if (navigator.mounted) {
                  navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) => CartScreen(userId: cart.userId),
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.sampleBlue,
        foregroundColor: AppColors.white,
        title: const Text('Product details'),
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: Image.network(
              product.images.isNotEmpty
                  ? product.images.first
                  : product.thumbnail,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.primaryLight,
                child: Icon(Icons.image_not_supported_outlined, size: 52),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.sampleBlue,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(product.title, style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '\$${product.discountedPrice.toStringAsFixed(2)}',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.sampleBlue,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey54,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sampleCoral,
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.sm,
                          ),
                        ),
                        child: Text(
                          'Save ${product.discountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(product.description, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isAdding ? null : _addToCart,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sampleBlue,
                    ),
                    icon: _isAdding
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
