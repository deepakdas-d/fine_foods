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

class BillListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable state
  final RxList<Map<String, dynamic>> bills = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;

  // Selected month filter (null = all time)
  final Rx<DateTime?> selectedMonth = Rx<DateTime?>(null);

  // Pagination
  DocumentSnapshot? _lastDoc;
  static const int pageSize = 30;

  @override
  void onInit() {
    super.onInit();
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

  // ────────────────────────────────
  // FETCH BILLS WITH MONTH FILTER
  // ────────────────────────────────
  Future<void> fetchBills({required bool reset}) async {
    if (reset) {
      bills.clear();
      _lastDoc = null;
      hasMore.value = true;
    }

    if (isLoading.value || !hasMore.value) return;

    isLoading.value = true;

    try {
      Query query = _firestore
          .collection('bills')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      // Apply month filter if selected
      if (selectedMonth.value != null) {
        final year = selectedMonth.value!.year;
        final month = selectedMonth.value!.month;

        final startOfMonth = DateTime(year, month, 1);
        final endOfMonth = DateTime(year, month + 1, 1)
            .subtract(const Duration(milliseconds: 1)); // Last millisecond of month

        query = query
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('createdAt',
                isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth));
      }

      // Pagination
      if (_lastDoc != null && !reset) {
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

      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      hasMore.value = snapshot.docs.length == pageSize;
    } catch (e, s) {
      log('Fetch bills error: $e\n$s');
      Get.snackbar('Error', 'Failed to load bills',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
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

  // ────────────────────────────────
  // PDF GENERATION
  // ────────────────────────────────
  Future<Uint8List> generateBillPdf(Map<String, dynamic> bill) async {
    final pdf = pw.Document();
    final date = (bill['createdAt'] as Timestamp).toDate().toLocal();
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
                pw.Text("INVOICE", style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, font: font)),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text("Invoice #: $invoice", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
                  pw.Text("Date: ${DateFormat('dd MMM yyyy • HH:mm').format(date)}", style: pw.TextStyle(font: font)),
                ]),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Text("Bill To:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
            pw.Text(bill['customerName'] ?? "Walk-in Customer", style: pw.TextStyle(fontSize: 16, font: font)),
            if (bill['customerPhone']?.toString().isNotEmpty == true)
              pw.Text("Phone: ${bill['customerPhone']}", style: pw.TextStyle(font: font)),
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
                      .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font))))
                      .toList(),
                ),
                ...extractProductRows(bill).map((p) => pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(p['name'], style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(p['quantity'].toStringAsFixed(p['quantity'] % 1 == 0 ? 0 : 1), textAlign: pw.TextAlign.center, style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Rs${p['price'].toStringAsFixed(2)}", textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("Rs${p['total'].toStringAsFixed(2)}", textAlign: pw.TextAlign.right, style: pw.TextStyle(font: font))),
                    ])),
              ],
            ),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 250,
                child: pw.Column(children: [
                  if (calculateBillDiscount(bill) > 0)
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text("Subtotal:", style: pw.TextStyle(font: font)),
                      pw.Text("Rs${calculateBillSubtotal(bill).toStringAsFixed(2)}", style: pw.TextStyle(font: font)),
                    ]),
                  if (calculateBillDiscount(bill) > 0)
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text("Discount:", style: pw.TextStyle(font: font)),
                      pw.Text("-Rs${calculateBillDiscount(bill).toStringAsFixed(2)}", style: pw.TextStyle(font: font)),
                    ]),
                  pw.Divider(),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text("TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, font: font)),
                    pw.Text("Rs${calculateBillFinalTotal(bill).toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, font: font)),
                  ]),
                ]),
              ),
            ),
            pw.SizedBox(height: 40),
            pw.Center(child: pw.Text("Thank you!", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, font: font))),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<String> savePdf(Uint8List bytes, String fileName) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (Platform.isAndroid && androidInfo.version.sdkInt >= 29) {
      return await FileSaver.instance.saveAs(
        name: fileName.replaceAll('.pdf', ''),
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      ) ?? '';
    } else {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) await dir.create(recursive: true);
      final path = '${dir.path}/$fileName';
      await File(path).writeAsBytes(bytes);
      return path;
    }
  }

  Future<void> downloadBillPdf(Map<String, dynamic> bill) async {
    try {
      isLoading.value = true;
      final bytes = await generateBillPdf(bill);
      final name = (bill['invoiceNumber'] ?? bill['id'].substring(0, 8))
              .toString()
              .replaceAll('/', '_') +
          '.pdf';
      final path = await savePdf(bytes, name);
      Get.snackbar("Success", "PDF saved: $name", backgroundColor: Colors.green, colorText: Colors.white);
      OpenFile.open(path);
    } catch (e) {
      Get.snackbar("Error", "Failed to generate PDF", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadCurrentReport() async {
    if (bills.isEmpty) {
      Get.snackbar("Empty", "No bills to export", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
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

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text("Sales Report - $period", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: font)),
          pw.SizedBox(height: 20),
          pw.Text("Total Bills: ${bills.length}"),
          pw.Text("Total Sales: Rs${bills.fold(0.0, (sum, b) => sum + calculateBillFinalTotal(b)).toStringAsFixed(2)}"),
          pw.SizedBox(height: 20),
          ...bills.map((bill) {
            final date = (bill['createdAt'] as Timestamp).toDate().toLocal();
            final inv = bill['invoiceNumber'] ?? 'INV-${bill['id'].substring(0, 8)}';
            return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Divider(),
              pw.Text("$inv • ${DateFormat('dd MMM yyyy HH:mm').format(date)} • Rs${calculateBillFinalTotal(bill).toStringAsFixed(2)}"),
            ]);
          }),
        ],
      ));

      final bytes = await pdf.save();
      final path = await savePdf(bytes, fileName);
      Get.snackbar("Success", "Report saved!", backgroundColor: Colors.green, colorText: Colors.white);
      OpenFile.open(path);
    } catch (e) {
      Get.snackbar("Error", "Failed to generate report", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}