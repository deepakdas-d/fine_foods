import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/invoice_generator/product_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class InventoryController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();
  final products = <Product>[].obs;
  final isLoading = false.obs;
  final total = 0.0.obs;
  final productNameController = TextEditingController();
  final productCountController = TextEditingController();
  final productIdController = TextEditingController();
  final productPriceController = TextEditingController();
  final quantityType = 'Nos'.obs; // Added quantityType observable
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadInventory();
  }

  void calculateTotal() {
    total.value = products.fold(0, (sumValue, product) => sumValue + product.totalPrice);
  }

  void clearForm() {
    productNameController.clear();
    productCountController.clear();
    productPriceController.clear();
    productIdController.clear();
    quantityType.value = 'Nos'; // Reset to default
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
      );

      // Add to both products and inventory collections
      await Future.wait([
        _firestore.collection('products').doc(product.id).set(product.toMap()),
        _firestore.collection('inventory').doc(product.id).set(product.toMap()),
      ]);

      products.add(product);
      calculateTotal();
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

      final updatedProduct = Product(
        id: id,
        name: productNameController.text,
        productId: productIdController.text,
        count: int.parse(productCountController.text),
        price: double.parse(productPriceController.text),
        createdAt: existingProduct.createdAt,
        quantityType: quantityType.value,
      );

      await Future.wait([
        _firestore.collection('products').doc(id).update(updatedProduct.toMap()),
        _firestore.collection('inventory').doc(id).update(updatedProduct.toMap()),
      ]);

      products[existingProductIndex] = updatedProduct;
      calculateTotal();
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

      products.removeWhere((product) => product.id == productId);
      calculateTotal();

      showToast('Product removed successfully', Colors.green);
    } catch (e) {
      showToast('Failed to remove product: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void loadInventory() async {
    try {
      isLoading.value = true;

      final querySnapshot = await _firestore
          .collection('inventory')
          .orderBy('createdAt', descending: true)
          .get();

      products.clear();
      for (var doc in querySnapshot.docs) {
        final product = Product.fromMap(doc.data());
        products.add(product);
      }

      calculateTotal();
    } catch (e) {
      showToast('Failed to load products: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }
}
