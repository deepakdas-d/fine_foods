import 'dart:developer';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fine_foods/ADMIN/invoice_generator/invoice_models.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fine_foods/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InvoiceViewController extends GetxController {
  // ─────────────── Permission Handling ───────────────

  /// Returns true if storage permission is granted or not needed (desktop).
  Future<bool> _requestStoragePermission() async {
    // Desktop platforms don't need storage permissions
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return true;
    }

    PermissionStatus status;

    if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt >= 30) {
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      status = await Permission.storage.request();
    } else {
      return true;
    }

    if (status.isGranted) {
      return true;
    }

    // If permanently denied, prompt user to open app settings
    if (status.isPermanentlyDenied) {
      final shouldOpenSettings = await _showPermissionDeniedDialog(
        isPermanent: true,
      );
      if (shouldOpenSettings) {
        await openAppSettings();
      }
      return false;
    }

    // If just denied (not permanent), ask if they want to try again
    if (status.isDenied) {
      final shouldRetry = await _showPermissionDeniedDialog(isPermanent: false);
      if (shouldRetry) {
        return _requestStoragePermission(); // Retry
      }
      return false;
    }

    return false;
  }

  /// Shows a dialog when permission is denied.
  /// Returns true if user wants to open settings (permanent) or retry (temporary).
  Future<bool> _showPermissionDeniedDialog({required bool isPermanent}) async {
    final context = Get.context;
    if (context == null) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Storage Permission Required',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        content: Text(
          isPermanent
              ? 'Storage permission was permanently denied. '
                    'Please enable it from app settings to download invoices.'
              : 'Storage permission is required to save the invoice PDF. '
                    'Would you like to grant permission?',
          style: GoogleFonts.poppins(color: AppColor.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColor.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isPermanent ? 'Open Settings' : 'Try Again',
              style: GoogleFonts.poppins(
                color: AppColor.background,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ─────────────── Download ───────────────

  Future<void> downloadInvoicePdf(Uint8List pdfBytes, String fileName) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      log('Storage permission not granted — download aborted');
      return;
    }

    // Sanitize filename — remove characters invalid in file paths
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[:\\/*?"<>|]'), '_');

    Directory? directory;
    if (Platform.isAndroid) {
      // Use the public Downloads folder so it's visible in file manager
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getDownloadsDirectory();
      }
    } else {
      directory = await getDownloadsDirectory();
    }
    directory ??= await getApplicationDocumentsDirectory();

    final filePath = '${directory.path}/$sanitizedFileName';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    log('Saved to $filePath');

    // 📂 Open the file after saving
    final result = await OpenFile.open(filePath);
    log('OpenFile result: ${result.message}');
  }

  //pdf gernerator
  Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
    // Load Unicode-compatible font for ₹ symbol support
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final roboto = pw.Font.ttf(fontData);
    final robotoBold = pw.Font.ttf(fontData); // Same file, bold via TextStyle

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: roboto, bold: robotoBold),
    );

    // Load logo image
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    // Format date
    final formattedDate =
        "${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}";

    // Build the PDF page
    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, width: 100),
              pw.Text('Date: $formattedDate'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            '${invoice.displayTitle} #${invoice.id}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),

          // Table Header
          pw.TableHelper.fromTextArray(
            headers: [invoice.displayTitle, 'Qty', 'Price', 'Total'],
            data: invoice.products.map((product) {
              return [
                product.name,
                product.count.toString(),
                '₹${product.price.toStringAsFixed(2)}',
                '₹${product.totalPrice.toStringAsFixed(2)}',
              ];
            }).toList(),
            border: pw.TableBorder.all(),
            cellStyle: pw.TextStyle(fontSize: 12, font: roboto),
            headerStyle: pw.TextStyle(
              font: roboto,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey900,
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total Amount: ₹${invoice.totalAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
