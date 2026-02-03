import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:near_share/core/theme/app_theme.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:near_share/features/auth/presentation/widgets/auth_guard_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:near_share/features/home/models/product.dart';
import 'package:near_share/features/home/presentation/pages/product_details_page.dart';
import 'package:near_share/features/home/presentation/pages/product_form_page.dart';
import 'package:near_share/features/home/services/product_firestore_service.dart';
import 'package:intl/intl.dart';

class MyProductsPage extends StatelessWidget {
  MyProductsPage({super.key});

  final ProductFirestoreService _service = ProductFirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isGuest = user == null || user.isAnonymous;
    final theme = Theme.of(context);

    if (isGuest) {
      return const AuthRequiredView(
        message: 'Sign in to manage your products',
      );
    }

    return StreamBuilder<List<Product>>(
      stream: _service.streamUserProducts(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong. Please try again.',
              style: theme.textTheme.bodyLarge,
            ),
          );
        }

        final products = snapshot.data ?? [];
        final isEmpty = products.isEmpty;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: isEmpty
              ? _EmptyState(
                  onAdd: () {
                    final currentUser =
                        fb_auth.FirebaseAuth.instance.currentUser;
                    if (currentUser == null || currentUser.isAnonymous) {
                      showAuthGuardSheet(
                        context,
                        title: 'Sign in to start listing',
                        message:
                            'Sign in to start listing your gear and manage your rentals.',
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductFormPage(),
                      ),
                    );
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductManagementCard(
                      product: product,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductFormPage(product: product),
                          ),
                        );
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                'Delete Product',
                                style: GoogleFonts.interTight(),
                              ),
                              content: Text(
                                'This action cannot be undone.',
                                style: GoogleFonts.interTight(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.interTight(),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(
                                    'Delete',
                                    style: GoogleFonts.interTight(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirm == true) {
                          await _service.deleteProduct(product.id);
                        }
                      },
                      onView: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailsPage(product: product),
                          ),
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      final currentUser =
                          fb_auth.FirebaseAuth.instance.currentUser;
                      if (currentUser == null || currentUser.isAnonymous) {
                        showAuthGuardSheet(
                          context,
                          title: 'Sign in to start listing',
                          message:
                              'Sign in to start listing your gear and manage your rentals.',
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductFormPage(),
                        ),
                      );
                    },
                    icon: const Icon(IconsaxPlusLinear.add),
                    label: Text(
                      'Add Product',
                      style: GoogleFonts.interTight(),
                    ),
                  ),
                ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You don't have any products yet",
              textAlign: TextAlign.center,
              style: GoogleFonts.interTight(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(IconsaxPlusLinear.add),
              label: Text(
                'Add Product',
                style: GoogleFonts.interTight(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductManagementCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _ProductManagementCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');
    final imageUrl = product.images?.isNotEmpty == true
        ? product.images!.first
        : product.image;

    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-image-${product.id}-0',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.interTight(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        IconsaxPlusLinear.location,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.location ?? 'Location not set',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.interTight(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₦${formatter.format(product.price)}',
                    style: GoogleFonts.interTight(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Iconsax.edit, size: 16),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Iconsax.trash, size: 16),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(IconsaxPlusLinear.arrow_right_3),
          ],
        ),
      ),
    );
  }
}
