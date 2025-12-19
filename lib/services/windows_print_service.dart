import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'print_service.dart';

class WindowsPrintService extends PrintService {
  static const MethodChannel _channel = MethodChannel(
    'com.deepak.fine_foods/printer',
  );

  final _scanResultsController = StreamController<List<dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  String? _selectedPrinter;
  bool _isConnected = false;

  @override
  Future<void> init() async {
    developer.log('[WindowsPrintService] Initializing service');
    // nothing specific for now
  }

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<List<dynamic>> get scanResults => _scanResultsController.stream;

  @override
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  @override
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      developer.log('[WindowsPrintService] Starting printer scan');
      final List<dynamic>? printers = await _channel.invokeMethod(
        'getPrinters',
      );
      if (printers != null) {
        developer.log('[WindowsPrintService] Found printers: $printers');
        _scanResultsController.add(printers);
      } else {
        developer.log('[WindowsPrintService] No printers found');
        _scanResultsController.add([]);
      }
    } catch (e) {
      developer.log(
        '[WindowsPrintService] Failed to get printers: $e',
        level: 1000,
      );
      _scanResultsController.add([]);
    }
  }

  @override
  Future<void> connect(dynamic device) async {
    developer.log(
      '[WindowsPrintService] Attempting connection to device: $device',
    );
    if (device is String) {
      _selectedPrinter = device;
      _isConnected = true;
      _connectionStatusController.add(true);
      developer.log(
        '[WindowsPrintService] Selected printer: $_selectedPrinter - Connection established',
      );
    } else {
      developer.log(
        '[WindowsPrintService] Invalid device type - Expected String, got ${device.runtimeType}',
        level: 1000,
      );
      throw Exception(
        'Invalid device type for WindowsPrintService. Expected String (Printer Name).',
      );
    }
  }

  @override
  Future<void> disconnect() async {
    developer.log('[WindowsPrintService] Disconnecting printer');
    _selectedPrinter = null;
    _isConnected = false;
    _connectionStatusController.add(false);
    developer.log('[WindowsPrintService] Disconnection complete');
  }

  @override
  Future<void> print(Uint8List data) async {
    if (!_isConnected || _selectedPrinter == null) {
      developer.log(
        '[WindowsPrintService] Printer not selected - Cannot print',
        level: 1000,
      );
      throw Exception('Printer not selected');
    }

    try {
      developer.log(
        '[WindowsPrintService] Printing to $_selectedPrinter, ${data.lengthInBytes} bytes',
      );
      developer.log(
        '[WindowsPrintService] Invoking native method channel for print',
      );
      await _channel.invokeMethod('print', {
        'device_name': _selectedPrinter,
        'data': data,
      });
      developer.log(
        '[WindowsPrintService] Method channel invoked successfully - Print job sent to native',
      );
    } catch (e) {
      developer.log('[WindowsPrintService] Print FAILED: $e', level: 1000);
      throw Exception('Print failed: $e');
    }
  }
}
