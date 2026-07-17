import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as dart_math;

class MigrationScript {
  static Future<void> migrateZeroBarcodes() async {
    final firestore = FirebaseFirestore.instance;
    final WriteBatch batch = firestore.batch();
    
    try {
      final querySnapshot = await firestore.collection('products').get();
      int count = 0;
      Set<String> usedBarcodes = {};

      // Collect existing non-zero barcodes
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['productId'] != null && data['productId'] != '0') {
          usedBarcodes.add(data['productId'].toString());
        }
      }

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['productId'] == '0') {
          String newBarcode;
          do {
            newBarcode = (100000 + dart_math.Random().nextInt(900000)).toString();
          } while (usedBarcodes.contains(newBarcode));
          
          usedBarcodes.add(newBarcode);
          
          batch.update(doc.reference, {'productId': newBarcode});
          
          // Also update inventory collection
          final inventoryRef = firestore.collection('inventory').doc(doc.id);
          batch.update(inventoryRef, {'productId': newBarcode});
          
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        Get.snackbar('Migration Success', 'Generated unique barcodes for $count products.', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Migration Info', 'No products with zero barcode found.', backgroundColor: Colors.blue, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Migration Error', 'Error during barcode migration: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

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
