import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/models/discount_card_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class DiscountCardController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final cards = <DiscountCard>[].obs;
  final isLoading = false.obs;

  final tierController = 'silver'.obs;
  final discountPercentController = TextEditingController();
  final activeController = true.obs;
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadCards();
  }

  void clearForm() {
    tierController.value = 'silver';
    discountPercentController.clear();
    activeController.value = true;
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

  String? validateDiscount(String? value) {
    if (value == null || value.isEmpty) return 'Discount is required';
    final numValue = double.tryParse(value);
    if (numValue == null || numValue <= 0 || numValue > 100) {
      return 'Enter a valid percentage (0-100)';
    }
    return null;
  }

  void addCard() async {
    if (discountPercentController.text.isEmpty) {
      showToast('Please fill all fields', Colors.red);
      return;
    }
    
    if (validateDiscount(discountPercentController.text) != null) {
      showToast(validateDiscount(discountPercentController.text)!, Colors.red);
      return;
    }
    
    final tier = tierController.value;
    if (cards.any((c) => c.tier.toLowerCase() == tier.toLowerCase())) {
      showToast('A discount card for ${tier.toUpperCase()} already exists.', Colors.red);
      return;
    }

    try {
      isLoading.value = true;

      final card = DiscountCard(
        id: _uuid.v4(),
        tier: tierController.value,
        discountPercent: double.parse(discountPercentController.text),
        active: activeController.value,
        createdAt: DateTime.now().toString(),
      );

      await _firestore.collection('discount_cards').doc(card.id).set(card.toMap());

      cards.add(card);
      clearForm();
      showToast('Discount Card added successfully', Colors.green);
    } catch (e) {
      showToast('Failed to add card: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void updateCard(String id) async {
    if (discountPercentController.text.isEmpty) {
      showToast('Please fill all fields', Colors.red);
      return;
    }
    
    if (validateDiscount(discountPercentController.text) != null) {
      showToast(validateDiscount(discountPercentController.text)!, Colors.red);
      return;
    }

    final tier = tierController.value;
    if (cards.any((c) => c.id != id && c.tier.toLowerCase() == tier.toLowerCase())) {
      showToast('Another discount card for ${tier.toUpperCase()} already exists.', Colors.red);
      return;
    }

    try {
      isLoading.value = true;
      
      final existingIndex = cards.indexWhere((c) => c.id == id);
      if (existingIndex == -1) return;
      final existingCard = cards[existingIndex];

      final updatedCard = DiscountCard(
        id: id,
        tier: tierController.value,
        discountPercent: double.parse(discountPercentController.text),
        active: activeController.value,
        createdAt: existingCard.createdAt,
      );

      await _firestore.collection('discount_cards').doc(id).update(updatedCard.toMap());

      cards[existingIndex] = updatedCard;
      clearForm();
      showToast('Discount Card updated successfully', Colors.green);
    } catch (e) {
      showToast('Failed to update card: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void removeCard(String cardId) async {
    try {
      isLoading.value = true;
      await _firestore.collection('discount_cards').doc(cardId).delete();
      cards.removeWhere((c) => c.id == cardId);
      showToast('Discount Card removed successfully', Colors.green);
    } catch (e) {
      showToast('Failed to remove card: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  void loadCards() async {
    try {
      isLoading.value = true;
      final querySnapshot = await _firestore
          .collection('discount_cards')
          .orderBy('createdAt', descending: true)
          .get();

      cards.clear();
      for (var doc in querySnapshot.docs) {
        cards.add(DiscountCard.fromMap(doc.data()));
      }
    } catch (e) {
      showToast('Failed to load discount cards: $e', Colors.red);
    } finally {
      isLoading.value = false;
    }
  }
}
