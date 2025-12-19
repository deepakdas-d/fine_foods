import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:get/Get.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:get_storage/get_storage.dart';
import '../services/print_service.dart';
import '../services/android_print_service.dart';
import '../services/windows_print_service.dart';

class PrinterController extends GetxController {
  var isConnected = false.obs;
  var isScanning = false.obs;
  var isConnecting = false.obs;
  var printerName = ''.obs;
  var availablePrinters = <BluetoothDevice>[].obs;

  String? connectingAddress;
  BluetoothDevice? selectedPrinter;
  final storage = GetStorage();

  late PrintService _service;

  @override
  void onInit() {
    if (GetPlatform.isWeb) {
      developer.log("PrinterController disabled on web");
      return;
    }

    // Setup Service
    if (GetPlatform.isWindows) {
      _service = WindowsPrintService();
      developer.log('[PrinterController] Initialized WindowsPrintService');
    } else {
      _service = AndroidPrintService();
      developer.log('[PrinterController] Initialized AndroidPrintService');
    }

    super.onInit();

    // Bind streams
    _service.scanResults.listen((devices) {
      final List<BluetoothDevice> mapped = [];
      for (var d in devices) {
        if (d is BluetoothDevice) {
          mapped.add(d);
        } else if (d is String) {
          mapped.add(BluetoothDevice(d, d)); // Use name as address
        }
      }
      availablePrinters.value = mapped;
      developer.log(
        '[PrinterController] Scan results updated: ${mapped.length} devices',
      );
    });

    _service.connectionStatus.listen((connected) {
      isConnected.value = connected;
      developer.log(
        '[PrinterController] Connection status changed: $connected',
      );
      if (connected && selectedPrinter != null) {
        developer.log(
          '[PrinterController] Printer connected and stable: ${selectedPrinter!.name}',
        );
        // Removed Get.snackbar to avoid Overlay error
      }
    });

    restoreLastPrinter();
    developer.log('[PrinterController] onInit called');
    startScan();
  }

  Future<void> _saveLastPrinter(BluetoothDevice device) async {
    developer.log(
      '[PrinterController] Saving last printer: ${device.name}, ${device.address}',
    );
    await storage.write('last_printer', {
      'name': device.name,
      'address': device.address,
    });
  }

  Future<void> restoreLastPrinter() async {
    final data = storage.read('last_printer');
    developer.log('[PrinterController] Restore check: $data');

    if (data != null) {
      selectedPrinter = BluetoothDevice(data['name'], data['address']);
      printerName.value = data['name'];

      developer.log('[PrinterController] Restored printer: ${data['name']}');

      // Try auto reconnect (if not connected)
      Future.delayed(const Duration(seconds: 1), () {
        if (!isConnected.value) {
          developer.log('[PrinterController] Trying auto reconnect...');
          connectPrinter(selectedPrinter!);
        }
      });
    } else {
      developer.log('[PrinterController] No saved printer found');
    }
  }

  Future<void> startScan() async {
    try {
      isScanning.value = true;
      availablePrinters.clear();
      developer.log('[PrinterController] Starting printer scan');
      await _service.startScan(timeout: const Duration(seconds: 4));
      developer.log('[PrinterController] Scan completed');
    } catch (e) {
      developer.log('[PrinterController] Scan failed: $e', level: 1000);
      Get.snackbar('Error', 'Failed to scan: $e');
    } finally {
      isScanning.value = false;
    }
  }

  Future<void> connectPrinter(BluetoothDevice device) async {
    try {
      developer.log(
        'DEBUG: PrinterController.connectPrinter called for ${device.name}',
      );
      isConnecting.value = true;
      connectingAddress = device.address;
      developer.log(
        '[PrinterController] Connecting to printer: ${device.name}, ${device.address}',
      );

      dynamic target;
      if (GetPlatform.isWindows) {
        target = device.name;
        developer.log('DEBUG: Targeting Windows printer by name: $target');
      } else {
        target = device;
      }

      await _service.connect(target);
      developer.log('DEBUG: Service connect returned successfully');
      developer.log(
        '[PrinterController] Connection successful - checking stability',
      );

      selectedPrinter = device;
      printerName.value = device.name;
      await _saveLastPrinter(device);
    } catch (e) {
      developer.log('[PrinterController] Connection failed: $e', level: 1000);
      Get.snackbar("Error", "Connection failed: $e");
    } finally {
      isConnecting.value = false;
      connectingAddress = null;
    }
  }

  Future<void> refreshConnection() async {
    developer.log('[PrinterController] Refreshing connection status');
    isConnected.value = _service.isConnected;
    if (isConnected.value) {
      developer.log('[PrinterController] Connection is stable');
    } else {
      developer.log('[PrinterController] Connection lost or unstable');
      printerName.value = selectedPrinter?.name ?? '';
    }
  }

  Future<void> disconnectPrinter() async {
    try {
      developer.log('[PrinterController] Disconnecting printer...');
      await _service.disconnect();
      developer.log('[PrinterController] Disconnect successful');
    } catch (e) {
      developer.log('[PrinterController] Disconnect failed: $e', level: 1000);
    }

    printerName.value = '';
    developer.log('[PrinterController] Printer disconnected');
  }

  Future<void> print(Uint8List data) async {
    developer.log(
      '[PrinterController] Starting print job with ${data.length} bytes',
    );
    try {
      await _service.print(data);
      developer.log(
        '[PrinterController] Print job sent to service successfully',
      );
    } catch (e) {
      developer.log('[PrinterController] Print job failed: $e', level: 1000);
      rethrow;
    }
  }
}
