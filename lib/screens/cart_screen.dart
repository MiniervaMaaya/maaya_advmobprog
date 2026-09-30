import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../utils/constants.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Cart? _cart;
  Object? _loadError;
  bool _isLoading = true;
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cart = await context.read<CartService>().getCartForUser(
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _cart = cart;
          _loadError = null;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeProduct(int productId) async {
    try {
      final cart = await context.read<CartService>().removeProduct(
        widget.userId,
        productId,
      );
      if (mounted) setState(() => _cart = cart);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _changeQuantity(int productId, int change) async {
    try {
      final cart = await context.read<CartService>().changeQuantity(
        widget.userId,
        productId,
        change,
      );
      if (mounted) setState(() => _cart = cart);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _checkout(Cart cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm checkout'),
        content: Text(
          'Place your order for ${cart.totalQuantity} item${cart.totalQuantity == 1 ? '' : 's'} totaling '
          '\$${cart.discountedTotal.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Place order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCheckingOut = true);
    try {
      final emptyCart = await context.read<CartService>().clearCart(
        widget.userId,
      );
      if (mounted) {
        setState(() => _cart = emptyCart);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveCart = context.watch<CartService>().cartForUser(widget.userId);
    final displayedCart = liveCart ?? _cart;
    return Scaffold(
      appBar: AppBar(title: const Text('My cart')),
      body: _isLoading && displayedCart == null
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null && displayedCart == null
          ? _buildLoadError()
          : _buildCart(displayedCart ?? Cart.empty(widget.userId)),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: AppColors.grey54),
            const SizedBox(height: AppSpacing.md),
            Text(_loadError.toString(), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _loadError = null;
                });
                _loadCart();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart(Cart cart) {
    if (cart.products.isEmpty) {
      return const Center(child: Text('This cart is empty.'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: cart.products.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final product = cart.products[index];
              return _CartProductTile(
                product: product,
                onDecrease: () => _changeQuantity(product.id, -1),
                onIncrease: () => _changeQuantity(product.id, 1),
                onRemove: () => _removeProduct(product.id),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CartSummaryRow(
                  label: '${cart.totalQuantity} items subtotal',
                  value: '\$${cart.total.toStringAsFixed(2)}',
                ),
                const SizedBox(height: AppSpacing.xs),
                _CartSummaryRow(
                  label: 'Discount',
                  value: '-\$${cart.discountSavings.toStringAsFixed(2)}',
                  valueColor: AppColors.sampleCoral,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Divider(height: 1),
                ),
                _CartSummaryRow(
                  label: 'Total',
                  value: '\$${cart.discountedTotal.toStringAsFixed(2)}',
                  emphasize: true,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isCheckingOut ? null : () => _checkout(cart),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sampleBlue,
                      foregroundColor: AppColors.white,
                    ),
                    icon: _isCheckingOut
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined),
                    label: Text(
                      _isCheckingOut
                          ? 'Processing…'
                          : 'Checkout • \$${cart.discountedTotal.toStringAsFixed(2)}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasize;

  const _CartSummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = emphasize ? AppTextStyles.heading3 : AppTextStyles.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style.copyWith(color: valueColor)),
      ],
    );
  }
}

class _CartProductTile extends StatelessWidget {
  final CartProduct product;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  const _CartProductTile({
    required this.product,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 56,
            child: product.thumbnail.isEmpty
                ? const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.sampleBlue,
                  )
                : Image.network(
                    product.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.sampleBlue,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium,
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      '\$${product.discountedPrice.toStringAsFixed(2)} each',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: product.hasDiscount
                            ? AppColors.sampleCoral
                            : AppColors.grey54,
                        fontWeight: product.hasDiscount
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (product.hasDiscount)
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: AppTextStyles.caption.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _QuantityButton(
                      tooltip: 'Decrease ${product.title} quantity',
                      icon: Icons.remove,
                      onPressed: onDecrease,
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${product.quantity}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    _QuantityButton(
                      tooltip: 'Increase ${product.title} quantity',
                      icon: Icons.add,
                      onPressed: onIncrease,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Remove ${product.title}',
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
              Text(
                '\$${(product.discountedPrice * product.quantity).toStringAsFixed(2)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        color: AppColors.sampleBlue,
        disabledColor: AppColors.grey54,
        icon: Icon(icon),
      ),
    );
  }
}
