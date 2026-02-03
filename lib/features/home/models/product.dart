import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final String image;
  final String description;
  final String? location;
  final Map<String, dynamic>? specs;
  final List<String>? images;
  final String? postedBy;
  final double? userRating;
  final String? userProfilePic;
  final Timestamp? createdAt;

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
    this.postedBy,
    this.userRating,
    this.userProfilePic,
    this.createdAt,
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
          ? Map<String, dynamic>.from(json['specs'])
          : null,
      images: parsedImages,
      postedBy: json['postedBy'],
      userRating: (json['userRating'] as num?)?.toDouble(),
      userProfilePic: json['userProfilePic'],
    );
  }

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final imagesRaw = data['images'];
    final images = imagesRaw is List
        ? imagesRaw.map((e) => e.toString()).toList()
        : <String>[];
    final primaryImage = (data['image'] ?? (images.isNotEmpty ? images.first : ''))
        .toString();
    final specsRaw = data['specs'];
    return Product(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      image: primaryImage,
      description: (data['description'] ?? '').toString(),
      location: data['location']?.toString(),
      specs: specsRaw is Map ? Map<String, dynamic>.from(specsRaw) : null,
      images: images.isNotEmpty ? images : [primaryImage],
      postedBy: data['postedBy']?.toString(),
      userRating: (data['userRating'] as num?)?.toDouble(),
      userProfilePic: data['userProfilePic']?.toString(),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'image': image,
      'description': description,
      'location': location,
      'specs': specs,
      'images': images,
      'postedBy': postedBy,
      'userRating': userRating,
      'userProfilePic': userProfilePic,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'image': image,
      'images': images,
      'description': description,
      'location': location,
      'specs': specs,
      'postedBy': postedBy,
      'userRating': userRating,
      'userProfilePic': userProfilePic,
    };
  }
}
