import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MigrationScript {
  static Future<void> backfillProductCardDiscountExcluded() async {
    final firestore = FirebaseFirestore.instance;
    final WriteBatch batch = firestore.batch();
    
    try {
      final querySnapshot = await firestore.collection('products').get();
      int count = 0;

      for (var doc in querySnapshot.docs) {
        if (!doc.data().containsKey('cardDiscountExcluded')) {
          batch.update(doc.reference, {'cardDiscountExcluded': false});
          count++;
        }
      }

      final inventorySnapshot = await firestore.collection('inventory').get();
      for (var doc in inventorySnapshot.docs) {
        if (!doc.data().containsKey('cardDiscountExcluded')) {
          batch.update(doc.reference, {'cardDiscountExcluded': false});
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        Get.snackbar('Migration Success', 'Backfilled cardDiscountExcluded for $count products.', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Migration Info', 'No products needed backfilling.', backgroundColor: Colors.blue, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Migration Error', 'Error during backfill: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
