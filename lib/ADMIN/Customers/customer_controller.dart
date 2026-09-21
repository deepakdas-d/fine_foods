import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/models/customer_model.dart';
import 'package:fine_foods/models/discount_card_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class CustomerController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  
  final customers = <Customer>[].obs;
  final filteredCustomers = <Customer>[].obs;
  final activeCards = <DiscountCard>[].obs;
  final isLoading = false.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final customDiscountPercentController = TextEditingController();
  final selectedCardId = Rxn<String>();
  final searchQuery = ''.obs;
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
    loadActiveCards();
  }

  void clearForm() {
    nameController.clear();
    phoneController.clear();
    customDiscountPercentController.clear();
    selectedCardId.value = null;
  }

  String? validateCustomDiscount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final numValue = double.tryParse(value.trim());
    if (numValue == null || numValue < 0 || numValue > 100) {
      return 'Enter a valid percentage (0-100)';
    }
    return null;
  }

  void showToast(String message, Color bgColor) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void searchCustomers(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredCustomers.assignAll(customers);
    } else {
      final q = query.toLowerCase();
      filteredCustomers.assignAll(customers.where((c) =>
          c.name.toLowerCase().contains(q) || c.phone.contains(q)));
    }
  }

  Future<void> loadActiveCards() async {
    try {
      final snapshot = await _firestore
          .collection('discount_cards')
          .where('active', isEqualTo: true)
          .get();

      activeCards.clear();
      for (var doc in snapshot.docs) {
        activeCards.add(DiscountCard.fromMap(doc.data()));
      }
    } catch (e) {
      debugPrint('Failed to load cards: $e');
    }
  }

  Future<bool> _isDuplicate(String name, String phone, {String? excludeId}) async {
    final normalizedName = name.trim().toLowerCase();
    final normalizedPhone = phone.trim();

    final querySnapshot = await _firestore
        .collection('customers')
        .where('phone', isEqualTo: normalizedPhone)
        .get();

    for (var doc in querySnapshot.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      
      final docName = (doc.data()['name'] as String).trim().toLowerCase();
      if (docName == normalizedName) {
        return true;
      }
    }
    return false;
  }

  Future<void> addCustomer() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      showToast('Please fill name and phone', Colors.red);
      return;
    }
    
    if (phoneController.text.trim().length != 10) {
      showToast('Phone must be 10 digits', Colors.red);
      return;
    }

    final discountErr = validateCustomDiscount(customDiscountPercentController.text);
    if (selectedCardId.value == null && discountErr != null) {
      showToast(discountErr, Colors.red);
      return;
    }

    try {
      isLoading.value = true;
      
      final isDup = await _isDuplicate(nameController.text, phoneController.text);
      if (isDup) {
        showToast('A customer with this exact name and phone already exists.', Colors.orange);
        return;
      }

      String? cardTier;
      double? customDiscount;
      if (selectedCardId.value != null) {
        final card = activeCards.firstWhereOrNull((c) => c.id == selectedCardId.value);
        cardTier = card?.tier;
      } else if (customDiscountPercentController.text.trim().isNotEmpty) {
        customDiscount = double.tryParse(customDiscountPercentController.text.trim());
      }

      final customer = Customer(
        id: _uuid.v4(),
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        cardId: selectedCardId.value,
        cardTier: cardTier,
        customDiscountPercent: customDiscount,
        createdAt: DateTime.now().toString(),
      );

      await _firestore.collection('customers').doc(customer.id).set(customer.toMap());

      customers.add(customer);
      searchCustomers(searchQuery.value);
      clearForm();
      showToast('Customer added successfully', Colors.green);
      Get.back();
    } catch (e) {
      showToast('Failed to add customer: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateCustomer(String id) async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      showToast('Please fill name and phone', Colors.red);
      return;
    }

    if (phoneController.text.trim().length != 10) {
      showToast('Phone must be 10 digits', Colors.red);
      return;
    }

    final discountErr = validateCustomDiscount(customDiscountPercentController.text);
    if (selectedCardId.value == null && discountErr != null) {
      showToast(discountErr, Colors.red);
      return;
    }

    try {
      isLoading.value = true;

      final isDup = await _isDuplicate(nameController.text, phoneController.text, excludeId: id);
      if (isDup) {
        showToast('A customer with this exact name and phone already exists.', Colors.orange);
        return;
      }

      final existingIndex = customers.indexWhere((c) => c.id == id);
      if (existingIndex == -1) return;
      final existingCustomer = customers[existingIndex];

      String? cardTier;
      double? customDiscount;
      if (selectedCardId.value != null) {
        final card = activeCards.firstWhereOrNull((c) => c.id == selectedCardId.value);
        cardTier = card?.tier;
      } else if (customDiscountPercentController.text.trim().isNotEmpty) {
        customDiscount = double.tryParse(customDiscountPercentController.text.trim());
      }

      final updatedCustomer = Customer(
        id: id,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        cardId: selectedCardId.value,
        cardTier: cardTier,
        customDiscountPercent: customDiscount,
        createdAt: existingCustomer.createdAt,
      );

      await _firestore.collection('customers').doc(id).update(updatedCustomer.toMap());

      customers[existingIndex] = updatedCustomer;
      searchCustomers(searchQuery.value);
      clearForm();
      showToast('Customer updated successfully', Colors.green);
      Get.back();
    } catch (e) {
      showToast('Failed to update customer: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void removeCustomer(String id) async {
    try {
      isLoading.value = true;
      await _firestore.collection('customers').doc(id).delete();
      customers.removeWhere((c) => c.id == id);
      searchCustomers(searchQuery.value);
      showToast('Customer removed successfully', Colors.green);
    } catch (e) {
      showToast('Failed to remove customer: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void loadCustomers() async {
    try {
      isLoading.value = true;
      final querySnapshot = await _firestore
          .collection('customers')
          .orderBy('createdAt', descending: true)
          .get();

      customers.clear();
      for (var doc in querySnapshot.docs) {
        customers.add(Customer.fromMap(doc.data()));
      }
      filteredCustomers.assignAll(customers);
    } catch (e) {
      showToast('Failed to load customers: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }
}
