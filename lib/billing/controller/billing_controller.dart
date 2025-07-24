import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fine_foods/invoice_generator/models/product_models.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

class BillingController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final customerName = TextEditingController();
  final customerPhone = TextEditingController();
  final RxList<Product> products = <Product>[].obs;
  final RxMap<String, int> selectedProducts = <String, int>{}.obs;
  final RxList<Map<String, dynamic>> bills = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchBills();
  }

  void fetchProducts() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore.collection('products').get();
      products.value = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Failed to fetch products: $e');
      Get.snackbar('Error', 'Failed to fetch products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void fetchBills() async {
    isLoading.value = true;
    try {
      final snapshot = await _firestore.collection('bills').get();
      bills.value = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      log('Failed to fetch bills: $e');
      Get.snackbar('Error', 'Failed to fetch bills: $e');
    } finally {
      isLoading.value = false;
    }
  }

  int getSelectedQuantity(Product product) {
    return selectedProducts[product.id] ?? 0;
  }

  void increaseQuantity(Product product) {
    if (product.count > (selectedProducts[product.id] ?? 0)) {
      selectedProducts[product.id] = (selectedProducts[product.id] ?? 0) + 1;
    } else {
      Get.snackbar('Error', '${product.name} is out of stock');
    }
  }

  void decreaseQuantity(Product product) {
    if ((selectedProducts[product.id] ?? 0) > 0) {
      selectedProducts[product.id] = selectedProducts[product.id]! - 1;
      if (selectedProducts[product.id] == 0) {
        selectedProducts.remove(product.id);
      }
    }
  }

  double calculateTotal() {
    double total = 0;
    for (var product in products) {
      if (selectedProducts.containsKey(product.id)) {
        total += product.price * selectedProducts[product.id]!;
      }
    }
    return total;
  }

  void createBill() async {
    if (customerName.text.isEmpty || customerPhone.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all customer details');
      return;
    }

    if (selectedProducts.isEmpty) {
      Get.snackbar('Error', 'Please select at least one product');
      return;
    }

    isLoading.value = true;
    try {
      final billId = const Uuid().v4();
      final batch = _firestore.batch();

      // Create bill document
      final billData = {
        'customerName': customerName.text,
        'customerPhone': customerPhone.text,
        'products': selectedProducts.map((key, value) {
          final product = products.firstWhere((p) => p.id == key);
          return MapEntry(key, {
            'productId': key,
            'productName': product.name,
            'quantity': value,
            'price': product.price,
          });
        }),
        'total': calculateTotal(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      batch.set(_firestore.collection('bills').doc(billId), billData);

      // Update product counts
      for (var entry in selectedProducts.entries) {
        final product = products.firstWhere((p) => p.id == entry.key);
        batch.update(_firestore.collection('products').doc(product.id), {
          'count': product.count - entry.value,
        });

        // Update local product list
        final index = products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          products[index] = Product(
            id: product.id,
            name: product.name,
            count: product.count - entry.value,
            price: product.price,
            createdAt: product.createdAt,
          );
        }
      }

      await batch.commit();

      // Refresh bills list
      fetchBills();

      Get.snackbar('Success', 'Bill created successfully');
      customerName.clear();
      customerPhone.clear();
      selectedProducts.clear();
    } catch (e) {
      Get.snackbar('Error', 'Failed to create bill: $e');
    } finally {
      isLoading.value = false;
    }
  }

  double calculateBillTotal(Map<String, dynamic> bill) {
    if (bill['total'] != null && bill['total'] is num) {
      return (bill['total'] as num).toDouble();
    }
    double total = 0;
    if (bill['products'] != null && bill['products'] is Map) {
      bill['products'].values.forEach((product) {
        total += (product['price'] as num) * (product['quantity'] as num);
      });
    } else if (bill['price'] != null && bill['price'] is num) {
      total = (bill['price'] as num).toDouble();
    }
    return total;
  }

  //single download
  Future<Uint8List> generateBillPdf(Map<String, dynamic> bill) async {
    log('[PDF] Starting PDF generation...');
    final pdf = pw.Document();

    final date = DateTime.parse(bill['createdAt']).toLocal();
    final total = calculateBillTotal(bill);

    log('[PDF] Bill date: $date');
    log('[PDF] Total calculated: Rs. ${total.toStringAsFixed(2)}');

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          log('[PDF] Adding content to PDF page...');
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Invoice',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Bill ID: ${bill['id'] ?? ''}'),
              pw.Text('Customer: ${bill['customerName'] ?? ''}'),
              pw.Text('Phone: ${bill['customerPhone'] ?? ''}'),
              pw.Text('Date: ${date.toString().substring(0, 16)}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Products:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Product'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Quantity'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Price'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total'),
                      ),
                    ],
                  ),
                  if (bill['products'] != null && bill['products'] is Map)
                    ...bill['products'].values.map<pw.TableRow>((product) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(product['productName'] ?? ''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${product['quantity'] ?? 0}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Rs. ${(product['price'] ?? 0).toStringAsFixed(2)}',
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Rs. ${((product['price'] ?? 0) * (product['quantity'] ?? 0)).toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      );
                    }).toList()
                  else if (bill['productName'] != null)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(bill['productName']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('1'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs. ${(bill['price'] ?? 0).toStringAsFixed(2)}',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs. ${(bill['price'] ?? 0).toStringAsFixed(2)}',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Total: Rs. ${total.toStringAsFixed(2)}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    log('[PDF] PDF generation completed.');
    return pdf.save();
  }

  //download option
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
        // Android 13+: Request storage or photos permission
        granted =
            await Permission.photos.request().isGranted ||
            await Permission.storage.request().isGranted;
      } else {
        // Android 12 and below: Request storage permission
        granted = await Permission.storage.request().isGranted;
      }
    } else {
      granted = true; // iOS/macOS/etc., no permission needed for Downloads
    }

    if (!granted) {
      log.warning('[✗] Permission denied');
      throw Exception('Storage permission denied');
    }

    log.info('[SAVE] Permission granted.');
    String filePath;

    if (Platform.isAndroid) {
      // Use Downloads directory for Android
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        log.info('[SAVE] Creating Downloads directory...');
        await dir.create(recursive: true);
      }
      filePath = '${dir.path}/$fileName';
    } else {
      // Use getDownloadsDirectory for iOS or other platforms
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

    // Open the saved PDF file
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

    return filePath; // Return the file path
  }

  //monthly bill
  Future<Uint8List> generateMonthlyBillPdf(
    List<Map<String, dynamic>> bills,
  ) async {
    log('[PDF] Starting monthly bill PDF generation...');
    final pdf = pw.Document();

    if (bills.isEmpty) {
      throw Exception('No bills to generate for the month.');
    }

    // Grouping and sorting bills by date
    bills.sort(
      (a, b) => DateTime.parse(
        a['createdAt'],
      ).compareTo(DateTime.parse(b['createdAt'])),
    );

    final monthDate = DateTime.parse(bills.first['createdAt']).toLocal();
    final monthLabel =
        '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Text(
              'Monthly Bill Summary - $monthLabel',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),

            ...bills.map((bill) {
              final date = DateTime.parse(bill['createdAt']).toLocal();
              final total = calculateBillTotal(bill);

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('───────────────────────────────────────────────'),
                  pw.Text(
                    'Bill ID: ${bill['id'] ?? ''}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Date: ${date.toString().substring(0, 16)}'),
                  pw.Text('Customer: ${bill['customerName'] ?? ''}'),
                  pw.Text('Phone: ${bill['customerPhone'] ?? ''}'),
                  pw.SizedBox(height: 5),
                  pw.Table(
                    border: pw.TableBorder.all(),
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
                                  'Rs. ${(product['price'] ?? 0).toStringAsFixed(2)}',
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Rs. ${((product['price'] ?? 0) * (product['quantity'] ?? 0)).toStringAsFixed(2)}',
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
                                'Rs. ${(bill['price'] ?? 0).toStringAsFixed(2)}',
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                'Rs. ${(bill['price'] ?? 0).toStringAsFixed(2)}',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Subtotal: Rs. ${total.toStringAsFixed(2)}'),
                  pw.SizedBox(height: 10),
                ],
              );
            }),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text(
              'Grand Total: Rs. ${bills.fold(0.0, (sum, bill) => sum + calculateBillTotal(bill)).toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    log('[PDF] Monthly bill PDF generation completed.');
    return pdf.save();
  }
}
