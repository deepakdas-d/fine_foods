import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalesGrowthController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var isLoading = true.obs;

  var productSales = <ProductSalesData>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSalesData();
  }

  Future<void> fetchSalesData() async {
    try {
      isLoading.value = true;

      // 1️⃣ Fetch sales from bills
      final billsSnapshot = await _firestore.collection('bills').get();
      final Map<String, int> salesMap = {};

      for (var bill in billsSnapshot.docs) {
        final billData = bill.data();
        if (billData['products'] != null && billData['products'] is Map) {
          Map products = billData['products'];
          for (var product in products.values) {
            if (product is Map &&
                product.containsKey('productName') &&
                product.containsKey('quantity')) {
              final name = product['productName'] ?? 'Unknown';
              final qty = (product['quantity'] ?? 0) as int;
              salesMap[name] = (salesMap[name] ?? 0) + qty;
            }
          }
        }
      }

      // 2️⃣ Fetch inventory counts
      final inventorySnapshot = await _firestore.collection('inventory').get();
      final Map<String, int> inventoryMap = {};

      for (var doc in inventorySnapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown';
        final count = (data['count'] ?? 0) as int;
        inventoryMap[name] = count;
      }

      // 3️⃣ Merge into ProductSalesData
      final List<ProductSalesData> mergedList = [];
      for (var productName in inventoryMap.keys) {
        final soldQty = salesMap[productName] ?? 0;
        final inventoryQty = inventoryMap[productName] ?? 0;
        final remainingQty = inventoryQty - soldQty;

        mergedList.add(
          ProductSalesData(
            name: productName,
            soldQty: soldQty,
            inventoryQty: inventoryQty,
            remainingQty: remainingQty,
          ),
        );
      }

      // Sort by sold quantity
      mergedList.sort((a, b) => b.soldQty.compareTo(a.soldQty));

      productSales.assignAll(mergedList);
    } catch (e) {
      print("Error fetching sales data: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

class ProductSalesData {
  final String name;
  final int soldQty;
  final int inventoryQty;
  final int remainingQty;

  ProductSalesData({
    required this.name,
    required this.soldQty,
    required this.inventoryQty,
    required this.remainingQty,
  });
}
