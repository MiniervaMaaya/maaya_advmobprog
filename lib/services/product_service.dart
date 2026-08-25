import 'dart:async';

import '../models/product_model.dart';

class ProductService {
  // Curated animal products using local asset images.
  Future<List<Product>> getAllProducts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return <Product>[
      Product(
        id: 'pedigree_chicken',
        title: 'Pedigree Chopped Adult Dog Food - Chicken',
        description:
            'Complete and balanced chopped dog food made with real chicken and high quality protein.',
        price: 3.49,
        imageUrl: 'assets/images/pedigree_chicken.jpg',
      ),
      Product(
        id: 'pedigree_beef',
        title: 'Pedigree Adult Dog Food - Beef',
        description:
            'Tender beef chunks in gravy, no artificial flavours or added preservatives.',
        price: 3.29,
        imageUrl: 'assets/images/pedigree_beef.jpg',
      ),
      Product(
        id: 'milkbone_treats',
        title: 'Milk-Bone Soft & Chewy Minis',
        description:
            'Bite-sized soft and chewy dog treats, great for training and rewarding.',
        price: 5.99,
        imageUrl: 'assets/images/milkbone_treats.jpg',
      ),
      Product(
        id: 'cat_treats_variety',
        title: 'Cat Treat Sticks - Variety Pack',
        description:
            'Chicken, tuna, and salmon flavoured lickable cat treat sticks, pack of 100.',
        price: 14.99,
        imageUrl: 'assets/images/cat_treats_variety.jpg',
      ),
      Product(
        id: 'cat_snacks_100pc',
        title: 'Cat Snacks - Chicken, Salmon & Tuna (100pcs)',
        description:
            'Creamy lickable cat snacks in three flavours, perfect for treats or medicine time.',
        price: 13.49,
        imageUrl: 'assets/images/cat_snacks_100pc.jpg',
      ),
      Product(
        id: 'meow_mix',
        title: 'Meow Mix Original Choice Dry Cat Food',
        description:
            'Complete and balanced dry cat food with a mix of flavours cats love.',
        price: 11.99,
        imageUrl: 'assets/images/meow_mix.jpg',
      ),
      Product(
        id: 'bird_seed_blend',
        title: 'Organic Seed Blend for Birds',
        description:
            'Natural seed blend suitable for love birds, cockatiels, and other small birds.',
        price: 9.20,
        imageUrl: 'assets/images/bird_seed_blend.jpg',
      ),
      Product(
        id: 'kang_seed',
        title: 'Kang Seed Parrot & Bird Food',
        description:
            'Balanced natural seed mix for parrots, love birds, and cockatiels.',
        price: 7.50,
        imageUrl: 'assets/images/kang_seed.jpg',
      ),
    ];
  }
}
