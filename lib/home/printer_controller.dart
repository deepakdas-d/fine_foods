import 'dart:developer';
import 'package:get/get.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_storage/get_storage.dart';

class PrinterController extends GetxController {
  var isConnected = false.obs;
  var isScanning = false.obs;
  var isConnecting = false.obs;
  var printerName = ''.obs;
  var availablePrinters = <BluetoothDevice>[].obs;

  String? connectingAddress;
  BluetoothDevice? selectedPrinter;
  final storage = GetStorage();

  @override
  void onInit() {
    if (GetPlatform.isWeb) {
      log("PrinterController disabled on web");
      return;
    }
    super.onInit();
    restoreLastPrinter();
    log('[PrinterController] onInit called');
    startScan();
  }

  /// Request Bluetooth permissions
  Future<bool> _requestPermissions() async {
    if (GetPlatform.isAndroid) {
      log('[PrinterController] Requesting Bluetooth permissions...');
      final status = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool granted = status.values.every((s) => s.isGranted);
      log('[PrinterController] Permissions granted: $granted');
      return granted;
    }
    return true;
  }

  /// Save last printer
  Future<void> _saveLastPrinter(BluetoothDevice device) async {
    log(
      '[PrinterController] Saving last printer: ${device.name}, ${device.address}',
    );
    await storage.write('last_printer', {
      'name': device.name,
      'address': device.address,
    });
  }

  /// Restore last printer (only load, no auto-connect)
  Future<void> restoreLastPrinter() async {
    final data = storage.read('last_printer');
    log('[PrinterController] Restore check: $data');

    if (data != null) {
      selectedPrinter = BluetoothDevice(data['name'], data['address']);
      printerName.value = data['name'];

      log('[PrinterController] Restored printer: ${data['name']}');

      // Try auto reconnect (if not connected)
      Future.delayed(const Duration(seconds: 1), () {
        if (!BluetoothPrintPlus.isConnected) {
          log('[PrinterController] Trying auto reconnect...');
          connectPrinter(selectedPrinter!);
        }
      });
    } else {
      log('[PrinterController] No saved printer found');
    }
  }

  /// Scan for printers
  Future<void> startScan() async {
    final granted = await _requestPermissions();
    if (!granted) {
      Get.snackbar('Permission', 'Bluetooth permission required');
      return;
    }

    try {
      isScanning.value = true;
      availablePrinters.clear();
      log('[PrinterController] Starting scan...');
      await BluetoothPrintPlus.startScan(timeout: const Duration(seconds: 4));

      BluetoothPrintPlus.scanResults.listen((devices) {
        log(
          '[PrinterController] Scan results: ${devices.map((d) => d.name).toList()}',
        );
        availablePrinters.value = devices;
      });
    } catch (e) {
      log('[PrinterController] Scan failed: $e', level: 1000);
      Get.snackbar('Error', 'Failed to scan: $e');
    } finally {
      isScanning.value = false;
      log('[PrinterController] Scan stopped');
    }
  }

  /// Connect to printer with loader and retry
  Future<void> connectPrinter(BluetoothDevice device) async {
    try {
      isConnecting.value = true;
      connectingAddress = device.address;
      log(
        '[PrinterController] Connecting to printer: ${device.name}, ${device.address}',
      );

      await BluetoothPrintPlus.connect(device);

      // Retry loop to ensure connection is established
      int retries = 0;
      while (retries < 6 && !BluetoothPrintPlus.isConnected) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
        log(
          '[PrinterController] Retry #$retries, isConnected=${BluetoothPrintPlus.isConnected}',
        );
      }

      isConnected.value = BluetoothPrintPlus.isConnected;

      if (isConnected.value) {
        selectedPrinter = device;
        printerName.value = device.name;
        await _saveLastPrinter(device);
        Get.snackbar("Connected", "Connected to ${device.name}");
        log('[PrinterController] Successfully connected to ${device.name}');
      } else {
        Get.snackbar("Failed", "Could not connect to printer");
        log('[PrinterController] Connection failed for ${device.name}');
      }
    } catch (e) {
      Get.snackbar("Error", "Connection failed: $e");
      log('[PrinterController] Exception during connection: $e', level: 1000);
    } finally {
      isConnecting.value = false;
      connectingAddress = null;
      log('[PrinterController] connectPrinter finished, isConnecting=false');
    }
  }

  /// Refresh connection
  Future<void> refreshConnection() async {
    final connected = BluetoothPrintPlus.isConnected;
    isConnected.value = connected;
    log('[PrinterController] refreshConnection: isConnected=$connected');
    if (!connected) printerName.value = selectedPrinter?.name ?? '';
  }

  /// Disconnect printer
  Future<void> disconnectPrinter() async {
    try {
      log('[PrinterController] Disconnecting printer...');
      await BluetoothPrintPlus.disconnect();
    } catch (_) {
      log('[PrinterController] Exception while disconnecting', level: 1000);
    }

    isConnected.value = false;
    printerName.value = '';
    log('[PrinterController] Printer disconnected');
  }
}
