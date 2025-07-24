import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/invoice_view/view/invoice_view.dart';
import 'package:fine_foods/invoice_generator/models/invoice_models.dart';
import 'package:fine_foods/invoice_generator/models/product_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class InvoiceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  final productNameController = TextEditingController();
  final productCountController = TextEditingController();
  final productPriceController = TextEditingController();

  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble totalAmount = 0.0.obs;
  Invoice? _cachedInvoice;
  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    productNameController.dispose();
    productCountController.dispose();
    productPriceController.dispose();
    super.onClose();
  }

  void addProduct() async {
    if (productNameController.text.isEmpty ||
        productCountController.text.isEmpty ||
        productPriceController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      final product = Product(
        id: _uuid.v4(),
        name: productNameController.text,
        count: int.parse(productCountController.text),
        price: double.parse(productPriceController.text),
        createdAt: DateTime.now().toString(),
      );

      // Add to Firebase
      await _firestore
          .collection('products')
          .doc(product.id)
          .set(product.toMap());

      // Add to local list
      products.add(product);
      calculateTotal();
      clearForm();

      Get.snackbar(
        'Success',
        'Product added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add product: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void removeProduct(String productId) async {
    try {
      isLoading.value = true;

      // Remove from Firebase
      await _firestore.collection('products').doc(productId).delete();

      // Remove from local list
      products.removeWhere((product) => product.id == productId);
      calculateTotal();

      Get.snackbar(
        'Success',
        'Product removed successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove product: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void loadProducts() async {
    try {
      isLoading.value = true;

      final querySnapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      products.clear();
      for (var doc in querySnapshot.docs) {
        final product = Product.fromMap(doc.data());
        products.add(product);
      }

      calculateTotal();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load products: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void generateInvoice() async {
    if (products.isEmpty) {
      Get.snackbar(
        'Error',
        'No products to generate invoice',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      final invoice = Invoice(
        id: _uuid.v4(),
        products: products.toList(),
        createdAt: DateTime.now(),
        totalAmount: totalAmount.value,
      );

      // Save invoice to Firebase
      await _firestore
          .collection('invoices')
          .doc(invoice.id)
          .set(invoice.toMap());

      Get.snackbar(
        'Success',
        'Invoice generated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to invoice view
      Get.to(() => InvoiceViewPage(invoice: invoice));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate invoice: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void calculateTotal() {
    totalAmount.value = products.fold(
      0.0,
      (sum, product) => sum + product.totalPrice,
    );
  }

  void handleInvoiceTap(BuildContext context) {
    if (products.isEmpty) {
      Get.snackbar(
        'Error',
        'No products to generate invoice',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _cachedInvoice ??= Invoice(
      id: _uuid.v4(),
      products: products.toList(),
      createdAt: DateTime.now(),
      totalAmount: totalAmount.value,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceViewPage(invoice: _cachedInvoice!),
      ),
    ).then((_) {
      _cachedInvoice = null; // Optional: reset after viewing
    });
  }

  void clearForm() {
    productNameController.clear();
    productCountController.clear();
    productPriceController.clear();
  }

  void clearAllProducts() async {
    try {
      isLoading.value = true;

      // Delete all products from Firebase
      final batch = _firestore.batch();
      for (var product in products) {
        batch.delete(_firestore.collection('products').doc(product.id));
      }
      await batch.commit();

      // Clear local list
      products.clear();
      calculateTotal();

      Get.snackbar(
        'Success',
        'All products cleared',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear products: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
