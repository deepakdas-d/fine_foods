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

      // 1️⃣ Fetch sales from products collection
      final productsSnapshot = await _firestore.collection('products').get();
      final Map<String, int> salesMap = {};

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown';
        final count = ((data['count'] ?? 0) as num).toInt();
        salesMap[name] = (salesMap[name] ?? 0) + count;
      }

      // 2️⃣ Fetch inventory counts
      final inventorySnapshot = await _firestore.collection('inventory').get();
      final Map<String, int> inventoryMap = {};

      for (var doc in inventorySnapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown';
        final count = ((data['count'] ?? 0) as num).toInt();
        inventoryMap[name] = (inventoryMap[name] ?? 0) + count;
      }

      // 3️⃣ Merge into ProductSalesData
      final Set<String> allProducts = {...inventoryMap.keys, ...salesMap.keys};
      final List<ProductSalesData> mergedList = [];
      
      for (var productName in allProducts) {
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

      // Sort by sold quantity (descending), then by name
      mergedList.sort((a, b) {
        int cmp = b.soldQty.compareTo(a.soldQty);
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });

      productSales.assignAll(mergedList);
    } catch (e) {
      Get.log("Error fetching sales data: $e");
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
