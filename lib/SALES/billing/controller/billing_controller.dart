import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:fine_foods/home/printer_controller.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:fine_foods/services/invoice_sequence_service.dart';

class BillingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final customerName = TextEditingController();
  TextEditingController customerPhone = TextEditingController();
  var customerDiscount = ''.obs;
  final discountController = TextEditingController();
  /// Incrementing this forces the Autocomplete widget to rebuild with a fresh controller.
  final RxInt autocompleteKey = 0.obs;
  var cardDiscountPercent = 0.0.obs;
  var cardTierUsed = RxnString();
  final RxList<Map<String, dynamic>> foundCustomers = <Map<String, dynamic>>[].obs;

  final RxList<Product> products = <Product>[].obs;
  final RxList<Product> filteredProducts = <Product>[].obs;
  final RxMap<String, int> selectedProducts = <String, int>{}.obs;
  final RxMap<String, double> customPrices = <String, double>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final controller = Get.put(BillListController());
  RxString selectedPaymentType = 'Full'.obs;
  RxString paymentMethod = 'Cash'.obs;
  RxString cashReceived = ''.obs;
  RxString onlineReceived = ''.obs;

  DocumentSnapshot? lastDocument;
  final RxBool isFetchingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isSearching = false.obs;
  Timer? _debounce;
  final ScrollController scrollController = ScrollController();
  final RxList<Map<String, dynamic>> allCustomers = <Map<String, dynamic>>[].obs;

  /// All products fetched so far (used for client-side numeric search)
  final RxList<Product> _allProductsCache = <Product>[].obs;
  bool _allProductsFetched = false;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    isLoading.value = true;
    fetchProducts(refresh: true);
    fetchAllCustomers();
  }

  Future<void> fetchAllCustomers() async {
    try {
      final snap = await _firestore.collection('customers').get();
      allCustomers.assignAll(snap.docs.map((e) => e.data()).toList());
    } catch (e) {
      developer.log('Failed to fetch customers: $e');
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      // Only paginate when there is no active search query (browse mode)
      if (searchQuery.value.trim().isEmpty) {
        fetchProducts();
      }
    }
  }

  /// Fetches ALL products from Firestore into _allProductsCache (one-time).
  Future<void> _ensureAllProductsCached() async {
    if (_allProductsFetched) return;
    try {
      isSearching.value = true;
      final snapshot = await _firestore.collection('products').orderBy('name').get();
      _allProductsCache.assignAll(
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
      );
      // Also update the main products list
      for (var item in _allProductsCache) {
        if (!products.any((p) => p.id == item.id)) {
          products.add(item);
        }
      }
      _allProductsFetched = true;
    } catch (e) {
      developer.log('Failed to fetch all products for cache: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// Client-side search across name, price, and productId.
  Future<void> _searchClientSide(String query) async {
    try {
      if (!_allProductsFetched) {
        isSearching.value = true;
      }
      await _ensureAllProductsCached();

      final trimmed = query.trim();
      final lowerQuery = trimmed.toLowerCase();
      final numericValue = double.tryParse(trimmed);

      filteredProducts.assignAll(
        _allProductsCache.where((product) {
          // Match by name (case-insensitive substring / full match)
          if (product.name.toLowerCase().contains(lowerQuery)) return true;
          // Match by exact price
          if (numericValue != null && product.price == numericValue) return true;
          // Match by productId prefix
          if (product.productId.startsWith(trimmed)) return true;
          return false;
        }).toList(),
      );

      hasMore.value = false; // no pagination for client-side results
    } catch (e) {
      developer.log('Failed client-side search: $e');
    } finally {
      isSearching.value = false;
      isLoading.value = false;
      isFetchingMore.value = false;
    }
  }

  Future<void> fetchProducts({bool refresh = false}) async {
    // If there's an active search query, use client-side search for all fields
    if (searchQuery.value.trim().isNotEmpty) {
      if (refresh) filteredProducts.clear();
      await _searchClientSide(searchQuery.value);
      return;
    }

    // No search query → paginated Firestore browse
    if (refresh) {
      lastDocument = null;
      hasMore.value = true;
    }

    if (!hasMore.value || (isFetchingMore.value && !refresh)) return;

    if (!refresh) isFetchingMore.value = true;

    try {
      Query query = _firestore.collection('products').orderBy('name').limit(20);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (refresh) {
        filteredProducts.clear();
      }

      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
        final newItems = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        
        for (var item in newItems) {
          if (!products.any((p) => p.id == item.id)) {
            products.add(item);
          }
        }
        filteredProducts.addAll(newItems);
      }

      if (snapshot.docs.length < 20) {
        hasMore.value = false;
      }
    } catch (e) {
      developer.log('Failed to fetch products: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch products: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      isFetchingMore.value = false;
    }
  }

  void searchProducts(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isNotEmpty && !_allProductsFetched) {
      isSearching.value = true;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery.value = query;
      fetchProducts(refresh: true);
    });
  }

  int getSelectedQuantity(Product product) {
    return selectedProducts[product.id] ?? 0;
  }

  double getCustomPrice(Product product) {
    return customPrices[product.id] ?? product.price;
  }

  void setCustomPrice(Product product, double price) {
    if (price > 0) {
      customPrices[product.id] = price;
    } else {
      customPrices.remove(product.id);
    }
  }

  void increaseQuantity(Product product) {
    final currentQuantity = selectedProducts[product.id] ?? 0;
    if (product.count > currentQuantity) {
      selectedProducts[product.id] = currentQuantity + 1;
    } else {
      Get.snackbar(
        'Out of Stock',
        '${product.name} is out of stock',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void decreaseQuantity(Product product) {
    final currentQuantity = selectedProducts[product.id] ?? 0;
    if (currentQuantity > 0) {
      if (currentQuantity == 1) {
        selectedProducts.remove(product.id);
        customPrices.remove(product.id);
        _showFeedback('${product.name} removed from cart');
      } else {
        selectedProducts[product.id] = currentQuantity - 1;
      }
    }
  }

  void clearCart() {
    selectedProducts.clear();
    customPrices.clear();
    customerName.clear();
    customerDiscount.value = '';
    discountController.clear();
    cardDiscountPercent.value = 0.0;
    cardTierUsed.value = null;
    // Increment key to force Autocomplete widget to rebuild with a fresh controller
    autocompleteKey.value++;
  }

  /// Adds an ad-hoc quick item (not from inventory) to the cart.
  void addQuickItem({
    required String name,
    required double price,
    required int quantity,
    required String quantityType,
  }) {
    final id = 'quick_${DateTime.now().millisecondsSinceEpoch}';
    final quickProduct = Product(
      id: id,
      name: name,
      productId: '',
      count: 999, // unlimited stock for quick items
      price: price,
      createdAt: DateTime.now().toIso8601String(),
      quantityType: quantityType,
    );

    // Add product to the products list so it can be found during bill creation
    products.add(quickProduct);
    filteredProducts.add(quickProduct);

    // Add to cart with requested quantity
    selectedProducts[id] = quantity;
    customPrices[id] = price;

    _showFeedback('$name added to cart');
  }

  Future<void> searchCustomerByPhone(String phone) async {
    if (phone.trim().length != 10) {
      Get.snackbar('Error', 'Enter a valid 10-digit phone number');
      return;
    }
    
    try {
      isLoading.value = true;
      final querySnapshot = await _firestore
          .collection('customers')
          .where('phone', isEqualTo: phone.trim())
          .get();
          
      if (querySnapshot.docs.isEmpty) {
        Get.snackbar('Not Found', 'Customer not found. You can proceed without discount.');
        foundCustomers.clear();
        applySelectedCustomer(null);
      } else if (querySnapshot.docs.length == 1) {
        foundCustomers.clear();
        applySelectedCustomer(querySnapshot.docs.first.data());
      } else {
        foundCustomers.assignAll(querySnapshot.docs.map((d) => d.data()).toList());
        _showCustomerSelectionDialog();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to search customer: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _showCustomerSelectionDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2B3139),
        title: const Text('Select Customer', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: foundCustomers.length,
            itemBuilder: (context, index) {
              final c = foundCustomers[index];
              return ListTile(
                title: Text(c['name'] ?? '', style: const TextStyle(color: Colors.white)),
                subtitle: Text('Tier: ${c['cardTier']?.toString().toUpperCase() ?? 'None'}', style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  Get.back();
                  applySelectedCustomer(c);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> applySelectedCustomer(Map<String, dynamic>? data) async {
    if (data == null) {
      customerName.clear();
      cardDiscountPercent.value = 0.0;
      cardTierUsed.value = null;
      return;
    }
    
    customerName.text = data['name'] ?? '';
    cardTierUsed.value = data['cardTier'];
    
    if (data['cardId'] != null) {
      try {
        final cardDoc = await _firestore.collection('discount_cards').doc(data['cardId']).get();
        if (cardDoc.exists && cardDoc.data()?['active'] == true) {
          cardDiscountPercent.value = (cardDoc.data()?['discountPercent'] as num?)?.toDouble() ?? 0.0;
        } else {
          cardDiscountPercent.value = 0.0;
        }
      } catch (e) {
        cardDiscountPercent.value = 0.0;
      }
    } else {
      cardDiscountPercent.value = 0.0;
    }
    
    if (cardDiscountPercent.value > 0) {
      Get.snackbar('Discount Applied', '${cardTierUsed.value?.toUpperCase()} Card applied (${cardDiscountPercent.value}%)');
    }
  }

  Product? getProductById(String id) {
    for (var p in products) {
      if (p.id == id) return p;
    }
    for (var p in _allProductsCache) {
      if (p.id == id) return p;
    }
    return null;
  }

  double calculateTotal() {
    double total = 0;
    for (var entry in selectedProducts.entries) {
      final product = getProductById(entry.key);
      if (product != null) {
        final price = getCustomPrice(product);
        final qty = entry.value;
        final lineSubtotal = price * qty;
        
        double lineCardDiscount = 0.0;
        if (!product.cardDiscountExcluded && cardDiscountPercent.value > 0) {
          lineCardDiscount = lineSubtotal * (cardDiscountPercent.value / 100);
        }
        
        total += (lineSubtotal - lineCardDiscount);
      } else {
        final customPrice = customPrices[entry.key] ?? 0.0;
        total += customPrice * entry.value;
      }
    }
    final discount = customerDiscount.value.trim().isEmpty
        ? 0.0
        : double.tryParse(customerDiscount.value.trim()) ?? 0.0;
    return (total - discount).clamp(0, double.infinity);
  }

  Future<String> generateInvoiceNumber() async {
    return await InvoiceSequenceService.getNextInvoiceNumber();
  }

  Future<Map<String, dynamic>?> createBill() async {
    if (selectedProducts.isEmpty) {
      Get.snackbar('Error', 'Please select at least one product');
      return null;
    }

    // Phone validation (optional but if filled → 10 digits)
    if (customerPhone.text.trim().isNotEmpty &&
        !RegExp(r'^\d{10}$').hasMatch(customerPhone.text.trim())) {
      Get.snackbar('Error', 'Enter a valid 10-digit phone number');
      return null;
    }

    // Discount validation
    if (customerDiscount.value.trim().isNotEmpty) {
      final disc = double.tryParse(customerDiscount.value.trim());
      if (disc == null || disc <= 0) {
        Get.snackbar('Error', 'Enter a valid discount greater than 0');
        return null;
      }
      if (disc > calculateTotal()) {
        Get.snackbar('Error', 'Discount cannot exceed total amount');
        return null;
      }
    }

    isLoading.value = true;

    try {
      final billId = const Uuid().v4();
      developer.log('[createBill] Requesting next sequential invoice number...');
      print('[createBill] Requesting next sequential invoice number...');
      final invoiceNumber = await generateInvoiceNumber();
      developer.log('[createBill] Received invoice number: $invoiceNumber, billId: $billId');
      print('[createBill] Received invoice number: $invoiceNumber, billId: $billId');
      final batch = _firestore.batch();

      final totalAmount = calculateTotal();
      final discount = customerDiscount.value.trim().isEmpty
          ? 0.0
          : double.parse(customerDiscount.value.trim());

      if (totalAmount <= 0) {
        developer.log('[createBill] Validation failed: totalAmount is $totalAmount');
        print('[createBill] Validation failed: totalAmount is $totalAmount');
        Get.snackbar('Error', 'Total amount must be greater than 0');
        return null;
      }

      double cash = 0;
      double online = 0;

      // Determine payment amounts
      if (selectedPaymentType.value == 'Full') {
        if (paymentMethod.value == 'Cash') {
          cash = totalAmount;
        } else if (paymentMethod.value == 'Online') {
          online = totalAmount;
        }
      } else if (selectedPaymentType.value == 'Split') {
        cash = double.tryParse(cashReceived.value) ?? 0;
        online = double.tryParse(onlineReceived.value) ?? 0;

        if ((cash + online) != totalAmount) {
          Get.snackbar('Error', 'Cash + Online must equal total amount');
          return null;
        }
      }

      final billData = {
        'invoiceNumber': invoiceNumber,
        'customerName': customerName.text.isEmpty
            ? 'Walk-in Customer'
            : customerName.text.trim(),
        'customerPhone': customerPhone.text.trim(),
        'cardTierUsed': cardTierUsed.value,
        'cardDiscountPercent': cardDiscountPercent.value,

        // ✅ FIXED PRODUCTS LIST
        'products': selectedProducts.entries.map((entry) {
          final product = getProductById(entry.key);
          final name = product?.name ?? 'Item';
          final price = product != null
              ? getCustomPrice(product)
              : (customPrices[entry.key] ?? 0.0);
          final lineSubtotal = price * entry.value;
          final cardExcluded = product?.cardDiscountExcluded ?? false;

          double cardDiscountAmount = 0.0;
          if (!cardExcluded && cardDiscountPercent.value > 0) {
            cardDiscountAmount = lineSubtotal * (cardDiscountPercent.value / 100);
          }

          return {
            'productId': entry.key,
            'productName': name,
            'quantity': entry.value,
            'price': price,
            'total': lineSubtotal - cardDiscountAmount,
            'cardDiscountExcluded': cardExcluded,
            'cardDiscountAmount': cardDiscountAmount,
          };
        }).toList(),

        'subtotal': totalAmount + discount,
        'discount': discount,
        'total': totalAmount,

        'itemCount': selectedProducts.values.fold(0, (a, b) => a + b),

        'paymentType': selectedPaymentType.value,
        'paymentMethod': selectedPaymentType.value == 'Split'
            ? 'Both'
            : paymentMethod.value,
        'cashReceived': cash,
        'onlineReceived': online,
        'totalPaid': cash + online,
        'paymentStatus': 'paid',

        'source': 'inventory',
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'completed',
      };

      // Save bill
      batch.set(_firestore.collection('bills').doc(billId), billData);

      // Update stock (skip quick items — they don't exist in Firestore)
      for (var entry in selectedProducts.entries) {
        final product = getProductById(entry.key);
        if (product == null) continue;

        // Quick items are ad-hoc and have no Firestore document
        if (!entry.key.startsWith('quick_')) {
          batch.update(_firestore.collection('products').doc(product.id), {
            'count': FieldValue.increment(-entry.value),
          });
          batch.update(_firestore.collection('inventory').doc(product.id), {
            'count': FieldValue.increment(-entry.value),
          });
        }

        final index = products.indexOf(product);
        if (index != -1) {
          products[index] = product.copyWith(
            count: product.count - entry.value,
          );
        }
      }

      // --- Time-Bucket Aggregations for Sales Growth ---
      // Since this is the inventory billing controller, it naturally filters out quick bills.
      final now = DateTime.now();
      final dayKey = DateFormat('yyyy-MM-dd').format(now);
      final monthKey = DateFormat('yyyy-MM').format(now);
      final yearKey = DateFormat('yyyy').format(now);

      final Map<String, dynamic> salesIncrements = {};
      for (var entry in selectedProducts.entries) {
        final product = getProductById(entry.key);
        salesIncrements[entry.key] = {
          'qty': FieldValue.increment(entry.value),
          'name': product?.name ?? 'Item',
        };
      }

      batch.set(_firestore.collection('sales_stats').doc('daily_$dayKey'), salesIncrements, SetOptions(merge: true));
      batch.set(_firestore.collection('sales_stats').doc('monthly_$monthKey'), salesIncrements, SetOptions(merge: true));
      batch.set(_firestore.collection('sales_stats').doc('yearly_$yearKey'), salesIncrements, SetOptions(merge: true));
      batch.set(_firestore.collection('sales_stats').doc('all_time'), salesIncrements, SetOptions(merge: true));
      // -----------------------------------------------

      developer.log('[createBill] Committing Firestore batch write...');
      print('[createBill] Committing Firestore batch write...');
      await batch.commit();
      developer.log('[createBill] Batch write committed successfully!');
      print('[createBill] Batch write committed successfully!');

      Get.snackbar(
        'Success',
        'Invoice $invoiceNumber created successfully!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      );

      clearCart();
      fetchProducts(refresh: true);
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }

      return billData;
    } catch (e, stackTrace) {
      developer.log('[createBill] Failed to create bill: $e\n$stackTrace', error: e, stackTrace: stackTrace);
      print('[createBill] Failed to create bill: $e\n$stackTrace');
      Get.snackbar('Error', 'Failed to create invoice: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> printInvoice(Map<String, dynamic> billData) async {
    developer.log(
      '[BillingController] Starting printInvoice for invoice #${billData['invoiceNumber']}',
    );

    try {
      final PrinterController printerController = Get.find<PrinterController>();

      if (!printerController.isConnected.value) {
        throw Exception('Printer not connected');
      }

      final createdAt = DateTime.parse(billData['createdAt']);
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(createdAt);

      Uint8List printBytes;

      // ================= WINDOWS / WEB =================
      if (GetPlatform.isWindows || kIsWeb) {
        developer.log(
          '[BillingController] Using Generator (Windows/Web stable)',
        );

        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);

        List<int> bytes = [];
        bytes += generator.reset();

        // Styles
        const centerBold = PosStyles(
          align: PosAlign.center,
          bold: true,
          fontType: PosFontType.fontA,
        );
        const center = PosStyles(align: PosAlign.center);
        const normal = PosStyles();
        const bold = PosStyles(bold: true);

        // Header
        bytes += generator.text('FINE FOODS', styles: centerBold);
        bytes += generator.text('CRAFTS & GIFT', styles: centerBold);
        bytes += generator.text('Main Road Alathur', styles: center);
        bytes += generator.text('7907609118', styles: center);
        bytes += generator.feed(1);

        // Invoice Info
        bytes += generator.text(
          'Invoice #${billData['invoiceNumber']}',
          styles: normal,
        );
        bytes += generator.text('Date: $formattedDate', styles: normal);

        if ((billData['customerPhone'] ?? '').toString().trim().isNotEmpty) {
          bytes += generator.text(
            'Phone: ${billData['customerPhone']}',
            styles: normal,
          );
        }

        // Table Header
        bytes += generator.text('--------------------------------');
        bytes += generator.text('Item         Qty Price  Total', styles: bold);
        bytes += generator.text('--------------------------------');

        // Products
        for (var product in billData['products']) {
          String name = product['productName'].toString();
          if (name.length > 12) name = name.substring(0, 12);
          name = name.padRight(12);

          String qty = product['quantity'].toString().padLeft(3);
          String price = product['price'].toStringAsFixed(2).padLeft(7);
          String total = product['total'].toStringAsFixed(2).padLeft(7);

          bytes += generator.text('$name $qty $price $total', styles: normal);
        }

        bytes += generator.text('--------------------------------');

        // Totals
        final subtotal =
            billData['subtotal'] ??
            (billData['total'] + (billData['discount'] ?? 0));
        final discount = billData['discount'] ?? 0;
        final total = billData['total'];

        bytes += generator.text(
          'Subtotal: Rs${subtotal.toStringAsFixed(2).padLeft(8)}',
          styles: normal,
        );
        if (discount > 0) {
          bytes += generator.text(
            'Discount: Rs${discount.toStringAsFixed(2).padLeft(8)}',
            styles: normal,
          );
        }
        bytes += generator.text(
          'Total:    Rs${total.toStringAsFixed(2).padLeft(8)}',
          styles: bold,
        );

        // Payment Details
        final paymentType = billData['paymentType'] ?? 'Full';
        final paymentMethod = billData['paymentMethod'] ?? 'Cash';
        final cash = (billData['cashReceived'] ?? 0).toDouble();
        final online = (billData['onlineReceived'] ?? 0).toDouble();

        bytes += generator.feed(1);
        bytes += generator.text(
          'Payment: $paymentMethod (${paymentType == 'Split' ? 'Split' : 'Full'})',
          styles: normal,
        );
        if (cash > 0) {
          bytes += generator.text(
            'Cash Received: Rs${cash.toStringAsFixed(2)}',
            styles: normal,
          );
        }
        if (online > 0) {
          bytes += generator.text(
            'Online Received: Rs${online.toStringAsFixed(2)}',
            styles: normal,
          );
        }
        bytes += generator.text(
          'Total Paid: Rs${(cash + online).toStringAsFixed(2)}',
          styles: bold,
        );

        bytes += generator.feed(2);
        bytes += generator.cut();

        printBytes = Uint8List.fromList(bytes);
      }
      // ================= ANDROID =================
      else {
        developer.log('[BillingController] Using raw ESC/POS (Android)');

        final esc = EscCommand();
        await esc.cleanCommand();

        esc.text(content: '\x1B\x40');

        // Header
        esc.text(
          content:
              '\x1B\x61\x01\x1B\x45\x01FINE FOODS\nCRAFTS & GIFT\n\x1B\x45\x00',
        );
        esc.text(content: '\n');
        esc.text(
          content: '\x1B\x61\x01Main Road Alathur\n7907609118\n\x1B\x61\x00',
        );

        // Invoice Info
        String phoneLine =
            (billData['customerPhone'] ?? '').toString().trim().isNotEmpty
            ? 'Phone: ${billData['customerPhone']}\n'
            : '';

        esc.text(
          content:
              'Invoice #${billData['invoiceNumber']}\nDate: $formattedDate\n$phoneLine',
        );

        esc.text(content: '--------------------------------\n');
        esc.text(
          content: '\x1B\x45\x01Item         Qty Price  Total\n\x1B\x45\x00',
        );
        esc.text(content: '--------------------------------\n');

        // Products
        for (var product in billData['products']) {
          String name = product['productName'].toString();
          if (name.length > 12) name = name.substring(0, 12);
          name = name.padRight(12);

          String qty = product['quantity'].toString().padLeft(3);
          String price = product['price'].toStringAsFixed(2).padLeft(6);
          String total = product['total'].toStringAsFixed(2).padLeft(6);

          esc.text(content: '$name $qty $price $total\n');
        }

        esc.text(content: '--------------------------------\n');

        // Totals
        final subtotal =
            billData['subtotal'] ??
            (billData['total'] + (billData['discount'] ?? 0));
        final discount = billData['discount'] ?? 0;
        final total = billData['total'];

        esc.text(content: 'Subtotal: Rs${subtotal.toStringAsFixed(2)}\n');
        if (discount > 0) {
          esc.text(content: 'Discount: Rs${discount.toStringAsFixed(2)}\n');
        }
        esc.text(
          content:
              '\x1B\x45\x01Total: Rs${total.toStringAsFixed(2)}\n\x1B\x45\x00',
        );

        // Payment Details
        final paymentType = billData['paymentType'] ?? 'Full';
        final paymentMethod = billData['paymentMethod'] ?? 'Cash';
        final cash = (billData['cashReceived'] ?? 0).toDouble();
        final online = (billData['onlineReceived'] ?? 0).toDouble();

        esc.text(content: '\n');
        esc.text(
          content:
              'Payment: $paymentMethod (${paymentType == 'Split' ? 'Split' : 'Full'})\n',
        );
        if (cash > 0) {
          esc.text(content: 'Cash Received: Rs${cash.toStringAsFixed(2)}\n');
        }
        if (online > 0) {
          esc.text(
            content: 'Online Received: Rs${online.toStringAsFixed(2)}\n',
          );
        }
        esc.text(
          content: 'Total Paid: Rs${(cash + online).toStringAsFixed(2)}\n',
        );

        esc.text(content: '\n\n\n');

        final cmd = await esc.getCommand();
        if (cmd == null) throw Exception('Failed to generate ESC command');

        printBytes = Uint8List.fromList(cmd);
      }

      // ================= SEND TO PRINTER =================
      await printerController.print(printBytes);

      Get.snackbar(
        'Success',
        'Invoice printed successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      developer.log('[BillingController] Print failed: $e', level: 1000);

      Get.snackbar(
        'Error',
        'Failed to print invoice: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showFeedback(String message, {Color bgColor = Colors.black87}) {
    final overlay = Get.key.currentState?.overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 40,
        right: 20,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  void onClose() {
    customerName.dispose();
    discountController.dispose();
    scrollController.dispose();
    _debounce?.cancel();
    super.onClose();
  }
}
