import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final int count;
  final double price;
  final String createdAt;

  Product({
    required this.id,
    required this.name,
    required this.count,
    required this.price,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'count': count,
      'price': price,
      'createdAt': createdAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      count: map['count'],
      price: map['price'].toDouble(),
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      count: data['count'] ?? 0,
      price: data['price'] ?? 0,
      createdAt: data['createdAt']?.toString() ?? '',
    );
  }

  double get totalPrice => count * price;
}
