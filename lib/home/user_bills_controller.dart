import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fine_foods/ADMIN/Bills/billing_list_controller.dart';
import 'package:get/get.dart';

class UserBillsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State
  final RxList<Map<String, dynamic>> bills = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString searchQuery = ''.obs;
  final RxString searchText = ''.obs;

  bool get isSearching => searchQuery.value.trim().isNotEmpty;

  DocumentSnapshot? _lastDoc;
  static const int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    debounce(searchText, (val) => searchQuery.value = val, time: const Duration(milliseconds: 300));
    fetchBills(reset: true);
  }

  // Filtered bills based on searchQuery
  List<Map<String, dynamic>> get filteredBills {
    if (searchQuery.value.trim().isEmpty) return bills.toList();
    final q = searchQuery.value.trim().toLowerCase();
    return bills.where((bill) {
      final inv = (bill['invoiceNumber'] ?? '').toString().toLowerCase();
      final customer = (bill['customerName'] ?? '').toString().toLowerCase();
      
      bool hasProductMatch = false;
      final products = bill['products'];
      if (products != null) {
        Iterable<dynamic> items = [];
        if (products is Map) {
          items = products.values;
        } else if (products is List) {
          items = products;
        }
        for (final p in items) {
          if (p is Map) {
            final pName = (p['productName'] ?? p['name'] ?? '').toString().toLowerCase();
            if (pName.contains(q)) {
              hasProductMatch = true;
              break;
            }
          }
        }
      }

      return inv.contains(q) || customer.contains(q) || hasProductMatch;
    }).toList();
  }

  Future<void> fetchBills({bool reset = false}) async {
    if (reset) {
      bills.clear();
      _lastDoc = null;
      hasMore.value = true;
      isLoading.value = true;
    } else {
      if (!hasMore.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      Query query = _firestore
          .collection('bills')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();

      final newBills = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (reset) {
        bills.assignAll(newBills);
      } else {
        bills.addAll(newBills);
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
      }
      hasMore.value = snapshot.docs.length == pageSize;
    } catch (e, s) {
      log('UserBillsController Fetch Error: $e\n$s');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    await fetchBills(reset: false);
  }

  Future<void> refreshBills() async {
    await fetchBills(reset: true);
  }

  void downloadPdf(Map<String, dynamic> bill) {
    if (!Get.isRegistered<BillListController>()) {
      Get.put(BillListController());
    }
    final pdfController = Get.find<BillListController>();
    pdfController.downloadBillPdf(bill);
  }
}
