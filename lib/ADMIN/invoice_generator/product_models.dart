import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String productId;
  final int count;
  final double price;
  final String createdAt;
  final String quantityType; // Added quantityType field

  Product({
    required this.id,
    required this.name,
    required this.productId,
    required this.count,
    required this.price,
    required this.createdAt,
    required this.quantityType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'productId': productId,
      'count': count,
      'price': price,
      'createdAt': createdAt,
      'quantityType': quantityType,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      productId: map['productId'] ?? '',
      count: map['count'],
      price: map['price'].toDouble(),
      createdAt: map['createdAt']?.toString() ?? '',
      quantityType: map['quantityType'] ?? 'Nos',
    );
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      productId: data['productId'] ?? '',
      count: data['count'] ?? 0,
      price: data['price'] ?? 0,
      createdAt: data['createdAt']?.toString() ?? '',
      quantityType: data['quantityType'] ?? 'Nos',
    );
  }

  double get totalPrice => count * price;
}
