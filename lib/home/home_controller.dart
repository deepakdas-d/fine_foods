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
  var availablePrinters = <BluetoothDevice>[].obs;

  final billingController = Get.put(BillingController());
  final storage = GetStorage();
  BluetoothDevice? selectedPrinter;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _restoreLastPrinter();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !isConnected.value &&
        selectedPrinter != null) {
      Get.snackbar(
        'Printer',
        'Reconnecting to last printer...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      connectToLastPrinter();
    }
  }

  /// ✅ Ask permissions for Bluetooth
  Future<bool> _requestPermissions() async {
    if (GetPlatform.isAndroid) {
      final status = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      return status.values.every((s) => s.isGranted);
    }
    return true;
  }

  /// ✅ Save last printer info
  Future<void> _saveLastPrinter(BluetoothDevice device) async {
    await storage.write('last_printer', {
      'name': device.name,
      'address': device.address,
    });
  }

  /// ✅ Restore last printer and auto reconnect
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

  /// ✅ Connect to the saved printer
  Future<void> connectToLastPrinter() async {
    if (selectedPrinter == null) return;
    try {
      await BluetoothPrintPlus.connect(selectedPrinter!);
      isConnected.value = BluetoothPrintPlus.isConnected;
      if (isConnected.value) printerName.value = selectedPrinter?.name ?? '';
    } catch (_) {
      isConnected.value = false;
      printerName.value = '';
    }
  }

  /// ✅ Start scanning for printers (used in PrinterSelectionPage)
  Future<void> startScan() async {
    final granted = await _requestPermissions();
    if (!granted) {
      Get.snackbar('Permission', 'Bluetooth permission required');
      return;
    }

    try {
      isScanning.value = true;
      availablePrinters.clear();

      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 4));
      BluetoothPrintPlus.scanResults.listen((devices) {
        availablePrinters.value = devices;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to scan: $e');
    } finally {
      isScanning.value = false;
    }
  }

  /// ✅ Stop scanning manually
  Future<void> stopScan() async {
    try {
      await BluetoothPrintPlus.stopScan();
    } catch (_) {}
    isScanning.value = false;
  }

  /// ✅ Connect to a selected printer from list
  Future<void> connectPrinter(BluetoothDevice device) async {
    try {
      await BluetoothPrintPlus.connect(device);
      final connected = BluetoothPrintPlus.isConnected;
      isConnected.value = connected;

      if (connected) {
        selectedPrinter = device;
        printerName.value = device.name;
        await _saveLastPrinter(device);
        Get.snackbar('Connected', 'Printer: ${device.name}');
      } else {
        Get.snackbar('Failed', 'Could not connect to ${device.name}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Connection failed: $e');
    }
  }

  /// ✅ Disconnect printer
  Future<void> disconnectPrinter() async {
    try {
      await BluetoothPrintPlus.disconnect();
    } catch (_) {}
    isConnected.value = false;
    printerName.value = '';
  }

  /// === NEW ===
  /// Check the current printer connection state and update observables.
  /// If [tryReconnect] is true and there's a saved `selectedPrinter`, this will
  /// attempt a couple of quick reconnect tries.
  Future<void> checkPrinterConnection({bool tryReconnect = false}) async {
    try {
      // Query the underlying library for connection status
      final connected = BluetoothPrintPlus.isConnected;
      isConnected.value = connected;

      if (connected) {
        // If we are connected but don't have a name set, try to set it
        if (printerName.value.isEmpty) {
          printerName.value =
              selectedPrinter?.name ??
              storage.read('last_printer')?['name'] ??
              'Printer';
        }
        return;
      }

      // Not connected
      printerName.value = '';

      if (tryReconnect && selectedPrinter != null) {
        Get.snackbar(
          'Printer',
          'Attempting quick reconnect...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );

        bool reconnected = false;
        for (int i = 0; i < 2; i++) {
          try {
            await BluetoothPrintPlus.connect(selectedPrinter!);
            reconnected = BluetoothPrintPlus.isConnected;
            if (reconnected) break;
          } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 500));
        }

        isConnected.value = reconnected;
        if (reconnected) {
          printerName.value =
              selectedPrinter?.name ??
              storage.read('last_printer')?['name'] ??
              'Printer';
          Get.snackbar('Connected', 'Reconnected to ${printerName.value}');
        } else {
          Get.snackbar('Printer', 'Not connected');
        }
      }
    } catch (e) {
      // On error, ensure state is consistent
      isConnected.value = false;
      printerName.value = '';
      Get.snackbar('Error', 'Failed to check printer state: $e');
    }
  }
}
