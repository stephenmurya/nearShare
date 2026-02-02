class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String image;
  final String description;
  final String? location;
  final Map<String, String>? specs;
  final List<String>? images;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    required this.description,
    this.location,
    this.specs,
    this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] != null) {
      parsedImages = List<String>.from(json['images']);
    } else if (json['image'] != null) {
      parsedImages = [json['image']];
    }

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      location: json['location'],
      specs: json['specs'] != null
          ? Map<String, String>.from(json['specs'])
          : null,
      images: parsedImages,
    );
  }
}
