import 'package:fine_foods/SALES/billing/controller/billing_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_storage/get_storage.dart';

class PrinterController extends GetxController with WidgetsBindingObserver {
  var isConnected = false.obs;
  var isScanning = false.obs;
  var printerName = ''.obs;
  var selectedIndex = 0.obs;
  final pageController = PageController();
  final BillingController billingController = Get.put(BillingController());

  BluetoothDevice? selectedPrinter;
  final storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Try reconnect on startup
    _restoreLastPrinter();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app resumes after call/background
      if (!isConnected.value && selectedPrinter != null) {
        Get.snackbar(
          'Printer',
          'Reconnecting to last printer...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        connectToLastPrinter();
      }
    }
  }

  void changePage(int index) {
    selectedIndex.value = index;
    pageController.jumpToPage(index);
  }

  /// Request Bluetooth permissions
  Future<bool> _requestPermissions() async {
    if (GetPlatform.isAndroid) {
      final status = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // needed for Android < 12
      ].request();

      return status.values.every((s) => s.isGranted);
    }
    return true;
  }

  /// Save last printer in storage
  /// Save last printer in storage
  Future<void> _saveLastPrinter(BluetoothDevice device) async {
    await storage.write('last_printer', {
      'name': device.name,
      'address': device.address,
    });
  }

  /// Restore last printer on startup
  /// Restore last printer on startup
  Future<void> _restoreLastPrinter() async {
    final data = storage.read('last_printer');
    if (data != null && data is Map) {
      final name = data['name'] ?? 'Saved Printer';
      final addr = data['address'];
      if (addr != null) {
        selectedPrinter = BluetoothDevice(name, addr);

        Get.snackbar(
          'Printer',
          'Restoring last printer: $name',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        await connectToLastPrinter();
      }
    }
  }

  /// Connect to the previously saved printer
  Future<void> connectToLastPrinter() async {
    if (selectedPrinter == null) return;
    try {
      await BluetoothPrintPlus.connect(selectedPrinter!);
      isConnected.value = BluetoothPrintPlus.isConnected;
    } catch (_) {
      isConnected.value = false;
    }
  }

  /// Scan, show list, connect
  Future<void> connectPrinter(BuildContext context) async {
    try {
      final granted = await _requestPermissions();
      if (!granted) return;

      isScanning.value = true;
      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 5));
      await Future.delayed(const Duration(seconds: 1));

      final bonded = await BluetoothPrintPlus.scanResults.firstWhere(
        (list) => list.isNotEmpty,
        orElse: () => [],
      );

      isScanning.value = false;

      final chosen = await showDialog<BluetoothDevice>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Select Bluetooth Printer'),
            content: SizedBox(
              width: double.maxFinite,
              child: StreamBuilder<List<BluetoothDevice>>(
                stream: BluetoothPrintPlus.scanResults,
                initialData: bonded,
                builder: (context, snapshot) {
                  final devices = [
                    ...bonded,
                    ...snapshot.data!.where((d) => !bonded.contains(d)),
                  ];

                  if (devices.isEmpty) {
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    itemBuilder: (context, i) {
                      final d = devices[i];
                      return ListTile(
                        title: Text(d.name),
                        subtitle: Text(d.address),
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

      try {
        await BluetoothPrintPlus.stopScan();
      } catch (_) {}

      if (chosen == null) return;

      // Try connect with retries
      await Future.delayed(const Duration(seconds: 1));
      bool connected = false;
      for (int i = 0; i < 2; i++) {
        try {
          await BluetoothPrintPlus.connect(chosen);
          connected = BluetoothPrintPlus.isConnected;
          if (connected) break;
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 500));
      }

      isConnected.value = connected;

      if (connected) {
        selectedPrinter = chosen;
        await _saveLastPrinter(chosen);
        Get.snackbar('Connected', 'Printer: ${chosen.name}');
      } else {
        Get.snackbar('Failed', 'Could not connect to printer');
      }
    } catch (e) {
      isScanning.value = false;
      Get.snackbar('Error', e.toString());
    }
  }

  // Quick billing
}
