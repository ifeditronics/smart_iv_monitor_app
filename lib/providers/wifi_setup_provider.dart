import 'package:flutter/foundation.dart';
import '../../data/ble/ble_service.dart';

enum WifiActionState { idle, connecting, success, failed }

class WifiSetupProvider with ChangeNotifier {
  final BleService _bleService;

  String _ssid = "";
  String _password = "";
  String _currentIp = "0.0.0.0";
  WifiActionState _actionState = WifiActionState.idle;

  WifiSetupProvider(this._bleService);

  String get ssid => _ssid;
  String get password => _password;
  String get currentIp => _currentIp;
  WifiActionState get actionState => _actionState;

  void setSSID(String value) {
    _ssid = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  Future<void> loadCurrentSettings() async {
    _ssid = await _bleService.readWifiSsid();
    _currentIp = await _bleService.readIpAddress();
    notifyListeners();
  }

  Future<void> saveCredentials() async {
    if (_ssid.isEmpty) return;
    await _bleService.writeWifiSsid(_ssid);
    if (_password.isNotEmpty) {
      await _bleService.writeWifiPassword(_password);
    }
  }

  Future<void> saveAndReconnect() async {
    _actionState = WifiActionState.connecting;
    notifyListeners();

    await saveCredentials();
    await _bleService.sendReconnectWifiCommand();

    // Wait and check connection result
    await Future.delayed(const Duration(seconds: 6));
    _currentIp = await _bleService.readIpAddress();

    if (_currentIp != "0.0.0.0" && _currentIp.isNotEmpty) {
      _actionState = WifiActionState.success;
    } else {
      _actionState = WifiActionState.failed;
    }
    notifyListeners();
  }
}
