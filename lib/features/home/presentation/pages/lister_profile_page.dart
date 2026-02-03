import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:near_share/features/home/models/product.dart';
import 'package:near_share/features/home/services/product_service.dart';
import 'package:near_share/features/home/presentation/widgets/product_card.dart';
import 'package:near_share/features/home/presentation/widgets/search_bar.dart'
    as custom;
import 'package:near_share/features/home/presentation/pages/product_details_page.dart';

class ListerProfilePage extends StatefulWidget {
  final String listerName;
  final String? profilePic;
  final double? rating;

  const ListerProfilePage({
    super.key,
    required this.listerName,
    this.profilePic,
    this.rating,
  });

  @override
  State<ListerProfilePage> createState() => _ListerProfilePageState();
}

class _ListerProfilePageState extends State<ListerProfilePage> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allListerProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await _productService.loadProducts();
    if (mounted) {
      setState(() {
        _allListerProducts = products
            .where((p) => p.postedBy == widget.listerName)
            .toList();
        _filteredProducts = _allListerProducts;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allListerProducts;
      } else {
        _filteredProducts = _allListerProducts.where((p) {
          final title = p.name.toLowerCase();
          final location = (p.location ?? '').toLowerCase();
          final q = query.toLowerCase();
          return title.contains(q) || location.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.listerName,
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            IconsaxPlusLinear.arrow_left_1,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header Profile Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.profilePic != null
                      ? NetworkImage(widget.profilePic!)
                      : null,
                  child: widget.profilePic == null
                      ? const Icon(Iconsax.user, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.listerName,
                        style: GoogleFonts.interTight(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.star1,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.rating ?? 0.0} (12 reviews)',
                            style: GoogleFonts.interTight(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verified Lister on NearShare',
                        style: GoogleFonts.interTight(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          custom.SearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),

          // Product Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      'No items found.',
                      style: GoogleFonts.interTight(),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
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
                        child: ProductCard(product: _filteredProducts[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
