import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/ble/ble_service.dart';

class BleProvider with ChangeNotifier {
  final BleService _bleService = BleService();
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  int _rssi = -60;
  StreamSubscription? _stateSub;
  StreamSubscription? _rssiSub;

  BleProvider() {
    _stateSub = _bleService.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });

    _rssiSub = _bleService.rssiStream.listen((rssi) {
      _rssi = rssi;
      notifyListeners();
    });

    // Start auto scanning on app launch
    startConnect();
  }

  BleService get bleService => _bleService;
  BleConnectionState get connectionState => _connectionState;
  int get rssi => _rssi;

  bool get isConnected => _connectionState == BleConnectionState.connected;

  String get connectionStatusText {
    switch (_connectionState) {
      case BleConnectionState.disconnected:
        return "Disconnected";
      case BleConnectionState.searching:
        return "Searching for Smart IV Monitor...";
      case BleConnectionState.connecting:
        return "Connecting...";
      case BleConnectionState.synchronizing:
        return "Synchronizing Device...";
      case BleConnectionState.connected:
        return "Connected";
      case BleConnectionState.failed:
        return "Connection Failed";
    }
  }

  void startConnect() {
    _bleService.startAutoScanAndConnect();
  }

  void disconnect() {
    _bleService.disconnect();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _rssiSub?.cancel();
    super.dispose();
  }
}
