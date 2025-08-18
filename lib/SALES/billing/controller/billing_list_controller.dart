import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pw;

class BillListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<Map<String, dynamic>> bills = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBills();
  }

  void fetchBills() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore
          .collection('bills')
          .orderBy('createdAt', descending: true)
          .get();
      bills.value = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      log('Failed to fetch bills: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch bills: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  double calculateBillSubtotal(Map<String, dynamic> bill) {
    double subtotal = 0;
    if (bill['products'] != null && bill['products'] is Map) {
      final products = Map<String, dynamic>.from(bill['products']);
      for (var product in products.values) {
        if (product is Map) {
          final total = (product['total'] ?? 0) as num; // use total directly
          subtotal += total;
        }
      }
    }
    return subtotal.toDouble();
  }

  double calculateBillDiscount(Map<String, dynamic> bill) {
    return ((bill['discount'] ?? 0) as num).toDouble(); // global discount
  }

  Future<Uint8List> generateBillPdf(Map<String, dynamic> bill) async {
    log('[PDF] Starting PDF generation...');

    final pdf = pw.Document();
    final date = DateTime.parse(bill['createdAt']).toLocal();

    final subtotal = calculateBillSubtotal(bill);
    final discount = calculateBillDiscount(bill);
    final total = (subtotal - discount).clamp(0, double.infinity);

    final invoiceNumber = bill['invoiceNumber'] ?? 'INV-${bill['id']}';

    log('[PDF] Invoice: $invoiceNumber');
    log('[PDF] Bill date: $date');
    log('[PDF] Subtotal: \$${subtotal.toStringAsFixed(2)}');
    log('[PDF] Discount: \$${discount.toStringAsFixed(2)}');
    log('[PDF] Final total: \$${total.toStringAsFixed(2)}');

    // 1️⃣ Load Roboto font (supports ₹)
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final robotoFont = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          font: robotoFont,
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Fine Foods POS System',
                        style: pw.TextStyle(
                          font: robotoFont,
                          fontSize: 16,
                          color: pw.PdfColor.fromInt(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Invoice #: $invoiceNumber',
                        style: pw.TextStyle(
                          font: robotoFont,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(date)}',
                        style: pw.TextStyle(font: robotoFont, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Customer Info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: pw.PdfColor.fromInt(0xFFE0E0E0)),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To:',
                      style: pw.TextStyle(
                        font: robotoFont,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${bill['customerName'] ?? 'Walk-in Customer'}',
                      style: pw.TextStyle(font: robotoFont, fontSize: 16),
                    ),
                    if (bill['customerPhone'] != null &&
                        bill['customerPhone'].toString().isNotEmpty)
                      pw.Text(
                        'Phone: ${bill['customerPhone']}',
                        style: pw.TextStyle(font: robotoFont, fontSize: 12),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Items Table
              pw.Text(
                'Items:',
                style: pw.TextStyle(
                  font: robotoFont,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(
                  color: pw.PdfColor.fromInt(0xFFE0E0E0),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: pw.PdfColor.fromInt(0xFFF5F5F5),
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          'Product',
                          style: pw.TextStyle(
                            font: robotoFont,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(
                            font: robotoFont,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          'Price',
                          style: pw.TextStyle(
                            font: robotoFont,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(12),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(
                            font: robotoFont,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),

                  // Table Items
                  if (bill['products'] != null && bill['products'] is Map)
                    ...bill['products'].values.map<pw.TableRow>((product) {
                      final price = (product['price'] ?? 0) as num;
                      final qty = (product['quantity'] ?? 0) as num;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text(
                              product['productName'] ?? '',
                              style: pw.TextStyle(font: robotoFont),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text(
                              '$qty',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(font: robotoFont),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text(
                              '₹${price.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(font: robotoFont),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(12),
                            child: pw.Text(
                              '₹${(price * qty).toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(font: robotoFont),
                            ),
                          ),
                        ],
                      );
                    }).toList()
                  else if (bill['productName'] != null) ...[
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(
                            bill['productName'],
                            style: pw.TextStyle(font: robotoFont),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(
                            '1',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(font: robotoFont),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(
                            '₹${(bill['price'] ?? 0).toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: robotoFont),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Text(
                            '₹${(bill['price'] ?? 0).toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(font: robotoFont),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 20),

              // Total Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: pw.PdfColor.fromInt(0xFFFAFAFA),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Subtotal:',
                              style: pw.TextStyle(font: robotoFont),
                            ),
                            pw.Text(
                              '₹${subtotal.toStringAsFixed(2)}',
                              style: pw.TextStyle(font: robotoFont),
                            ),
                          ],
                        ),
                        if (discount > 0) ...[
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Discount:',
                                style: pw.TextStyle(font: robotoFont),
                              ),
                              pw.Text(
                                '-₹${discount.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: robotoFont),
                              ),
                            ],
                          ),
                        ],
                        pw.SizedBox(height: 8),
                        pw.Divider(),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Total:',
                              style: pw.TextStyle(
                                font: robotoFont,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '₹${total.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                font: robotoFont,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    font: robotoFont,
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                    color: pw.PdfColor.fromInt(0xFF666666),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    log('[PDF] PDF generation completed.');
    return pdf.save();
  }

  Future<String> saveBillPdfToDownloads(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    final log = Logger('PDFSaver');
    log.info('[SAVE] Requesting storage permission...');
    bool granted = false;
    final deviceInfo = DeviceInfoPlugin();
    int sdkInt = 0;

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        granted =
            await Permission.photos.request().isGranted ||
            await Permission.storage.request().isGranted;
      } else {
        granted = await Permission.storage.request().isGranted;
      }
    } else {
      granted = true;
    }

    if (!granted) {
      log.warning('[✗] Permission denied');
      throw Exception('Storage permission denied');
    }

    log.info('[SAVE] Permission granted.');
    String filePath;

    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        log.info('[SAVE] Creating Downloads directory...');
        await dir.create(recursive: true);
      }
      filePath = '${dir.path}/$fileName';
    } else {
      final dir = await getDownloadsDirectory();
      if (dir == null) {
        log.warning('[✗] Could not access Downloads directory');
        throw Exception('Could not access Downloads directory');
      }
      filePath = '${dir.path}/$fileName';
    }

    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    log.info('[✓] PDF saved successfully to: $filePath');

    try {
      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.done) {
        log.info('[✓] PDF opened successfully');
      } else {
        log.warning('[✗] Failed to open PDF: ${result.message}');
        throw Exception('Failed to open PDF: ${result.message}');
      }
    } catch (e) {
      log.severe('[✗] Error opening PDF: $e');
      throw Exception('Error opening PDF: $e');
    }

    return filePath;
  }

  Future<Uint8List> generateMonthlyBillPdf(
    List<Map<String, dynamic>> bills,
  ) async {
    log('[PDF] Starting monthly bill PDF generation...');
    final pdf = pw.Document();

    if (bills.isEmpty) {
      throw Exception('No bills to generate for the month.');
    }

    bills.sort(
      (a, b) => DateTime.parse(
        a['createdAt'],
      ).compareTo(DateTime.parse(b['createdAt'])),
    );

    final monthDate = DateTime.parse(bills.first['createdAt']).toLocal();
    final monthLabel = DateFormat('MMMM yyyy').format(monthDate);

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Text(
              'Monthly Sales Report - $monthLabel',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            ...bills.map((bill) {
              final date = DateTime.parse(bill['createdAt']).toLocal();
              final total = calculateBillSubtotal(bill);
              final invoiceNumber =
                  bill['invoiceNumber'] ?? 'INV-${bill['id']}';

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('───────────────────────────────────────────────'),
                  pw.Text(
                    'Invoice: $invoiceNumber',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(date)}',
                  ),
                  pw.Text(
                    'Customer: ${bill['customerName'] ?? 'Walk-in Customer'}',
                  ),
                  if (bill['customerPhone'] != null &&
                      bill['customerPhone'].toString().isNotEmpty)
                    pw.Text('Phone: ${bill['customerPhone']}'),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: pw.PdfColor.fromInt(0xFFE0E0E0),
                    ), // Grey300 equivalent
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Product'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Qty'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Price'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('Total'),
                          ),
                        ],
                      ),
                      if (bill['products'] != null && bill['products'] is Map)
                        ...bill['products'].values.map<pw.TableRow>((product) {
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(product['productName'] ?? ''),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text('${product['quantity'] ?? 0}'),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  '\$${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  '\$${((product['price'] ?? 0) * (product['quantity'] ?? 0)).toStringAsFixed(2)}',
                                ),
                              ),
                            ],
                          );
                        }).toList()
                      else if (bill['productName'] != null)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(bill['productName']),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text('1'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                '\$${bill['price']?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                '\$${bill['price']?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Subtotal: \$${total.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 10),
                ],
              );
            }),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text(
              'Grand Total: \$${bills.fold(0.0, (sum, bill) => sum + calculateBillSubtotal(bill)).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Total Invoices: ${bills.length}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    log('[PDF] Monthly bill PDF generation completed.');
    return pdf.save();
  }

  // Helper method to download bill PDF
  Future<void> downloadBillPdf(Map<String, dynamic> bill) async {
    try {
      isLoading.value = true;
      // Generate PDF
      final pdfBytes = await generateBillPdf(bill);
      // Create filename
      final invoiceNumber = bill['invoiceNumber'] ?? 'INV-${bill['id']}';
      final fileName = '${invoiceNumber.replaceAll('/', '_')}.pdf';
      // Save and open PDF
      await saveBillPdfToDownloads(pdfBytes, fileName);
      Get.snackbar(
        'Success',
        'PDF saved and opened successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log('Error downloading PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to download PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to download monthly report
  Future<void> downloadMonthlyReport(
    List<Map<String, dynamic>> monthlyBills,
  ) async {
    try {
      if (monthlyBills.isEmpty) {
        Get.snackbar(
          'Error',
          'No bills found for the selected month',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;
      // Generate monthly PDF
      final pdfBytes = await generateMonthlyBillPdf(monthlyBills);
      // Create filename
      final monthDate = DateTime.parse(
        monthlyBills.first['createdAt'],
      ).toLocal();
      final monthLabel = DateFormat('MMMM_yyyy').format(monthDate);
      final fileName = 'Monthly_Sales_Report_$monthLabel.pdf';
      // Save and open PDF
      await saveBillPdfToDownloads(pdfBytes, fileName);
      Get.snackbar(
        'Success',
        'Monthly report PDF saved and opened successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log('Error downloading monthly report PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to download monthly report PDF: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
