import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

class InventoryController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();
  final products = <Product>[].obs;
  final allProducts =
      <Product>[]; // Store all products for client-side filtering
  final isLoading = false.obs;

  final tableKey = GlobalKey<PaginatedDataTableState>();

  final total = 0.0.obs;
  final productNameController = TextEditingController();
  final productCountController = TextEditingController();
  final productIdController = TextEditingController();
  final productPriceController = TextEditingController();
  final quantityType = 'Nos'.obs; // Added quantityType observable
  final cardDiscountExcluded = false.obs;
  final formKey = GlobalKey<FormState>();

  final isSelectionMode = false.obs;
  final selectedProducts = <String>{}.obs;

  Timer? _debounce;
  final searchQuery = ''.obs;

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      searchQuery.value = query;
      _filterProducts();
    });
  }

  void _filterProducts() {
    if (searchQuery.value.isEmpty) {
      products.assignAll(allProducts);
    } else {
      final q = searchQuery.value.toLowerCase();
      products.assignAll(
        allProducts.where((p) => p.name.toLowerCase().contains(q)).toList(),
      );
    }
    // Overall total is fetched via fetchOverallTotal(), not recalculated locally
  }

  @override
  void onInit() {
    super.onInit();
    loadInventory();
  }

  Future<void> fetchOverallTotal() async {
    try {
      final allDocs = await _firestore.collection('inventory').get();
      double calculatedTotal = 0.0;
      for (var doc in allDocs.docs) {
        final data = doc.data();
        final qty = (data['count'] as num?)?.toInt() ?? 0;
        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
        calculatedTotal += qty * price;
      }
      total.value = calculatedTotal;
    } catch (e) {
      debugPrint('Error fetching overall total: $e');
    }
  }

  void toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
      selectedProducts.clear();
    }
  }

  void toggleProductSelection(String id) {
    if (selectedProducts.contains(id)) {
      selectedProducts.remove(id);
      if (selectedProducts.isEmpty) {
        isSelectionMode.value = false;
      }
    } else {
      selectedProducts.add(id);
    }
  }

  void deleteSelectedProducts() async {
    if (selectedProducts.isEmpty) return;

    try {
      isLoading.value = true;
      final productIds = selectedProducts.toList();

      // Batch limit is 500 operations, 2 per product = 250 products max per batch
      for (var i = 0; i < productIds.length; i += 250) {
        final batch = _firestore.batch();
        final chunk = productIds.sublist(i, min(i + 250, productIds.length));
        for (final id in chunk) {
          batch.delete(_firestore.collection('products').doc(id));
          batch.delete(_firestore.collection('inventory').doc(id));
        }
        await batch.commit();
      }

      allProducts.removeWhere((p) => selectedProducts.contains(p.id));
      _filterProducts();

      isSelectionMode.value = false;
      selectedProducts.clear();
      showToast('Selected products removed successfully', Colors.green);
    } catch (e) {
      showToast('Failed to remove selected products: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    productNameController.clear();
    productCountController.clear();
    productPriceController.clear();
    productIdController.clear();
    quantityType.value = 'Nos'; // Reset to default
    cardDiscountExcluded.value = false;
  }

  void generateUniqueBarcode() {
    String newBarcode;
    bool isUnique;
    do {
      // Generate a 6-digit number between 100000 and 999999
      newBarcode = (100000 + Random().nextInt(900000)).toString();
      isUnique = !products.any((p) => p.productId == newBarcode);
    } while (!isUnique);
    productIdController.text = newBarcode;
  }

  void showToast(String message, Color bgColor) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating, // Makes it act more like a toast
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? validateNos(String? value) {
    if (value == null || value.isEmpty) return 'Quantity is required';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Enter valid number';
    final numValue = int.tryParse(value);
    if (numValue == null || numValue <= 0) {
      return 'Quantity must be greater than 0';
    }
    return null;
  }

  String? validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) return 'Enter valid price';
    final numValue = double.tryParse(value);
    if (numValue == null || numValue < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }

  void addProduct() async {
    if (productNameController.text.isEmpty ||
        productCountController.text.isEmpty ||
        productIdController.text.isEmpty ||
        productPriceController.text.isEmpty) {
      showToast('Please fill all fields', Colors.red);
      return;
    }

    try {
      isLoading.value = true;

      // Additional safety check against Firebase to prevent concurrent duplicates
      String barcode = productIdController.text;
      bool isUniqueInDb = false;

      while (!isUniqueInDb) {
        final existingDoc = await _firestore
            .collection('products')
            .where('productId', isEqualTo: barcode)
            .get();

        if (existingDoc.docs.isEmpty) {
          isUniqueInDb = true;
        } else {
          // If it exists in Firebase, generate a new one and loop again
          do {
            barcode = (100000 + Random().nextInt(900000)).toString();
          } while (products.any((p) => p.productId == barcode));

          productIdController.text = barcode; // Update UI just in case
        }
      }

      final product = Product(
        id: _uuid.v4(),
        name: productNameController.text,
        productId: productIdController.text,
        count: int.parse(productCountController.text),
        price: double.parse(productPriceController.text),
        createdAt: DateTime.now().toString(),
        quantityType: quantityType.value,
        cardDiscountExcluded: cardDiscountExcluded.value,
      );

      // Add to both products and inventory collections
      await Future.wait([
        _firestore.collection('products').doc(product.id).set(product.toMap()),
        _firestore.collection('inventory').doc(product.id).set(product.toMap()),
      ]);

      allProducts.insert(0, product);
      _filterProducts();
      clearForm();

      showToast('Product added successfully', Colors.green);
    } catch (e) {
      showToast('Failed to add product: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void updateProduct(String id) async {
    if (productNameController.text.isEmpty ||
        productCountController.text.isEmpty ||
        productIdController.text.isEmpty ||
        productPriceController.text.isEmpty) {
      showToast('Please fill all fields', Colors.red);
      return;
    }

    try {
      isLoading.value = true;

      final existingProductIndex = products.indexWhere((p) => p.id == id);
      if (existingProductIndex == -1) return;
      final existingProduct = products[existingProductIndex];

      String newBarcode = productIdController.text;
      if (newBarcode != existingProduct.productId) {
        final existingDoc = await _firestore
            .collection('products')
            .where('productId', isEqualTo: newBarcode)
            .get();

        if (existingDoc.docs.isNotEmpty) {
          showToast('Barcode already exists for another product!', Colors.red);
          isLoading.value = false;
          return;
        }
      }

      final updatedProduct = Product(
        id: id,
        name: productNameController.text,
        productId: productIdController.text,
        count: int.parse(productCountController.text),
        price: double.parse(productPriceController.text),
        createdAt: existingProduct.createdAt,
        quantityType: quantityType.value,
        cardDiscountExcluded: cardDiscountExcluded.value,
      );

      await Future.wait([
        _firestore
            .collection('products')
            .doc(id)
            .update(updatedProduct.toMap()),
        _firestore
            .collection('inventory')
            .doc(id)
            .update(updatedProduct.toMap()),
      ]);

      final allIndex = allProducts.indexWhere((p) => p.id == id);
      if (allIndex != -1) {
        allProducts[allIndex] = updatedProduct;
      }
      _filterProducts();
      clearForm();

      showToast('Product updated successfully', Colors.green);
    } catch (e) {
      showToast('Failed to update product: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void removeProduct(String productId) async {
    try {
      isLoading.value = true;

      // Remove from both collections
      await Future.wait([
        _firestore.collection('products').doc(productId).delete(),
        _firestore.collection('inventory').doc(productId).delete(),
      ]);

      allProducts.removeWhere((product) => product.id == productId);
      _filterProducts();

      showToast('Product removed successfully', Colors.green);
    } catch (e) {
      showToast('Failed to remove product: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  DocumentSnapshot? lastDocument;
  final hasMore = true.obs;
  final isFetchingNextPage = false.obs;
  static const int pageSize = 20;

  void loadInventory({bool isLoadMore = false}) async {
    if (isLoadMore) {
      if (isFetchingNextPage.value || !hasMore.value) return;
      isFetchingNextPage.value = true;
    } else {
      if (isLoading.value) return;
      isLoading.value = true;
      lastDocument = null;
      hasMore.value = true;
      allProducts.clear();
      products.clear();
      fetchOverallTotal();
    }

    try {
      Query query = _firestore
          .collection('inventory')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        lastDocument = querySnapshot.docs.last;
      }

      if (querySnapshot.docs.length < pageSize) {
        hasMore.value = false;
      }

      final newProducts = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      for (var p in newProducts) {
        if (!allProducts.any((existing) => existing.id == p.id)) {
          allProducts.add(p);
        }
      }

      _filterProducts();
    } catch (e) {
      showToast('Failed to load products: $e', Colors.red);
    } finally {
      if (isLoadMore) {
        isFetchingNextPage.value = false;
      } else {
        isLoading.value = false;
      }
    }
  }
}
