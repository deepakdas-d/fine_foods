import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? cardId;
  final String? cardTier;
  final double? customDiscountPercent;
  final String createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.cardId,
    this.cardTier,
    this.customDiscountPercent,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'cardId': cardId,
      'cardTier': cardTier,
      'customDiscountPercent': customDiscountPercent,
      'createdAt': createdAt,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      cardId: map['cardId'],
      cardTier: map['cardTier'],
      customDiscountPercent: (map['customDiscountPercent'] as num?)?.toDouble(),
      createdAt: map['createdAt'] ?? '',
    );
  }

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Customer(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      cardId: data['cardId'],
      cardTier: data['cardTier'],
      customDiscountPercent: (data['customDiscountPercent'] as num?)?.toDouble(),
      createdAt: data['createdAt'] ?? '',
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? cardId,
    String? cardTier,
    double? customDiscountPercent,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      cardId: cardId ?? this.cardId,
      cardTier: cardTier ?? this.cardTier,
      customDiscountPercent: customDiscountPercent ?? this.customDiscountPercent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
