import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../widgets/custom_text.dart';

class ProductScreen extends StatelessWidget {
  final Product product;
  const ProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(product.imageUrl, width: double.infinity, height: 220, fit: BoxFit.cover),
              const SizedBox(height: 12),
              CustomText(text: product.title, fontSize: 20, fontWeight: FontWeight.bold),
              const SizedBox(height: 8),
              CustomText(text: 'P${product.price.toStringAsFixed(2)}', fontSize: 18),
              const SizedBox(height: 12),
              CustomText(text: product.description),
            ],
          ),
        ),
      ),
    );
  }
}
