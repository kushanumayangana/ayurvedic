import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'product_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  static const categories = [
    'All',
    'Oils',
    'Balms',
    'Tablets',
    'Magazines',
    'Herbal Teas',
    'Powders (Churna)',
    'Syrups',
    'Wellness',
  ];

  static bool matchesProduct({
    required Map<String, dynamic> product,
    required String category,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final productCategory = (product['category'] ?? 'General')
        .toString()
        .trim()
        .toLowerCase();
    final selectedCategory = category.trim().toLowerCase();
    final matchesCategory =
        selectedCategory == 'all' ||
        productCategory == selectedCategory ||
        (selectedCategory == 'balms' && productCategory == 'balm') ||
        (selectedCategory == 'oils' && productCategory == 'oil');
    if (!matchesCategory) return false;
    if (normalizedQuery.isEmpty) return true;
    return [
      product['title'],
      product['category'],
      product['description'],
      product['ownerName'],
    ].any(
      (value) =>
          value?.toString().toLowerCase().contains(normalizedQuery) ?? false,
    );
  }

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final _searchController = TextEditingController();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productsStream = FirebaseFirestore.instance
        .collection('products')
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF174C3C);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text(
          'Marketplace',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF5F8F6),
        foregroundColor: forest,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find your everyday wellness',
                  style: TextStyle(
                    color: forest,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Explore trusted Ayurvedic products and remedies.',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search products, oils, balms...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: forest, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: MarketplacePage.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = MarketplacePage.categories[index];
                final selected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                  selectedColor: forest,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : forest,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected ? forest : Colors.grey.shade200,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _MarketplaceMessage(
                    icon: Icons.error_outline,
                    message: 'Products could not be loaded. Please try again.',
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = (snapshot.data?.docs ?? [])
                    .where(
                      (doc) => MarketplacePage.matchesProduct(
                        product: doc.data(),
                        category: _selectedCategory,
                        query: _searchQuery,
                      ),
                    )
                    .toList();

                if (products.isEmpty) {
                  return _MarketplaceMessage(
                    icon: Icons.search_off,
                    message:
                        _searchQuery.trim().isEmpty &&
                            _selectedCategory == 'All'
                        ? 'No products are available yet.'
                        : 'No products found. Try another category or search.',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 4 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.69,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final document = products[index];
                        return _ProductGridCard(
                          product: document.data(),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ProductDetailPage(
                                product: document.data(),
                                productId: document.id,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _MarketplaceMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF2F8062)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade700, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _ProductGridCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF174C3C);
    final image = _productImage(product);
    final title = (product['title'] ?? 'Ayurvedic product').toString();
    final category = (product['category'] ?? 'General').toString();
    final price = (product['price'] ?? '0').toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image.isNotEmpty)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder(),
                    )
                  else
                    _imagePlaceholder(),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: forest,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 9, 11, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF203A32),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'LKR $price',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: forest,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _productImage(Map<String, dynamic> data) {
    final directImage = data['imageUrl']?.toString().trim() ?? '';
    if (directImage.isNotEmpty) return directImage;
    final images = data['imageUrls'];
    if (images is List) {
      for (final image in images) {
        final url = image?.toString().trim() ?? '';
        if (url.isNotEmpty) return url;
      }
    }
    return '';
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFEAF1EC),
    child: const Center(
      child: Icon(Icons.spa_outlined, color: Color(0xFF59806B), size: 38),
    ),
  );
}
