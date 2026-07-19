import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';

class Invoice {
  final String id;
  final List<Product> products;
  final DateTime createdAt;
  final double totalAmount;
  final String sourceCollection;

  Invoice({
    required this.id,
    required this.products,
    required this.createdAt,
    required this.totalAmount,
    this.sourceCollection = 'inventory',
  });

  /// Returns a display-friendly title based on the source collection.
  String get displayTitle =>
      sourceCollection == 'inventory' ? 'Inventory' : 'Stocks Availability';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'products': products.map((p) => p.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'totalAmount': totalAmount,
      'sourceCollection': sourceCollection,
    };
  }
}
