//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import bluetooth_print_plus
import cloud_firestore
import device_info_plus
import firebase_core
import open_file_mac
import path_provider_foundation
import printing
import share_plus

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  BluetoothPrintPlusPlugin.register(with: registry.registrar(forPlugin: "BluetoothPrintPlusPlugin"))
  FLTFirebaseFirestorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseFirestorePlugin"))
  DeviceInfoPlusMacosPlugin.register(with: registry.registrar(forPlugin: "DeviceInfoPlusMacosPlugin"))
  FLTFirebaseCorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCorePlugin"))
  OpenFilePlugin.register(with: registry.registrar(forPlugin: "OpenFilePlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  PrintingPlugin.register(with: registry.registrar(forPlugin: "PrintingPlugin"))
  SharePlusMacosPlugin.register(with: registry.registrar(forPlugin: "SharePlusMacosPlugin"))
}
