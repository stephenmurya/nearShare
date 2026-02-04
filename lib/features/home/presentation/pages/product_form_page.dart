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
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
  static const int _maxImages = 9;
  static const int _maxImageBytes = 10 * 1024 * 1024;

  final List<String> _categories = [
    'Construction',
    'Event',
    'Film',
    'Power',
    'Industrial',
  ];

  String _selectedCategory = 'Construction';
  String _selectedPeriod = 'Day';
  final List<String> _periods = ['Hour', 'Day', 'Week', 'Month'];
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
    if (images.isEmpty) return;
    await _addImagesWithChecks(images);
  }

  Future<void> _pickFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;
    await _addImagesWithChecks([image]);
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

  Future<void> _addImagesWithChecks(List<XFile> incoming) async {
    final totalExisting = _existingImageUrls.length + _newImages.length;
    final availableSlots = _maxImages - totalExisting;
    if (availableSlots <= 0) {
      _showToastWithMessenger(
        ScaffoldMessenger.of(context),
        'You can add up to $_maxImages images.',
      );
      return;
    }

    final selected = incoming.take(availableSlots).toList();
    final filtered = <XFile>[];
    for (final image in selected) {
      final size = await image.length();
      if (size > _maxImageBytes) {
        _showToastWithMessenger(
          ScaffoldMessenger.of(context),
          'Image too large (max 10MB).',
        );
        continue;
      }
      filtered.add(image);
    }

    if (filtered.isNotEmpty) {
      setState(() {
        _newImages.addAll(filtered);
      });
    }
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

    final shouldPopImmediately = widget.product == null;
    final messenger = ScaffoldMessenger.of(context);
    if (!shouldPopImmediately) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      if (shouldPopImmediately && mounted) {
        Navigator.pop(context, 'creating');
      }
      final uploadedUrls = <String>[];
      for (final image in _newImages) {
        final url = await _retry(
          () => _service
              .uploadProductImage(
                userId: user.uid,
                file: image,
              )
              .timeout(const Duration(seconds: 30)),
          onRetry: (attempt, error) {
            _showToastWithMessenger(
              messenger,
              'Retrying upload ($attempt/2)...',
            );
          },
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

      final priceValue = _parsePrice(_priceController.text.trim());

      final displayName =
          user.displayName?.trim().isNotEmpty == true ? user.displayName : null;
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
        postedByName: displayName ?? user.email ?? user.uid,
        userRating: widget.product?.userRating,
        userProfilePic: user.photoURL,
        createdAt: widget.product?.createdAt,
        isActive: widget.product?.isActive ?? true,
      );

      if (widget.product == null) {
        await _retry(
          () => _service.addProduct(product),
          onRetry: (attempt, error) {
            _showToastWithMessenger(
              messenger,
              'Retrying save ($attempt/2)...',
            );
          },
        );
      } else {
        await _retry(
          () => _service.updateProduct(widget.product!.id, product),
          onRetry: (attempt, error) {
            _showToastWithMessenger(
              messenger,
              'Retrying save ($attempt/2)...',
            );
          },
        );
      }

      if (!shouldPopImmediately && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Save product failed: $e');
      if (!shouldPopImmediately && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save product: $e',
              style: GoogleFonts.interTight(),
            ),
          ),
        );
      }
    } finally {
      if (!shouldPopImmediately && mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
              textCapitalization: TextCapitalization.sentences,
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
            _buildPriceRow(theme),
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
              textCapitalization: TextCapitalization.sentences,
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: (_existingImageUrls.length + _newImages.length) <
                  _maxImages
              ? _existingImageUrls.length + _newImages.length + 1
              : _existingImageUrls.length + _newImages.length,
          itemBuilder: (context, index) {
            final totalImages = _existingImageUrls.length + _newImages.length;
            final canAdd = totalImages < _maxImages;
            if (canAdd && index == totalImages) {
              return _buildAddImageTile(theme);
            }
            if (index < _existingImageUrls.length) {
              final url = _existingImageUrls[index];
              return _buildImageTile(
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
              );
            }
            final newIndex = index - _existingImageUrls.length;
            final file = _newImages[newIndex];
            return _buildImageTile(
              theme: theme,
              child: kIsWeb
                  ? Image.network(file.path, fit: BoxFit.cover)
                  : Image.file(
                      File(file.path),
                      fit: BoxFit.cover,
                    ),
              onRemove: () => _removeNewImage(file),
            );
          },
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
                IconsaxPlusLinear.trash,
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
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTextField(
              theme: theme,
              controller: spec.valueController,
              label: 'Value',
              textCapitalization: TextCapitalization.sentences,
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
    return _buildLabeledField(
      theme: theme,
      label: 'Category',
      child: _SelectionField(
        label: 'Category',
        value: _selectedCategory,
        onTap: () async {
          final selected = await _showSelectionSheet(
            theme: theme,
            title: 'Select Category',
            options: _categories,
            iconBuilder: (value) => IconsaxPlusLinear.tag,
            selectedValue: _selectedCategory,
          );
          if (selected != null) {
            setState(() {
              _selectedCategory = selected;
            });
          }
        },
      ),
    );
  }

  Widget _buildTextField({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return _buildLabeledField(
      theme: theme,
      label: label,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        textCapitalization: textCapitalization,
        style: GoogleFonts.interTight(color: theme.colorScheme.onSurface),
        decoration: _inputDecoration(theme, 'Enter $label'),
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, String label) {
    return InputDecoration(hintText: label);
  }

  Widget _buildPriceRow(ThemeData theme) {
    return _buildLabeledField(
      theme: theme,
      label: 'Price',
      child: Row(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: _selectionDecoration(theme),
            child: Row(
              children: [
                Text(
                  'NGN 🇳🇬',
                  style: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [_ThousandsSeparatorInputFormatter()],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Price is required';
                }
                final parsed = _parsePrice(value.trim());
                if (parsed <= 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
              style: GoogleFonts.interTight(
                color: theme.colorScheme.onSurface,
              ),
              decoration: _inputDecoration(theme, 'Enter Price'),
            ),
          ),
          const SizedBox(width: 12),
          _SelectionField(
            label: 'Period',
            value: _selectedPeriod,
            width: 120,
            onTap: () async {
              final selected = await _showSelectionSheet(
                theme: theme,
                title: 'Select Period',
                options: _periods,
                selectedValue: _selectedPeriod,
                iconBuilder: (value) {
                  switch (value) {
                    case 'Hour':
                      return IconsaxPlusLinear.clock;
                    case 'Week':
                      return IconsaxPlusLinear.calendar_2;
                    case 'Month':
                      return IconsaxPlusLinear.calendar;
                    default:
                      return IconsaxPlusLinear.calendar_1;
                  }
                },
              );
              if (selected != null) {
                setState(() {
                  _selectedPeriod = selected;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  BoxDecoration _selectionDecoration(ThemeData theme) {
    final fillColor =
        theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface;
    return BoxDecoration(
      color: fillColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withOpacity(0.6),
      ),
    );
  }

  Future<String?> _showSelectionSheet({
    required ThemeData theme,
    required String title,
    required List<String> options,
    required IconData Function(String value) iconBuilder,
    String? selectedValue,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: false,
      shape: theme.bottomSheetTheme.shape,
      backgroundColor: theme.bottomSheetTheme.backgroundColor,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: GoogleFonts.interTight(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map((value) {
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context, value),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                iconBuilder(value),
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  value,
                                  style: GoogleFonts.interTight(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Radio<String>(
                                value: value,
                                groupValue: selectedValue,
                                onChanged: (_) =>
                                    Navigator.pop(context, value),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  double _parsePrice(String raw) {
    final cleaned = raw.replaceAll(',', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  Future<T> _retry<T>(
    Future<T> Function() task, {
    int maxRetries = 2,
    void Function(int attempt, Object error)? onRetry,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await task();
      } catch (e) {
        if (attempt >= maxRetries) rethrow;
        attempt += 1;
        onRetry?.call(attempt, e);
      }
    }
  }

  void _showToastWithMessenger(
    ScaffoldMessengerState messenger,
    String message,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.interTight(),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildLabeledField({
    required ThemeData theme,
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SelectionField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final double? width;

  const _SelectionField({
    required this.label,
    required this.value,
    required this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor ??
                theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.6),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                IconsaxPlusLinear.arrow_down,
                color: theme.colorScheme.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final value = int.parse(raw);
    final formatted = NumberFormat.decimalPattern().format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
