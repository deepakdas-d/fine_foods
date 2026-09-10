class QueuedBill {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? cardTierUsed;
  final double cardDiscountPercent;
  final String customerDiscount;
  final String selectedPaymentType;
  final String paymentMethod;
  final String cashReceived;
  final String onlineReceived;
  final DateTime heldAt;
  final String? note;
  final double totalAmount;
  final int itemCount;
  final Map<String, int> selectedProducts;
  final Map<String, double> customPrices;
  final List<Map<String, dynamic>> productSnapshots;
  final List<String> itemSummaries;

  QueuedBill({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.cardTierUsed,
    required this.cardDiscountPercent,
    required this.customerDiscount,
    required this.selectedPaymentType,
    required this.paymentMethod,
    required this.cashReceived,
    required this.onlineReceived,
    required this.heldAt,
    this.note,
    required this.totalAmount,
    required this.itemCount,
    required this.selectedProducts,
    required this.customPrices,
    required this.productSnapshots,
    required this.itemSummaries,
  });

  List<Map<String, dynamic>> get quickProducts => productSnapshots;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'cardTierUsed': cardTierUsed,
      'cardDiscountPercent': cardDiscountPercent,
      'customerDiscount': customerDiscount,
      'selectedPaymentType': selectedPaymentType,
      'paymentMethod': paymentMethod,
      'cashReceived': cashReceived,
      'onlineReceived': onlineReceived,
      'heldAt': heldAt.toIso8601String(),
      'note': note,
      'totalAmount': totalAmount,
      'itemCount': itemCount,
      'selectedProducts': selectedProducts,
      'customPrices': customPrices,
      'productSnapshots': productSnapshots,
      'itemSummaries': itemSummaries,
    };
  }

  factory QueuedBill.fromJson(Map<String, dynamic> json) {
    return QueuedBill(
      id: json['id'] as String,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      cardTierUsed: json['cardTierUsed'] as String?,
      cardDiscountPercent: (json['cardDiscountPercent'] as num?)?.toDouble() ?? 0.0,
      customerDiscount: json['customerDiscount'] as String? ?? '',
      selectedPaymentType: json['selectedPaymentType'] as String? ?? 'Full',
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
      cashReceived: json['cashReceived'] as String? ?? '',
      onlineReceived: json['onlineReceived'] as String? ?? '',
      heldAt: DateTime.tryParse(json['heldAt'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      selectedProducts: (json['selectedProducts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      customPrices: (json['customPrices'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          {},
      productSnapshots: (json['productSnapshots'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          (json['quickProducts'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      itemSummaries: (json['itemSummaries'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
