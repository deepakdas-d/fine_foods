import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'print_service.dart';

class AndroidPrintService extends PrintService {
  final _scanResultsController = StreamController<List<dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();
  
  AndroidPrintService();

  @override
  Future<void> init() async {
    // Initialization logic if any
  }

  @override
  bool get isConnected => BluetoothPrintPlus.isConnected;

  @override
  Stream<List<dynamic>> get scanResults => _scanResultsController.stream;
  
  @override
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  Future<bool> _requestPermissions() async {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return false;
    }
    log('[AndroidPrintService] Requesting Bluetooth permissions...');
    final status = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    bool granted = status.values.every((s) => s.isGranted);
    log('[AndroidPrintService] Permissions granted: $granted');
    return granted;
  }

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 4)}) async {
    final granted = await _requestPermissions();
    if (!granted) {
      throw Exception('Bluetooth permissions not granted');
    }

    log('[AndroidPrintService] Starting scan...');
    _scanResultsController.add([]); // Clear previous results
    
    await BluetoothPrintPlus.startScan(timeout: timeout);

    BluetoothPrintPlus.scanResults.listen((devices) {
       _scanResultsController.add(devices);
    });
  }

  @override
  Future<void> connect(dynamic device) async {
    if (device is! BluetoothDevice) {
       throw Exception('Invalid device type for AndroidPrintService');
    }
    
    log('[AndroidPrintService] Connecting to ${device.name} (${device.address})');
    await BluetoothPrintPlus.connect(device);
    
    // The state stream should handle the update, but we can double check
    // The controller had a retry loop, let's keep it simply here or let controller handle retry?
    // Best to encapsulate retry logic here if it's reliable.
    int retries = 0;
    while (retries < 6 && !BluetoothPrintPlus.isConnected) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
    }
    
    if (BluetoothPrintPlus.isConnected) {
       _connectionStatusController.add(true);
    } else {
       _connectionStatusController.add(false);
       throw Exception('Failed to connect to printer');
    }
  }

  @override
  Future<void> disconnect() async {
    await BluetoothPrintPlus.disconnect();
    _connectionStatusController.add(false);
  }

  @override
  Future<void> print(Uint8List data) async {
    if (!isConnected) {
      throw Exception('Printer not connected');
    }
    await BluetoothPrintPlus.write(data);
  }
}
