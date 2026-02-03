import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:near_share/features/home/models/product.dart';
import 'package:near_share/features/home/services/product_firestore_service.dart';
import 'package:near_share/features/home/presentation/widgets/product_card.dart';
import 'package:near_share/features/home/presentation/widgets/category_selector.dart';
import 'package:near_share/features/home/presentation/pages/product_details_page.dart';
import 'package:near_share/features/home/presentation/widgets/personalized_header.dart';
import 'package:near_share/features/home/presentation/widgets/search_bar.dart'
    as custom;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductFirestoreService _productService = ProductFirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  List<Product> _applyFilters(List<Product> products) {
    List<Product> filtered = products;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where(
            (p) => p.category.toLowerCase() == _selectedCategory.toLowerCase(),
          )
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final name = p.name.toLowerCase();
        final location = (p.location ?? '').toLowerCase();
        return name.contains(query) || location.contains(query);
      }).toList();
    }

    return filtered;
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
        const PersonalizedHeader(),
        custom.SearchBar(
          controller: _searchController,
          onChanged: _onSearchChanged,
        ),
        CategorySelector(
          categories: _categories,
          selectedCategory: _selectedCategory,
          onCategorySelected: _onCategorySelected,
        ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _productService.streamAllProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerGrid();
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Unable to load products right now.'),
                );
              }

              final products = snapshot.data ?? [];
              final filtered = _applyFilters(products);

              if (products.isEmpty) {
                return const Center(
                  child: Text('No gear available in your area yet.'),
                );
              }

              if (filtered.isEmpty) {
                return const Center(
                  child: Text('No products found in this category'),
                );
              }

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildSponsoredSection('Sponsored Items'),
                  ),
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
                                    product: filtered[index],
                                  ),
                                ),
                              );
                            },
                            child: ProductCard(product: filtered[index]),
                          );
                        },
                        childCount: filtered.length > 6 ? 6 : filtered.length,
                      ),
                    ),
                  ),
                  if (filtered.length > 6)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: _buildSponsoredSection('Discover More'),
                      ),
                    ),
                  if (filtered.length > 6)
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
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsPage(
                                      product: filtered[index + 6],
                                    ),
                                  ),
                                );
                              },
                              child: ProductCard(
                                product: filtered[index + 6],
                              ),
                            );
                          },
                          childCount: filtered.length - 6,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildSponsoredSection('Sponsored Items'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildSkeletonCard();
              },
              childCount: 6,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 120,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
