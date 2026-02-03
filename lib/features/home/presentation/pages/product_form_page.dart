import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:near_share/features/auth/presentation/providers/auth_provider.dart';
import 'package:near_share/features/auth/presentation/widgets/auth_guard_sheet.dart';
import 'package:near_share/features/home/models/product.dart';
import 'package:near_share/features/home/services/product_firestore_service.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _SpecPair {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _SpecPair({String? key, String? value})
      : keyController = TextEditingController(text: key ?? ''),
        valueController = TextEditingController(text: value ?? '');

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _service = ProductFirestoreService();

  final List<String> _categories = [
    'Construction',
    'Event',
    'Film',
    'Power',
    'Industrial',
  ];

  String _selectedCategory = 'Construction';
  final List<String> _existingImageUrls = [];
  final List<XFile> _newImages = [];
  final List<_SpecPair> _specs = [];
  bool _isSaving = false;

  bool get _hasImages => _existingImageUrls.isNotEmpty || _newImages.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null || user.isAnonymous) {
        showAuthGuardSheet(
          context,
          title: 'Sign in to start listing',
          message:
              'Sign in to start listing your gear and manage your rentals.',
        );
        Navigator.of(context).pop();
        return;
      }
    });
    if (widget.product != null) {
      final product = widget.product!;
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(2);
      _descriptionController.text = product.description;
      _locationController.text = product.location ?? '';
      _selectedCategory =
          product.category.isNotEmpty ? product.category : _selectedCategory;
      if (product.images != null) {
        _existingImageUrls.addAll(product.images!);
      } else if (product.image.isNotEmpty) {
        _existingImageUrls.add(product.image);
      }
      if (product.specs != null) {
        product.specs!.forEach((key, value) {
          _specs.add(_SpecPair(key: key, value: value?.toString()));
        });
      }
    }

    if (_specs.isEmpty) {
      _specs.add(_SpecPair());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    for (final spec in _specs) {
      spec.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _newImages.add(image);
      });
    }
  }

  void _removeExistingImage(String url) {
    setState(() {
      _existingImageUrls.remove(url);
    });
  }

  void _removeNewImage(XFile file) {
    setState(() {
      _newImages.remove(file);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_hasImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add at least one image before saving.',
            style: GoogleFonts.interTight(),
          ),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null || user.isAnonymous) {
      await showAuthGuardSheet(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final uploadedUrls = <String>[];
    for (final image in _newImages) {
      final url = await _service.uploadProductImage(
        userId: user.uid,
        file: image,
      );
      uploadedUrls.add(url);
    }

    final allImages = [..._existingImageUrls, ...uploadedUrls];
    final specs = <String, dynamic>{};
    for (final spec in _specs) {
      final key = spec.keyController.text.trim();
      final value = spec.valueController.text.trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        specs[key] = value;
      }
    }

    final priceValue =
        double.tryParse(_priceController.text.trim()) ?? 0.0;

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      price: priceValue,
      image: allImages.first,
      images: allImages,
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      specs: specs.isEmpty ? null : specs,
      postedBy: user.uid,
      userRating: widget.product?.userRating,
      userProfilePic: user.photoURL,
      createdAt: widget.product?.createdAt,
    );

    if (widget.product == null) {
      await _service.addProduct(product);
    } else {
      await _service.updateProduct(widget.product!.id, product);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product' : 'Add Product',
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            IconsaxPlusLinear.arrow_left_1,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildImageSection(theme),
            const SizedBox(height: 24),
            _buildTextField(
              theme: theme,
              controller: _nameController,
              label: 'Title',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildCategory(theme),
            const SizedBox(height: 16),
            _buildTextField(
              theme: theme,
              controller: _priceController,
              label: 'Price',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Price is required';
                }
                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              theme: theme,
              controller: _locationController,
              label: 'Location',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              theme: theme,
              controller: _descriptionController,
              label: 'Description',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Specifications',
              style: GoogleFonts.interTight(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._specs.map((spec) => _buildSpecRow(theme, spec)).toList(),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _specs.add(_SpecPair());
                });
              },
              icon: const Icon(IconsaxPlusLinear.add, size: 18),
              label: Text(
                'Add Spec',
                style: GoogleFonts.interTight(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProduct,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Save Changes' : 'Create Product',
                      style: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    final heroImage = _existingImageUrls.isNotEmpty
        ? _existingImageUrls.first
        : _newImages.isNotEmpty
            ? _newImages.first
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._existingImageUrls.map(
              (url) => _buildImageTile(
                theme: theme,
                child: heroImage == url && widget.product != null
                    ? Hero(
                        tag: 'product-image-${widget.product!.id}-0',
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                      ),
                onRemove: () => _removeExistingImage(url),
              ),
            ),
            ..._newImages.map(
              (file) => _buildImageTile(
                theme: theme,
                child: kIsWeb
                    ? Image.network(file.path, fit: BoxFit.cover)
                    : Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                      ),
                onRemove: () => _removeNewImage(file),
              ),
            ),
            _buildAddImageTile(theme),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(IconsaxPlusLinear.gallery),
                label: Text(
                  'Gallery',
                  style: GoogleFonts.interTight(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromCamera,
                icon: const Icon(IconsaxPlusLinear.camera),
                label: Text(
                  'Camera',
                  style: GoogleFonts.interTight(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddImageTile(ThemeData theme) {
    return InkWell(
      onTap: _pickFromGallery,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        child: const Icon(IconsaxPlusLinear.add),
      ),
    );
  }

  Widget _buildImageTile({
    required ThemeData theme,
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 84,
            height: 84,
            child: child,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                IconsaxPlusLinear.close_circle,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(ThemeData theme, _SpecPair spec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              theme: theme,
              controller: spec.keyController,
              label: 'Key',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTextField(
              theme: theme,
              controller: spec.valueController,
              label: 'Value',
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() {
                _specs.remove(spec);
                spec.dispose();
              });
            },
            icon: const Icon(IconsaxPlusLinear.trash),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: _inputDecoration(theme, 'Category'),
      items: _categories
          .map(
            (category) => DropdownMenuItem(
              value: category,
              child: Text(
                category,
                style: GoogleFonts.interTight(),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.interTight(
        color: theme.colorScheme.onSurface,
      ),
      decoration: _inputDecoration(theme, label),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.interTight(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
