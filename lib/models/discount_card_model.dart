import 'package:cloud_firestore/cloud_firestore.dart';

class DiscountCard {
  final String id;
  final String tier; // "platinum", "gold", "silver"
  final double discountPercent;
  final bool active;
  final String createdAt;

  DiscountCard({
    required this.id,
    required this.tier,
    required this.discountPercent,
    required this.active,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tier': tier,
      'discountPercent': discountPercent,
      'active': active,
      'createdAt': createdAt,
    };
  }

  factory DiscountCard.fromMap(Map<String, dynamic> map) {
    return DiscountCard(
      id: map['id'] ?? '',
      tier: map['tier'] ?? 'silver',
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
      active: map['active'] ?? false,
      createdAt: map['createdAt'] ?? '',
    );
  }

  factory DiscountCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DiscountCard(
      id: doc.id,
      tier: data['tier'] ?? 'silver',
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0.0,
      active: data['active'] ?? false,
      createdAt: data['createdAt'] ?? '',
    );
  }

  DiscountCard copyWith({
    String? id,
    String? tier,
    double? discountPercent,
    bool? active,
    String? createdAt,
  }) {
    return DiscountCard(
      id: id ?? this.id,
      tier: tier ?? this.tier,
      discountPercent: discountPercent ?? this.discountPercent,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
