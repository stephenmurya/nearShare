import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:near_share/core/theme/app_theme.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:near_share/features/home/models/product.dart';
import 'package:near_share/features/home/presentation/providers/product_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class ProductEditPage extends StatefulWidget {
  final Product? product;
  const ProductEditPage({super.key, this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _descController;
  String? _selectedCategory;
  String _catQuery = '';

  static const List<String> _allCategories = [
    'Construction',
    'Event',
    'Film',
    'Power',
    'Industrial',
    'Audio',
    'Camera',
    'Lighting',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(text: p != null ? p.price.toString() : '');
    _imageController = TextEditingController(text: p?.image ?? _mockImageUrl());
    _descController = TextEditingController(text: p?.description ?? '');
    _selectedCategory = p?.category;
  }

  String _mockImageUrl() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'https://loremflickr.com/640/360/equipment?random=$ts';
  }

  bool get _isValid {
    return _titleController.text.trim().isNotEmpty &&
        _priceController.text.trim().isNotEmpty &&
        _imageController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        actions: [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product Image', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Center(
                child: Hero(
                  tag: 'product-img-${widget.product?.id ?? 'new'}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _imageController.text,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey[200],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(hintText: 'Image URL'),
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.trim().isEmpty ? 'Image required' : null,
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Title'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Price'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Price required' : null,
              ),

              const SizedBox(height: 16),
              Text('Category', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(hintText: 'Search categories'),
                onChanged: (v) => setState(() => _catQuery = v),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allCategories
                    .where((c) => c.toLowerCase().contains(_catQuery.toLowerCase()))
                    .map(
                      (c) => GestureDetector(
                        onTap: () => setState(() => _selectedCategory = c),
                        child: Chip(
                          label: Text(c),
                          backgroundColor: _selectedCategory == c ? Colors.grey[300] : Colors.grey[100],
                        ),
                      ),
                    )
                    .toList(),
              ),

              if (_selectedCategory != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  children: [
                    Chip(
                      label: Text(_selectedCategory!),
                      backgroundColor: Colors.grey[200],
                      deleteIcon: const Icon(IconsaxPlusLinear.close_circle),
                      onDeleted: () => setState(() => _selectedCategory = null),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Description (optional)'),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !_isValid
                      ? null
                      : () {
                          if (!_formKey.currentState!.validate()) return;
                          final id = widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                          final product = Product(
                            id: id,
                            name: _titleController.text.trim(),
                            category: _selectedCategory ?? 'General',
                            price: double.tryParse(_priceController.text.trim()) ?? 0.0,
                            image: _imageController.text.trim(),
                            description: _descController.text.trim(),
                          );
                          final uid = auth.user?.uid ?? 'guest';
                          if (widget.product == null) {
                            productProvider.addProduct(product, uid);
                          } else {
                            productProvider.updateProduct(id, product);
                          }
                          Navigator.pop(context);
                        },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
