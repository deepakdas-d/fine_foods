import 'dart:typed_data';

abstract class PrintService {
  /// Initialize the service (listeners, permissions, etc.)
  Future<void> init();

  /// Start scanning for printers and return a stream or list update mechanism
  /// For simplicity in the controller, we can just trigger a scan and rely on streams,
  /// or return a list. Given the existing controller logic uses a reactive list,
  /// we might just expose a stream of found devices or let the service update the controller.
  /// However, to keep it clean, let's have startScan return nothing but emit values via a listener or stream if possible.
  /// Refactoring the controller: The controller expects `availablePrinters` to be updated.
  /// We will define `startScan` and `stopScan`.
  Future<void> startScan({Duration timeout = const Duration(seconds: 4)});

  /// Connect to a device.
  /// [device] is dynamic because on Android it's a BluetoothDevice, on Windows it might just be a String (name).
  Future<void> connect(dynamic device);

  /// Disconnect from the current device.
  Future<void> disconnect();

  /// Send raw bytes to the printer.
  Future<void> print(Uint8List data);
  
  /// Check if connected.
  bool get isConnected;
  
  /// Stream of found devices (unified as a generic/dynamic type or wrapper wrapper).
  /// To avoid complex wrapping, we can let the controller handle the type casting based on platform,
  /// OR use a common model. For now, let's expose a stream of "Printers".
  Stream<List<dynamic>> get scanResults;
  
  /// Stream of connection status
  Stream<bool> get connectionStatus;
}
