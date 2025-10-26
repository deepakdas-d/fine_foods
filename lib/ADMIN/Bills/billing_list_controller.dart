import 'dart:developer';
import 'dart:io';
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

  /// Initializes the controller and fetches all bills on startup.
  @override
  void onInit() {
    super.onInit();
    fetchBills();
  }

  /// Fetches all bills from Firestore, ordered by creation date (newest first).
  ///
  /// Populates the [bills] observable list with maps containing:
  /// - `id`: Firestore document ID
  /// - All fields from the document data
  ///
  /// Shows loading state and error snackbar on failure.
  Future<void> fetchBills() async {
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

  /// Calculates the subtotal (sum of all product totals) for a given bill.
  ///
  /// [bill] - The bill map from Firestore.
  ///
  /// Handles legacy structure where `products` may be a Map with dynamic keys.
  /// Uses `total` field from each product to avoid recalculation errors.
  ///
  /// Returns 0.0 if no products or invalid structure.
  double calculateBillSubtotal(Map<String, dynamic> bill) {
    double subtotal = 0.0;

    final products = bill['products'];
    if (products == null) return subtotal;

    // ---- Map format (new) ----
    if (products is Map) {
      for (var entry in products.values) {
        if (entry is Map && entry['total'] is num) {
          subtotal += (entry['total'] as num).toDouble();
        }
      }
    }
    // ---- Array format (old) ----
    else if (products is List) {
      for (var item in products) {
        if (item is Map && item['total'] is num) {
          subtotal += (item['total'] as num).toDouble();
        }
      }
    }

    return subtotal;
  }

  /// Extracts the global discount amount from the bill.
  ///
  /// [bill] - The bill map.
  ///
  /// Returns 0.0 if no discount is set.
  double calculateBillDiscount(Map<String, dynamic> bill) {
    return (bill['discount'] as num?)?.toDouble() ?? 0.0;
  }

  /// -----------------------------------------------------------------
  /// 4. FINAL TOTAL (subtotal – discount, never < 0)
  /// -----------------------------------------------------------------
  double calculateBillFinalTotal(Map<String, dynamic> bill) {
    final subtotal = calculateBillSubtotal(bill);
    final discount = calculateBillDiscount(bill);
    return (subtotal - discount).clamp(0, double.infinity);
  }

  /// -----------------------------------------------------------------
  /// 5. LIST OF PRODUCT ROWS (for PDF table)
  /// -----------------------------------------------------------------
  List<Map<String, dynamic>> _extractProductRows(Map<String, dynamic> bill) {
    final List<Map<String, dynamic>> rows = [];

    final products = bill['products'];
    if (products == null) return rows;

    // ---- Map format ----
    if (products is Map) {
      for (var p in products.values) {
        if (p is Map) {
          rows.add({
            'name': p['productName']?.toString() ?? '',
            'quantity': (p['quantity'] as num?)?.toDouble() ?? 0.0,
            'price': (p['price'] as num?)?.toDouble() ?? 0.0,
            'total': (p['total'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }
    }
    // ---- Array format ----
    else if (products is List) {
      for (var p in products) {
        if (p is Map) {
          rows.add({
            'name': p['productName']?.toString() ?? '',
            'quantity': (p['quantity'] as num?)?.toDouble() ?? 0.0,
            'price': (p['price'] as num?)?.toDouble() ?? 0.0,
            'total': (p['total'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }
    }

    return rows;
  }

  /// Generates a professional PDF invoice for a single bill.
  ///
  /// [bill] - Complete bill data from Firestore.
  ///
  /// Features:
  /// - Custom Roboto font for proper Rupee symbol support
  /// - Clean layout with header, customer info, itemized table
  /// - Subtotal, discount, and bold total
  /// - Responsive column widths and padding
  /// - Fallback for old bill structures (single product)
  ///
  /// Returns [Uint8List] of the generated PDF.
  Future<Uint8List> generateBillPdf(Map<String, dynamic> bill) async {
    log('[PDF] Generating single bill PDF...');

    final pdf = pw.Document();
    final date = DateTime.parse(bill['createdAt']).toLocal();

    final subtotal = calculateBillSubtotal(bill);
    final discount = calculateBillDiscount(bill);
    final finalTotal = calculateBillFinalTotal(bill);
    final invoiceNumber = bill['invoiceNumber'] ?? 'INV-${bill['id']}';

    // Load font (Roboto supports Rupee symbol)
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final roboto = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ==== HEADER ====
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        font: roboto,
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Fine Foods POS System',
                      style: pw.TextStyle(
                        font: roboto,
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
                        font: roboto,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(date)}',
                      style: pw.TextStyle(font: roboto, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // ==== CUSTOMER INFO ====
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pw.PdfColor.fromInt(0xFFE0E0E0)),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Bill To:',
                    style: pw.TextStyle(
                      font: roboto,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    bill['customerName']?.toString() ?? 'Walk-in Customer',
                    style: pw.TextStyle(font: roboto, fontSize: 16),
                  ),
                  if ((bill['customerPhone']?.toString() ?? '').isNotEmpty)
                    pw.Text(
                      'Phone: ${bill['customerPhone']}',
                      style: pw.TextStyle(font: roboto, fontSize: 12),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // ==== ITEMS TABLE ====
            pw.Text(
              'Items:',
              style: pw.TextStyle(
                font: roboto,
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
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: pw.PdfColor.fromInt(0xFFF5F5F5),
                  ),
                  children: [
                    _tableHeaderCell('Product', roboto),
                    _tableHeaderCell('Qty', roboto, align: pw.TextAlign.center),
                    _tableHeaderCell(
                      'Price',
                      roboto,
                      align: pw.TextAlign.right,
                    ),
                    _tableHeaderCell(
                      'Total',
                      roboto,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                // Rows
                ..._extractProductRows(bill).map(
                  (p) => pw.TableRow(
                    children: [
                      _tableCell(p['name'], roboto),
                      _tableCell(
                        p['quantity'].toStringAsFixed(0),
                        roboto,
                        align: pw.TextAlign.center,
                      ),
                      _tableCell(
                        'Rs${p['price'].toStringAsFixed(2)}',
                        roboto,
                        align: pw.TextAlign.right,
                      ),
                      _tableCell(
                        'Rs${p['total'].toStringAsFixed(2)}',
                        roboto,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ==== TOTAL SUMMARY ====
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
                      _summaryRow(
                        'Subtotal:',
                        'Rs${subtotal.toStringAsFixed(2)}',
                        roboto,
                      ),
                      if (discount > 0)
                        _summaryRow(
                          'Discount:',
                          '-Rs${discount.toStringAsFixed(2)}',
                          roboto,
                        ),
                      pw.SizedBox(height: 8),
                      pw.Divider(),
                      pw.SizedBox(height: 8),
                      _summaryRow(
                        'Total:',
                        'Rs${finalTotal.toStringAsFixed(2)}',
                        roboto,
                        bold: true,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),

            // ==== FOOTER ====
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(
                  font: roboto,
                  fontSize: 14,
                  fontStyle: pw.FontStyle.italic,
                  color: pw.PdfColor.fromInt(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    log('[PDF] Single bill PDF ready');
    return pdf.save();
  }

  // -----------------------------------------------------------------
  // Helper widgets for PDF
  // -----------------------------------------------------------------
  pw.Widget _tableHeaderCell(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
        textAlign: align,
      ),
    );
  }

  pw.Widget _tableCell(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(12),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font),
        textAlign: align,
      ),
    );
  }

  pw.Widget _summaryRow(
    String label,
    String value,
    pw.Font font, {
    bool bold = false,
    double size = 14,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontWeight: bold ? pw.FontWeight.bold : null,
            fontSize: size,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: font,
            fontWeight: bold ? pw.FontWeight.bold : null,
            fontSize: size,
          ),
        ),
      ],
    );
  }

  /// Saves PDF bytes to the device's Downloads folder and opens it.
  ///
  /// [pdfBytes] - Raw PDF data.
  /// [fileName] - Desired filename (e.g., `INV-20231025-123045.pdf`).
  ///
  /// Handles Android 13+ scoped storage permissions.
  /// Creates `/Download` directory if missing.
  /// Uses [OpenFile] to launch the PDF after saving.
  ///
  /// Returns the full file path on success.
  /// Throws exception on permission denial or file error.
  Future<String> saveBillPdfToDownloads(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    final log = Logger('PDFSaver');
    log.info('[SAVE] Requesting storage permission...');

    bool granted = false;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdk = androidInfo.version.sdkInt;
      if (sdk >= 33) {
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
      log.warning('[Failed] Permission denied');
      throw Exception('Storage permission denied');
    }

    String filePath;
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) await dir.create(recursive: true);
      filePath = '${dir.path}/$fileName';
    } else {
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Cannot access Downloads folder');
      filePath = '${dir.path}/$fileName';
    }

    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    log.info('[Success] PDF saved: $filePath');

    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      throw Exception('Failed to open PDF: ${result.message}');
    }

    return filePath;
  }

  /// Generates a consolidated monthly sales report PDF.
  ///
  /// [bills] - List of bills for the target month.
  ///
  /// Sorts bills by date, groups by invoice, includes:
  /// - Per-invoice breakdown with items
  /// - Grand total and invoice count
  ///
  /// Throws if [bills] is empty.
  Future<Uint8List> generateMonthlyBillPdf(
    List<Map<String, dynamic>> bills,
  ) async {
    log('[PDF] Starting monthly bill PDF generation...');
    final pdf = pw.Document();

    if (bills.isEmpty) {
      throw Exception('No bills to generate for the month.');
    }

    // Sort bills chronologically
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
              final subtotal = calculateBillSubtotal(bill);
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
                    ),
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
                                  '₹${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  '₹${((product['price'] ?? 0) * (product['quantity'] ?? 0)).toStringAsFixed(2)}',
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
                                '₹${bill['price']?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                '₹${bill['price']?.toStringAsFixed(2) ?? '0.00'}',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 10),
                ],
              );
            }),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text(
              'Grand Total: ₹${bills.fold(0.0, (sum, bill) => sum + calculateBillSubtotal(bill)).toStringAsFixed(2)}',
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

  /// Downloads a single bill as PDF.
  ///
  /// Generates PDF → Saves to Downloads → Opens automatically.
  /// Shows loading and success/error snackbars.
  Future<void> downloadBillPdf(Map<String, dynamic> bill) async {
    try {
      isLoading.value = true;
      final pdfBytes = await generateBillPdf(bill);
      final inv = bill['invoiceNumber'] ?? 'INV-${bill['id']}';
      final fileName = '${inv.replaceAll('/', '_')}.pdf';
      await saveBillPdfToDownloads(pdfBytes, fileName);

      Get.snackbar(
        'Success',
        'Invoice PDF saved & opened',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      log('PDF download error: $e');
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

  /// Downloads a monthly sales report as PDF.
  ///
  /// [monthlyBills] - List of bills for the selected month.
  ///
  /// Validates input, generates consolidated PDF, saves, and opens.
  Future<void> downloadMonthlyReport(
    List<Map<String, dynamic>> monthlyBills,
  ) async {
    try {
      if (monthlyBills.isEmpty) {
        Get.snackbar(
          'Error',
          'No bills found for the selected månad',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      isLoading.value = true;
      final pdfBytes = await generateMonthlyBillPdf(monthlyBills);
      final monthDate = DateTime.parse(
        monthlyBills.first['createdAt'],
      ).toLocal();
      final monthLabel = DateFormat('MMMM_yyyy').format(monthDate);
      final fileName = 'Monthly_Sales_Report_$monthLabel.pdf';
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
