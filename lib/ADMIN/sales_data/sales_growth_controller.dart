import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalesGrowthController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var isLoading = true.obs;

  var productSales = <ProductSalesData>[].obs;
  var selectedFilter = 'This Month'.obs;

  // Client-side display pagination (doesn't affect dashboard analytics)
  static const int displayPageSize = 20;
  final displayCount = 20.obs;

  List<ProductSalesData> get displayedProducts {
    if (displayCount.value >= productSales.length) return productSales;
    return productSales.sublist(0, displayCount.value);
  }

  bool get hasMoreToDisplay => displayCount.value < productSales.length;

  void loadMoreDisplay() {
    if (!hasMoreToDisplay) return;
    displayCount.value = (displayCount.value + displayPageSize)
        .clamp(0, productSales.length);
  }

  @override
  void onInit() {
    super.onInit();
    fetchSalesData();
  }

  void changeFilter(String newFilter) {
    selectedFilter.value = newFilter;
    displayCount.value = displayPageSize;
    fetchSalesData();
  }

  Future<void> fetchSalesData() async {
    try {
      isLoading.value = true;

      // 1️⃣ Determine the doc key based on the filter
      final now = DateTime.now();
      String docKey = '';
      
      switch (selectedFilter.value) {
        case 'Today':
          docKey = 'daily_${DateFormat('yyyy-MM-dd').format(now)}';
          break;
        case 'This Month':
          docKey = 'monthly_${DateFormat('yyyy-MM').format(now)}';
          break;
        case 'This Year':
          docKey = 'yearly_${DateFormat('yyyy').format(now)}';
          break;
        case 'All Time':
        default:
          docKey = 'all_time';
          break;
      }

      // 2️⃣ Fetch the single stats document
      final statsDoc = await _firestore.collection('sales_stats').doc(docKey).get();
      final Map<String, int> soldQtyById = {};
      final Map<String, String> bucketNameById = {};
      
      if (statsDoc.exists && statsDoc.data() != null) {
        final data = statsDoc.data()!;
        data.forEach((key, value) {
          if (value is Map) {
            soldQtyById[key] = ((value['qty'] ?? 0) as num).toInt();
            bucketNameById[key] = value['name']?.toString() ?? 'Unknown';
          } else {
            // Fallback just in case there's old data
            soldQtyById[key] = (value as num).toInt();
          }
        });
      }

      // 3️⃣ Fetch current product details from products collection
      final productsSnapshot = await _firestore.collection('products').get();
      final Map<String, int> remainingQtyById = {};
      final Map<String, String> nameById = {};

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final productId = doc.id;
        final name = data['name'] ?? 'Unknown';
        final count = ((data['count'] ?? 0) as num).toInt();
        
        remainingQtyById[productId] = count;
        nameById[productId] = name;
      }

      // 4️⃣ Merge into ProductSalesData
      final Set<String> allProductIds = {...soldQtyById.keys, ...remainingQtyById.keys};
      final List<ProductSalesData> mergedList = [];
      
      for (var productId in allProductIds) {
        // If the product is deleted, it won't be in nameById, so we fall back to bucketNameById!
        final name = nameById[productId] ?? bucketNameById[productId] ?? 'Unknown Product';
        final soldQty = soldQtyById[productId] ?? 0;
        final remainingQty = remainingQtyById[productId] ?? 0;
        final inventoryQty = soldQty + remainingQty; // Total historically stocked

        mergedList.add(
          ProductSalesData(
            name: name,
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
      displayCount.value = displayPageSize.clamp(0, mergedList.length);
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
