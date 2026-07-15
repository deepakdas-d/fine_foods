import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String productId;
  final int count;
  final double price;
  final String createdAt;
  final String quantityType;
  final bool cardDiscountExcluded;

  Product({
    required this.id,
    required this.name,
    required this.productId,
    required this.count,
    required this.price,
    required this.createdAt,
    required this.quantityType,
    this.cardDiscountExcluded = false,
  });

  // ------------------ Firestore → Map ------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'productId': productId,
      'count': count,
      'price': price,
      'createdAt': createdAt,
      'quantityType': quantityType,
      'cardDiscountExcluded': cardDiscountExcluded,
    };
  }

  // ------------------ Map → Product ------------------
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      productId: map['productId'] ?? '',
      count: (map['count'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
      createdAt: map['createdAt']?.toString() ?? '',
      quantityType: map['quantityType'] ?? 'Nos',
      cardDiscountExcluded: map['cardDiscountExcluded'] ?? false,
    );
  }

  // ------------------ Firestore → Product ------------------
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      productId: data['productId'] ?? '',
      count: (data['count'] as num?)?.toInt() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['createdAt']?.toString() ?? '',
      quantityType: data['quantityType'] ?? 'Nos',
      cardDiscountExcluded: data['cardDiscountExcluded'] ?? false,
    );
  }

  // ------------------ ✅ REQUIRED FIX ------------------
  Product copyWith({
    String? id,
    String? name,
    String? productId,
    int? count,
    double? price,
    String? createdAt,
    String? quantityType,
    bool? cardDiscountExcluded,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      productId: productId ?? this.productId,
      count: count ?? this.count,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      quantityType: quantityType ?? this.quantityType,
      cardDiscountExcluded: cardDiscountExcluded ?? this.cardDiscountExcluded,
    );
  }

  // ------------------ Helper ------------------
  double get totalPrice => count * price;
}
