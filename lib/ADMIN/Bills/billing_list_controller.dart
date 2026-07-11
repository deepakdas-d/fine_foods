// ADMIN/Bills/billing_list_controller.dart

import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum BillFilterType { all, month, day }
enum BillSourceFilter { all, quickbill, inventory }

class BillListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable state
  final RxList<Map<String, dynamic>> bills = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isFetching = false.obs; // To prevent concurrent fetches
  final RxString searchQuery = ''.obs;
  final RxString searchText = ''.obs;

  bool get isSearching => searchQuery.value.trim().isNotEmpty;
  // Selected month filter (null = all time)
  final Rx<DateTime?> selectedMonth = Rx<DateTime?>(null);
  // Filter state
  final Rx<BillFilterType> filterType = BillFilterType.all.obs;
  final Rx<DateTime?> selectedDay = Rx<DateTime?>(null);
  // Source filter (quickbill / inventory / all)
  final Rx<BillSourceFilter> sourceFilter = BillSourceFilter.all.obs;

  List<Map<String, dynamic>> get filteredBills {
    if (searchQuery.value.trim().isEmpty) return bills;
    final query = searchQuery.value.trim().toLowerCase();
    return bills.where((bill) {
      final invoice = bill['invoiceNumber']?.toString().toLowerCase() ?? '';
      final customer = bill['customerName']?.toString().toLowerCase() ?? '';
      
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
            if (pName.contains(query)) {
              hasProductMatch = true;
              break;
            }
          }
        }
      }

      return invoice.contains(query) || customer.contains(query) || hasProductMatch;
    }).toList();
  }

  // Pagination
  DocumentSnapshot? _lastDoc;
  static const int pageSize = 30;

  @override
  void onInit() {
    super.onInit();
    debounce(searchText, (val) => searchQuery.value = val, time: const Duration(milliseconds: 300));
    fetchBills(reset: true);
  }

  // Generate last 12 months
  List<DateTime> getMonthOptions() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return DateTime(date.year, date.month);
    }).reversed.toList();
  }

  ///filter methods
  void setAllFilter() {
    filterType.value = BillFilterType.all;
    selectedMonth.value = null;
    selectedDay.value = null;
    fetchBills(reset: true);
  }

  void setMonthFilter(DateTime month) {
    filterType.value = BillFilterType.month;
    selectedMonth.value = month;
    selectedDay.value = null;
    fetchBills(reset: true);
  }

  void setDayFilter(DateTime day) {
    filterType.value = BillFilterType.day;
    selectedDay.value = day;
    selectedMonth.value = null;
    fetchBills(reset: true);
  }

  void setSourceFilter(BillSourceFilter filter) {
    sourceFilter.value = filter;
    fetchBills(reset: true);
  }

  /// Returns the source of a bill, defaulting to 'quickbill' for legacy bills.
  String getBillSource(Map<String, dynamic> bill) {
    return bill['source']?.toString() ?? 'quickbill';
  }

  // ────────────────────────────────
  // FETCH BILLS WITH MONTH FILTER
  // ────────────────────────────────
  Future<void> fetchBills({required bool reset}) async {
    if (reset) {
      bills.clear();
      _lastDoc = null;
      hasMore.value = true;
    }

    if (isFetching.value || !hasMore.value) return;

    isFetching.value = true;

    try {
      Query query = _firestore
          .collection('bills')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      // 🟡 MONTH FILTER (STRING)
      if (filterType.value == BillFilterType.month &&
          selectedMonth.value != null) {
        final m = selectedMonth.value!;

        final start = DateTime(m.year, m.month, 1).toIso8601String();
        final end = DateTime(
          m.year,
          m.month + 1,
          1,
        ).subtract(const Duration(milliseconds: 1)).toIso8601String();

        log('[FILTER] Month range: $start → $end');

        query = query
            .where('createdAt', isGreaterThanOrEqualTo: start)
            .where('createdAt', isLessThanOrEqualTo: end);
      }

      if (filterType.value == BillFilterType.day && selectedDay.value != null) {
        final d = selectedDay.value!;

        final start = DateTime(d.year, d.month, d.day).toIso8601String();
        final end = DateTime(
          d.year,
          d.month,
          d.day,
          23,
          59,
          59,
          999,
        ).toIso8601String();

        log('[FILTER] Day range: $start → $end');

        query = query
            .where('createdAt', isGreaterThanOrEqualTo: start)
            .where('createdAt', isLessThanOrEqualTo: end);
      }

      // SOURCE FILTER
      // Note: Firestore composite index required on (source, createdAt).
      // On first filtered query, Firestore logs an error with a clickable
      // link to auto-create the index in the Firebase Console.
      if (sourceFilter.value == BillSourceFilter.quickbill) {
        query = query.where('source', isEqualTo: 'quickbill');
      } else if (sourceFilter.value == BillSourceFilter.inventory) {
        query = query.where('source', isEqualTo: 'inventory');
      }

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();

      final newBills = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      bills.addAll(newBills);
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      hasMore.value = snapshot.docs.length == pageSize;
    } catch (e, s) {
      log('Fetch error: $e\n$s');
    } finally {
      isFetching.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!isLoading.value && hasMore.value) {
      await fetchBills(reset: false);
    }
  }

  // ────────────────────────────────
  // CALCULATIONS
  // ────────────────────────────────
  double calculateBillSubtotal(Map<String, dynamic> bill) {
    double total = 0.0;
    final products = bill['products'];
    if (products is Map) {
      for (var p in products.values) {
        if (p is Map<String, dynamic>) {
          total += (p['total'] as num?)?.toDouble() ?? 0.0;
        }
      }
    } else if (products is List) {
      for (var p in products) {
        if (p is Map<String, dynamic>) {
          total += (p['total'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    return total;
  }

  double calculateBillDiscount(Map<String, dynamic> bill) =>
      (bill['discount'] as num?)?.toDouble() ?? 0.0;

  double calculateBillFinalTotal(Map<String, dynamic> bill) {
    final subtotal = calculateBillSubtotal(bill);
    final discount = calculateBillDiscount(bill);
    return (subtotal - discount).clamp(0.0, double.infinity);
  }

  List<Map<String, dynamic>> extractProductRows(Map<String, dynamic> bill) {
    final List<Map<String, dynamic>> rows = [];
    final products = bill['products'];
    if (products == null) return rows;

    Iterable<Map<String, dynamic>> items = [];

    if (products is Map) {
      items = products.values.whereType<Map<String, dynamic>>();
    } else if (products is List) {
      items = products.whereType<Map<String, dynamic>>();
    }

    for (var p in items) {
      rows.add({
        'name': p['productName']?.toString().isNotEmpty == true
            ? p['productName']
            : 'Unknown Item',
        'quantity': (p['quantity'] as num?)?.toDouble() ?? 0.0,
        'price': (p['price'] as num?)?.toDouble() ?? 0.0,
        'total': (p['total'] as num?)?.toDouble() ?? 0.0,
      });
    }
    return rows;
  }

  String getPaymentMode(Map<String, dynamic> bill) {
    return bill['paymentMethod']?.toString() ??
        bill['paymentType']?.toString() ??
        'N/A';
  }

  double getReceivedAmount(Map<String, dynamic> bill) {
    if (bill['totalPaid'] != null) {
      return (bill['totalPaid'] as num).toDouble();
    }

    final cash = (bill['cashReceived'] as num?)?.toDouble() ?? 0.0;
    final online = (bill['onlineReceived'] as num?)?.toDouble() ?? 0.0;

    if (cash > 0 || online > 0) {
      return cash + online;
    }

    // fallback for version-2
    return (bill['total'] as num?)?.toDouble() ?? calculateBillFinalTotal(bill);
  }

  DateTime parseCreatedAt(dynamic createdAt) {
    if (createdAt is Timestamp) {
      return createdAt.toDate().toLocal();
    }
    if (createdAt is String) {
      return DateTime.parse(createdAt).toLocal();
    }
    return DateTime.now();
  }

  // ────────────────────────────────
  // PDF GENERATION
  // ────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchAllBillsForExport() async {
    Query query = _firestore
        .collection('bills')
        .orderBy('createdAt', descending: true);

    // MONTH FILTER
    if (filterType.value == BillFilterType.month &&
        selectedMonth.value != null) {
      final m = selectedMonth.value!;
      final start = DateTime(m.year, m.month, 1).toIso8601String();
      final end = DateTime(
        m.year,
        m.month + 1,
        1,
      ).subtract(const Duration(milliseconds: 1)).toIso8601String();

      query = query
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end);
    }

    // DAY FILTER
    if (filterType.value == BillFilterType.day && selectedDay.value != null) {
      final d = selectedDay.value!;
      final start = DateTime(d.year, d.month, d.day).toIso8601String();
      final end = DateTime(
        d.year,
        d.month,
        d.day,
        23,
        59,
        59,
        999,
      ).toIso8601String();

      query = query
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThanOrEqualTo: end);
    }

    log('[EXPORT] Fetching full dataset...');
    final snapshot = await query.get();
    log('[EXPORT] Total docs: ${snapshot.docs.length}');

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Uint8List> generateBillPdf(Map<String, dynamic> bill) async {
    final pdf = pw.Document();
    final date = parseCreatedAt(bill['createdAt']);
    final invoice = bill['invoiceNumber']?.toString().isNotEmpty == true
        ? bill['invoiceNumber']
        : 'INV-${bill['id'].substring(0, 8).toUpperCase()}';

    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final font = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "INVOICE",
                  style: pw.TextStyle(
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                    font: font,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Invoice #: $invoice",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: font,
                      ),
                    ),
                    pw.Text(
                      "Date: ${DateFormat('dd MMM yyyy • HH:mm').format(date)}",
                      style: pw.TextStyle(font: font),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Text(
              "Bill To:",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
            ),
            pw.Text(
              bill['customerName'] ?? "Walk-in Customer",
              style: pw.TextStyle(fontSize: 16, font: font),
            ),
            if (bill['customerPhone']?.toString().isNotEmpty == true)
              pw.Text(
                "Phone: ${bill['customerPhone']}",
                style: pw.TextStyle(font: font),
              ),
            pw.SizedBox(height: 30),

            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: ["Item", "Qty", "Price", "Total"]
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              font: font,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...extractProductRows(bill).map(
                  (p) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          p['name'],
                          style: pw.TextStyle(font: font),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          p['quantity'].toStringAsFixed(
                            p['quantity'] % 1 == 0 ? 0 : 1,
                          ),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: font),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          "Rs${p['price'].toStringAsFixed(2)}",
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(font: font),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          "Rs${p['total'].toStringAsFixed(2)}",
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(font: font),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              width: 250,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Payment",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                      font: font,
                    ),
                  ),
                  pw.SizedBox(height: 6),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Mode", style: pw.TextStyle(font: font)),
                      pw.Text(
                        getPaymentMode(bill),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ],
                  ),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Received", style: pw.TextStyle(font: font)),
                      pw.Text(
                        "Rs${getReceivedAmount(bill).toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: font,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 250,
                child: pw.Column(
                  children: [
                    if (calculateBillDiscount(bill) > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Subtotal:", style: pw.TextStyle(font: font)),
                          pw.Text(
                            "Rs${calculateBillSubtotal(bill).toStringAsFixed(2)}",
                            style: pw.TextStyle(font: font),
                          ),
                        ],
                      ),
                    if (calculateBillDiscount(bill) > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("Discount:", style: pw.TextStyle(font: font)),
                          pw.Text(
                            "-Rs${calculateBillDiscount(bill).toStringAsFixed(2)}",
                            style: pw.TextStyle(font: font),
                          ),
                        ],
                      ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "TOTAL:",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            font: font,
                          ),
                        ),
                        pw.Text(
                          "Rs${calculateBillFinalTotal(bill).toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            font: font,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Text(
                "Thank you!",
                style: pw.TextStyle(fontStyle: pw.FontStyle.italic, font: font),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<String> savePdf(Uint8List bytes, String fileName) async {
    // ✅ WINDOWS
    if (Platform.isWindows) {
      final path = await FileSaver.instance.saveAs(
        name: fileName.replaceAll('.pdf', ''),
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      return path ?? '';
    }

    // ✅ ANDROID
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // Android 10+
      if (androidInfo.version.sdkInt >= 29) {
        await FileSaver.instance.saveAs(
          name: fileName.replaceAll('.pdf', ''),
          bytes: bytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
        return ''; // ⚠ no real path on scoped storage
      }

      // Android < 10
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final path = '${dir.path}/$fileName';
      await File(path).writeAsBytes(bytes);
      return path;
    }

    // ✅ FALLBACK (macOS / Linux)
    final dir = Directory.systemTemp;
    final path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  Future<void> downloadBillPdf(Map<String, dynamic> bill) async {
    try {
      isLoading.value = true;

      log('[PDF] Starting download for bill ${bill['id']}');

      // 1️⃣ Generate PDF
      final bytes = await generateBillPdf(bill);
      log('[PDF] PDF generated successfully (${bytes.length} bytes)');

      // 2️⃣ File name
      final name =
          '${(bill['invoiceNumber'] ?? bill['id'].substring(0, 8)).toString().replaceAll('/', '_')}.pdf';
      log('[PDF] File name: $name');

      // 3️⃣ Save PDF
      final path = await savePdf(bytes, name);
      log('[PDF] Saved at path: "$path"');

      // 4️⃣ Notify user
      Get.snackbar(
        "Success",
        "PDF saved: $name",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // 5️⃣ Open file only if path exists
      if (path.isNotEmpty) {
        log('[PDF] Opening file...');
        await OpenFile.open(path);
      } else {
        log('[PDF] File saved but path not returned (Android 10+)');
      }
    } catch (e, s) {
      log('[PDF] Error while downloading PDF', error: e, stackTrace: s);

      Get.snackbar(
        "Error",
        "Failed to generate PDF",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      log('[PDF] Download flow completed');
    }
  }

  Future<void> downloadCurrentReport() async {
    final exportBills = await fetchAllBillsForExport();
    if (bills.isEmpty) {
      if (exportBills.isEmpty) {
        Get.snackbar(
          "Empty",
          "No bills found for selected filter",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
    }

    try {
      isLoading.value = true;
      final period = selectedMonth.value != null
          ? DateFormat('MMMM_yyyy').format(selectedMonth.value!)
          : 'All_Time';
      final fileName = 'FineFoods_Report_$period.pdf';

      // Reuse single PDF logic or generate summary — here we generate full report
      final pdf = pw.Document();
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final font = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            pw.Text(
              "Sales Report - $period",
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                font: font,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Total Bills: ${exportBills.length}"),
            pw.Text(
              "Total Sales: Rs${exportBills.fold(0.0, (sumValue, b) => sumValue + calculateBillFinalTotal(b)).toStringAsFixed(2)}",
            ),
            pw.SizedBox(height: 20),
            ...exportBills.map((bill) {
              final date = parseCreatedAt(bill['createdAt']);
              final inv =
                  bill['invoiceNumber'] ?? 'INV-${bill['id'].substring(0, 8)}';
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Divider(),
                  pw.Text(
                    "$inv • ${DateFormat('dd MMM yyyy HH:mm').format(date)} • Rs${calculateBillFinalTotal(bill).toStringAsFixed(2)}",
                  ),
                ],
              );
            }),
          ],
        ),
      );

      final bytes = await pdf.save();
      final path = await savePdf(bytes, fileName);
      Get.snackbar(
        "Success",
        "Report saved!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      OpenFile.open(path);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to generate report",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
