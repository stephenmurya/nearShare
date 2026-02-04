import 'dart:ui';

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
import 'package:shimmer/shimmer.dart';
import 'package:near_share/features/home/presentation/widgets/product_card.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  final ProductFirestoreService _service = ProductFirestoreService();
  Stream<List<Product>>? _productsStream;
  String? _streamUserId;
  bool _isCreating = false;
  int _lastCount = 0;
  DateTime? _pendingSince;

  void _setCreating() {
    setState(() {
      _isCreating = true;
      _pendingSince = DateTime.now();
    });
  }

  void _clearCreating() {
    if (!_isCreating) return;
    setState(() {
      _isCreating = false;
      _pendingSince = null;
    });
  }

  Future<void> _refresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;
    setState(() {
      _productsStream = _service.streamUserProducts(user.uid);
      _streamUserId = user.uid;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    if (user != null && user.uid != _streamUserId) {
      _productsStream = _service.streamUserProducts(user.uid);
      _streamUserId = user.uid;
    }
  }

  Future<bool?> _showDeleteSheet(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: theme.bottomSheetTheme.backgroundColor ??
                  theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Delete Product',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.interTight(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.interTight(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductCard(
                    product: product,
                    showStatus: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Delete',
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
      stream: _productsStream ?? _service.streamUserProducts(user.uid),
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
        if (_isCreating) {
          if (products.length > _lastCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _clearCreating();
            });
          } else if (_pendingSince != null &&
              DateTime.now().difference(_pendingSince!) >
                  const Duration(seconds: 20)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _clearCreating();
            });
          }
        }
        _lastCount = products.length;
        final isEmpty = products.isEmpty;

        final showShimmerOnly = isEmpty && _isCreating;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: showShimmerOnly
              ? RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                    children: [
                      _ShimmerPlaceholder(),
                    ],
                  ),
                )
              : isEmpty
              ? _EmptyState(
                  onAdd: () async {
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
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProductFormPage(),
                      ),
                    );
                    if (result == 'creating') {
                      _setCreating();
                    }
                  },
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                    itemCount:
                        products.length + (_isCreating ? 1 : 0),
                    separatorBuilder: (context, _) => Column(
                      children: [
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    itemBuilder: (context, index) {
                      if (_isCreating && index == 0) {
                        return _ShimmerPlaceholder();
                      }
                      final product =
                          products[_isCreating ? index - 1 : index];
                      return _ProductManagementCard(
                        product: product,
                        onEdit: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductFormPage(product: product),
                            ),
                          );
                        },
                        onDelete: () async {
                          final confirm =
                              await _showDeleteSheet(context, product);
                          if (confirm == true) {
                            await _service.deleteProduct(product.id);
                          }
                        },
                        onToggleStatus: () async {
                          await _service.updateProductStatus(
                            product.id,
                            !product.isActive,
                          );
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
                ),
          floatingActionButton: isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: FloatingActionButton.extended(
                    onPressed: () async {
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
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductFormPage(),
                        ),
                      );
                      if (result == 'creating') {
                        _setCreating();
                      }
                    },
                    icon: const Icon(IconsaxPlusLinear.add),
                    label: Text(
                      'Add Product',
                      style: GoogleFonts.interTight(),
                    ),
                    backgroundColor: AppTheme.primaryBlue,
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
  final VoidCallback onToggleStatus;
  final VoidCallback onView;

  const _ProductManagementCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
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
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'product-image-${product.id}-0',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.interTight(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusDot(isActive: product.isActive),
                          const SizedBox(width: 6),
                          Text(
                            product.isActive ? 'Active' : 'Disabled',
                            style: GoogleFonts.interTight(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            IconsaxPlusLinear.arrow_right_3,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _InfoChip(
                            icon: IconsaxPlusLinear.tag,
                            label: product.category,
                          ),
                          _InfoChip(
                            icon: IconsaxPlusLinear.location,
                            label: product.location ?? 'Location',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₦${formatter.format(product.price)}',
                        style: GoogleFonts.interTight(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _PillButton(
                  label: 'Edit',
                  icon: IconsaxPlusLinear.edit,
                  onPressed: onEdit,
                ),
                const SizedBox(width: 8),
                _PillButton(
                  label: 'Delete',
                  icon: IconsaxPlusLinear.trash,
                  onPressed: onDelete,
                  isDestructive: true,
                ),
                const Spacer(),
                _TogglePill(
                  isActive: product.isActive,
                  onToggle: onToggleStatus,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.interTight(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.interTight(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;

  const _TogglePill({required this.isActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isActive ? 'Disable' : 'Enable',
          style: GoogleFonts.interTight(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: isActive,
          onChanged: (_) => onToggle(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeColor: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool isActive;

  const _StatusDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive ? Colors.green : Colors.grey;
    final text = isActive ? 'Active' : 'Disabled';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.interTight(
              fontSize: 11,
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
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
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: theme.colorScheme.surfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 140,
                    color: theme.colorScheme.surfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 12,
                    width: 80,
                    color: theme.colorScheme.surfaceVariant,
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
