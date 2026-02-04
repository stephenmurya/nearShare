import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:near_share/features/home/presentation/providers/favorites_provider.dart';
import 'package:near_share/features/home/presentation/pages/lister_profile_page.dart';
import 'package:near_share/features/home/models/product.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(widget.product.id);

    final images =
        (widget.product.images != null && widget.product.images!.isNotEmpty)
        ? widget.product.images!
        : [widget.product.image];

    final listerName =
        widget.product.postedByName ?? widget.product.postedBy;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Hero Image Carousel & App Bar Overlay
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            leadingWidth: 56, // Adjusted to strictly control icon position
            leading: Container(
              margin: const EdgeInsets.only(left: 16), // Force 16px from edge
              child: CircleAvatar(
                backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(IconsaxPlusLinear.arrow_left_1, size: 18),
                    color: theme.colorScheme.onSurface,
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero, // Remove default padding
                  ),
                ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  backgroundColor: theme.scaffoldBackgroundColor.withOpacity(
                    0.5,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Iconsax.export_1,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      Share.share(
                        'Check out this ${widget.product.name} for rent on Near Share! Only ₦${formatter.format(widget.product.price)}/day.',
                      );
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  right: 16,
                ), // Force 16px from edge
                child: CircleAvatar(
                  backgroundColor: theme.scaffoldBackgroundColor.withOpacity(
                    0.5,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Iconsax.heart5 : Iconsax.heart,
                      size: 20,
                      color: isFavorite
                          ? Colors.red
                          : theme.colorScheme.onSurface,
                    ),
                    onPressed: () =>
                        favoritesProvider.toggleFavorite(widget.product.id),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Blurred Background
                  if (images.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: images[_currentImageIndex],
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) =>
                          Container(color: Colors.grey[200]),
                    ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.black.withOpacity(0.2), // Dim countrol
                    ),
                  ),

                  // Carousel
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductImageViewerPage(
                            images: images,
                            initialIndex: _currentImageIndex,
                            heroTag: 'product-image-${widget.product.id}-0',
                          ),
                        ),
                      );
                    },
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final imageWidget = CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.contain, // Ensure full image fits
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(IconsaxPlusLinear.warning_2),
                        );
                        if (index == 0) {
                          return Hero(
                            tag: 'product-image-${widget.product.id}-0',
                            child: imageWidget,
                          );
                        }
                        return imageWidget;
                      },
                    ),
                  ),

                  // Counter Chip
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Updated Header: Row(Category, Location) -> Title
                  Row(
                    children: [
                      // Category Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.product.category,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Location Chip
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.05,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconsaxPlusLinear.location,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.product.location ?? 'Abuja, Nigeria',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Product Title
                  Text(
                    widget.product.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Lister Card
                  if (listerName != null) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListerProfilePage(
                              listerName: listerName,
                              profilePic: widget.product.userProfilePic,
                              rating: widget.product.userRating,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage:
                                  widget.product.userProfilePic != null
                                  ? NetworkImage(widget.product.userProfilePic!)
                                  : null,
                              child: widget.product.userProfilePic == null
                                  ? const Icon(Iconsax.user, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listerName,
                                    style: GoogleFonts.interTight(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Lister',
                                    style: GoogleFonts.interTight(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.product.userRating != null) ...[
                              const Icon(
                                Iconsax.star1,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.product.userRating} (12)',
                                style: GoogleFonts.interTight(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            Icon(
                              IconsaxPlusLinear.arrow_right_3,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Specs Grid
                  if (widget.product.specs != null) ...[
                    Text(
                      'Specifications',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ), // Matched spacing with Description (8px)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: widget.product.specs!.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(
                              0.3,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                entry.key,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                entry.value,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 100), // Spacing for fab/bottom bar
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '₦${formatter.format(widget.product.price)}',
                      style: GoogleFonts.interTight(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Rent Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductImageViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTag;

  const ProductImageViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.heroTag,
  });

  @override
  State<ProductImageViewerPage> createState() => _ProductImageViewerPageState();
}

class _ProductImageViewerPageState extends State<ProductImageViewerPage> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            IconsaxPlusLinear.close_circle,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gallery',
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageWidget = CachedNetworkImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(IconsaxPlusLinear.warning_2),
                );
                return InteractiveViewer(
                  child: index == widget.initialIndex
                      ? Hero(tag: widget.heroTag, child: imageWidget)
                      : imageWidget,
                );
              },
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: widget.images[index],
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
