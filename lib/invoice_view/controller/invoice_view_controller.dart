import 'dart:developer';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fine_foods/invoice_generator/models/invoice_models.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class InvoiceViewController extends GetxController {
  Future<void> downloadInvoicePdf(Uint8List pdfBytes, String fileName) async {
    if (Platform.isAndroid &&
        (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 30) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        log('Manage External Storage permission denied');
        return;
      }
    } else {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        log('Storage permission denied');
        return;
      }
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getDownloadsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory != null) {
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      log('Saved to $filePath');

      // 📂 Open the file using open_file package
      final result = await OpenFile.open(filePath);
      log('OpenFile result: ${result.message}');
    } else {
      log('Directory not found');
    }
  }

  //pdf gernerator
  Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();

    // Load logo image
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    // Format date
    final formattedDate =
        "${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}";

    // Build the PDF page
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logoImage, width: 100),
                pw.Text('Date: $formattedDate'),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Invoice #${invoice.id}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),

            // Table Header
            pw.Table.fromTextArray(
              headers: ['Item', 'Qty', 'Price', 'Total'],
              data: invoice.products.map((product) {
                return [
                  product.name,
                  product.count.toString(),
                  '₹${product.price.toStringAsFixed(2)}',
                  '₹${product.totalPrice.toStringAsFixed(2)}',
                ];
              }).toList(),
              border: pw.TableBorder.all(),
              cellStyle: pw.TextStyle(fontSize: 12),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey900),
            ),

            pw.SizedBox(height: 20),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Amount: ₹${invoice.totalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
