import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/ble/ble_service.dart';

class BleProvider with ChangeNotifier {
  final BleService _bleService = BleService();
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  List<DiscoveredBleDevice> _discoveredDevices = [];
  int _rssi = -60;

  StreamSubscription? _stateSub;
  StreamSubscription? _discoveredSub;
  StreamSubscription? _rssiSub;

  BleProvider() {
    _stateSub = _bleService.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    _discoveredSub = _bleService.discoveredDevicesStream.listen((devices) {
      _discoveredDevices = devices;
      notifyListeners();
    });

    _rssiSub = _bleService.rssiStream.listen((rssi) {
      _rssi = rssi;
      notifyListeners();
    });

    // Run startup workflow: try auto-reconnect first, if failed start scan
    initStartupWorkflow();
  }

  BleService get bleService => _bleService;
  BleConnectionState get connectionState => _connectionState;
  List<DiscoveredBleDevice> get discoveredDevices => _discoveredDevices;
  int get rssi => _rssi;

  bool get isConnected => _connectionState == BleConnectionState.connected;

  String get connectionStatusText {
    switch (_connectionState) {
      case BleConnectionState.disconnected:
        return "Disconnected";
      case BleConnectionState.searching:
        return "Searching for nearby Smart IV Monitors...";
      case BleConnectionState.connecting:
        return "Connecting...";
      case BleConnectionState.synchronizing:
        return "Synchronizing Device...";
      case BleConnectionState.connected:
        return "Connected";
      case BleConnectionState.failed:
        return "Connection Failed";
      case BleConnectionState.bluetoothOff:
        return "Bluetooth is Disabled";
      case BleConnectionState.permissionDenied:
        return "Bluetooth Permission Denied";
    }
  }

  Future<void> initStartupWorkflow() async {
    bool success = await _bleService.attemptAutoReconnect();
    if (!success) {
      startScan();
    }
  }

  void startScan() {
    _bleService.startScan();
  }

  void stopScan() {
    _bleService.stopScan();
  }

  Future<bool> connectToDevice(DiscoveredBleDevice target) async {
    return await _bleService.connectToSelectedDevice(target);
  }

  void disconnect() {
    _bleService.disconnect();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _discoveredSub?.cancel();
    _rssiSub?.cancel();
    super.dispose();
  }
}
