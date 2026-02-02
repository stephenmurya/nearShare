import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:near_share/features/home/models/product.dart';
import 'package:near_share/features/home/services/product_service.dart';
import 'package:near_share/features/home/presentation/widgets/product_card.dart';
import 'package:near_share/features/home/presentation/widgets/category_selector.dart';
import 'package:near_share/features/home/presentation/pages/product_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductService _productService = ProductService();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'Construction',
    'Event',
    'Film',
    'Power',
    'Industrial',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _productService.loadProducts();
    if (mounted) {
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts
            .where((p) => p.category.toLowerCase() == category.toLowerCase())
            .toList();
      }
    });
  }

  Widget _buildSponsoredSection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 280, // 16:9 approx (180 * 1.55)
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://picsum.photos/seed/${title.length + index}/600/338',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CategorySelector(
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategorySelected: _onCategorySelected,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredProducts.isEmpty
              ? const Center(child: Text('No products found in this category'))
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: Colors.black87,
                  backgroundColor: Colors.white,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Sponsored Section Top
                      SliverToBoxAdapter(
                        child: _buildSponsoredSection('Sponsored Items'),
                      ),

                      // First 6 products (3 rows)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailsPage(
                                        product: _filteredProducts[index],
                                      ),
                                    ),
                                  );
                                },
                                child: ProductCard(
                                  product: _filteredProducts[index],
                                ),
                              );
                            },
                            childCount: _filteredProducts.length > 6
                                ? 6
                                : _filteredProducts.length,
                          ),
                        ),
                      ),

                      // Middle Sponsored Section
                      if (_filteredProducts.length > 6)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: _buildSponsoredSection('Discover More'),
                          ),
                        ),

                      // Remaining products
                      if (_filteredProducts.length > 6)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 16.0,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailsPage(
                                        product: _filteredProducts[index + 6],
                                      ),
                                    ),
                                  );
                                },
                                child: ProductCard(
                                  product: _filteredProducts[index + 6],
                                ),
                              );
                            }, childCount: _filteredProducts.length - 6),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
