import 'package:get/get.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterController extends GetxController {
  var isConnected = false.obs;
  BluetoothDevice? selectedPrinter;

  /// Request Bluetooth permissions
  Future<bool> _requestPermissions() async {
    if (GetPlatform.isAndroid) {
      if (await Permission.bluetoothScan.isDenied ||
          await Permission.bluetoothConnect.isDenied) {
        final status = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location, // for Android < 12
        ].request();

        return status.values.every((s) => s.isGranted);
      }
    }
    return true;
  }

  /// Scan, show device list, connect
  Future<void> connectPrinter(BuildContext context) async {
    try {
      // 🔑 Step 1: Ensure permissions
      final granted = await _requestPermissions();
      if (!granted) {
        Get.snackbar(
          'Permission Denied',
          'Bluetooth permissions are required to scan printers',
        );
        return;
      }

      // 2) Start scanning
      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 4));

      // 3) Show dialog with results
      final chosen = await showDialog<BluetoothDevice>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Select Bluetooth Printer'),
            content: SizedBox(
              width: double.maxFinite,
              child: StreamBuilder<List<BluetoothDevice>>(
                stream: BluetoothPrintPlus.scanResults,
                initialData: const [],
                builder: (context, snapshot) {
                  final devices = snapshot.data ?? [];
                  if (devices.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text(
                        'Scanning... (make sure printer is on & discoverable)',
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    itemBuilder: (context, i) {
                      final d = devices[i];
                      return ListTile(
                        title: Text(d.name ?? 'Unknown'),
                        subtitle: Text(d.address ?? ''),
                        onTap: () => Navigator.pop(ctx, d),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      // Stop scanning once dialog is closed
      try {
        await BluetoothPrintPlus.stopScan();
      } catch (_) {}

      if (chosen == null) return; // user canceled

      // 4) Connect
      await BluetoothPrintPlus.connect(chosen);
      selectedPrinter = chosen;

      // 5) Verify connection
      final connected = BluetoothPrintPlus.isConnected;
      isConnected.value = connected;

      if (connected) {
        Get.snackbar('Connected', 'Printer: ${chosen.name}');
      } else {
        Get.snackbar('Failed', 'Could not connect to printer');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }
}
