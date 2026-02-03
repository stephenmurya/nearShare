import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:near_share/core/theme/app_theme.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:near_share/features/home/models/product.dart';
import 'package:near_share/features/home/presentation/providers/product_provider.dart';
import 'package:near_share/features/home/presentation/pages/product_edit_page.dart';
import 'package:near_share/features/home/presentation/widgets/search_bar.dart' as custom;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

class MyItemsPage extends StatefulWidget {
  const MyItemsPage({super.key});

  @override
  State<MyItemsPage> createState() => _MyItemsPageState();
}

class _MyItemsPageState extends State<MyItemsPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.user?.uid;
    final provider = Provider.of<ProductProvider>(context);
    final myProducts = provider.myProducts(userId).where((p) {
      if (_query.isEmpty) return true;
      return p.name.toLowerCase().contains(_query.toLowerCase()) ||
          p.category.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: custom.SearchBar(
            controller: TextEditingController(text: _query),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
      ),
      body: myProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "You don't have any products yet",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductEditPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                      ),
                      child: const Text('Add Product'),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final p = myProducts[index];
                return ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: Hero(
                    tag: 'product-img-${p.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: p.image,
                        width: 84,
                        height: 64,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Container(
                          width: 84,
                          height: 64,
                          color: Colors.grey[200],
                        ),
                      ),
                    ),
                  ),
                  title: Text(p.name, style: Theme.of(context).textTheme.bodyLarge),
                  subtitle: Text(p.category, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProductEditPage(product: p)),
                        );
                      } else if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete product?'),
                            content: const Text('This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          provider.deleteProduct(p.id);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: myProducts.length,
            ),
      floatingActionButton: myProducts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductEditPage()),
                );
              },
              icon: const Icon(Iconsax.add),
              label: const Text('Add Product'),
              backgroundColor: AppTheme.primaryBlue,
            )
          : null,
    );
  }
}
