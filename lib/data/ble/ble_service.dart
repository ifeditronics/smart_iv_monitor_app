import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/constants/ble_uuids.dart';

enum BleConnectionState {
  disconnected,
  searching,
  connecting,
  synchronizing,
  connected,
  failed,
}

class BleService {
  BluetoothDevice? _targetDevice;
  BluetoothCharacteristic? _charDripCount;
  BluetoothCharacteristic? _charDpm;
  BluetoothCharacteristic? _charFlowStatus;
  BluetoothCharacteristic? _charWifiStatus;
  BluetoothCharacteristic? _charBatteryLevel;
  BluetoothCharacteristic? _charResetCounter;
  BluetoothCharacteristic? _charWifiSsid;
  BluetoothCharacteristic? _charWifiPass;
  BluetoothCharacteristic? _charReconnectWifi;
  BluetoothCharacteristic? _charDeviceInfo;
  BluetoothCharacteristic? _charIpAddress;

  final _connectionStateController = StreamController<BleConnectionState>.broadcast();
  Stream<BleConnectionState> get connectionStateStream => _connectionStateController.stream;

  final _dripCountController = StreamController<int>.broadcast();
  Stream<int> get dripCountStream => _dripCountController.stream;

  final _dpmController = StreamController<double>.broadcast();
  Stream<double> get dpmStream => _dpmController.stream;

  final _flowStatusController = StreamController<String>.broadcast();
  Stream<String> get flowStatusStream => _flowStatusController.stream;

  final _wifiStatusController = StreamController<String>.broadcast();
  Stream<String> get wifiStatusStream => _wifiStatusController.stream;

  final _batteryController = StreamController<int>.broadcast();
  Stream<int> get batteryStream => _batteryController.stream;

  final _rssiController = StreamController<int>.broadcast();
  Stream<int> get rssiStream => _rssiController.stream;

  BleConnectionState _currentState = BleConnectionState.disconnected;
  BleConnectionState get currentState => _currentState;

  void _updateState(BleConnectionState newState) {
    _currentState = newState;
    _connectionStateController.add(newState);
  }

  Future<void> startAutoScanAndConnect() async {
    if (_currentState == BleConnectionState.connecting || _currentState == BleConnectionState.connected) return;

    _updateState(BleConnectionState.searching);

    try {
      // Listen to scan results
      var subscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          if (r.device.platformName == "Smart IV Monitor" ||
              r.advertisementData.serviceUuids.contains(Guid(BleUuids.serviceUuid))) {
            _targetDevice = r.device;
            await FlutterBluePlus.stopScan();
            await _connectToDevice(_targetDevice!);
            break;
          }
        }
      });

      // Start scan
      await FlutterBluePlus.startScan(
        withServices: [Guid(BleUuids.serviceUuid)],
        timeout: const Duration(seconds: 15),
      );

      await Future.delayed(const Duration(seconds: 15));
      if (_currentState == BleConnectionState.searching) {
        _updateState(BleConnectionState.failed);
      }
      subscription.cancel();
    } catch (e) {
      _updateState(BleConnectionState.failed);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _updateState(BleConnectionState.connecting);
    try {
      await device.connect(autoConnect: true, timeout: const Duration(seconds: 10));
      
      // Listen to connection state shifts
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && _currentState == BleConnectionState.connected) {
          _updateState(BleConnectionState.disconnected);
          startAutoScanAndConnect(); // Auto reconnect
        }
      });

      _updateState(BleConnectionState.synchronizing);
      await _discoverAndSetupCharacteristics(device);
      _updateState(BleConnectionState.connected);
      
      // Monitor RSSI
      Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (_currentState == BleConnectionState.connected && _targetDevice != null) {
          try {
            int rssi = await _targetDevice!.readRssi();
            _rssiController.add(rssi);
          } catch (_) {}
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      _updateState(BleConnectionState.failed);
    }
  }

  Future<void> _discoverAndSetupCharacteristics(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == BleUuids.serviceUuid.toLowerCase()) {
        for (var c in service.characteristics) {
          String uuid = c.uuid.toString().toLowerCase();
          if (uuid == BleUuids.charDripCount.toLowerCase()) _charDripCount = c;
          if (uuid == BleUuids.charDropsPerMin.toLowerCase()) _charDpm = c;
          if (uuid == BleUuids.charFlowStatus.toLowerCase()) _charFlowStatus = c;
          if (uuid == BleUuids.charWifiStatus.toLowerCase()) _charWifiStatus = c;
          if (uuid == BleUuids.charBatteryLevel.toLowerCase()) _charBatteryLevel = c;
          if (uuid == BleUuids.charResetCounter.toLowerCase()) _charResetCounter = c;
          if (uuid == BleUuids.charWifiSsid.toLowerCase()) _charWifiSsid = c;
          if (uuid == BleUuids.charWifiPass.toLowerCase()) _charWifiPass = c;
          if (uuid == BleUuids.charReconnectWifi.toLowerCase()) _charReconnectWifi = c;
          if (uuid == BleUuids.charDeviceInfo.toLowerCase()) _charDeviceInfo = c;
          if (uuid == BleUuids.charIpAddress.toLowerCase()) _charIpAddress = c;
        }
      }
    }

    // Subscribe to notifications
    if (_charDripCount != null) {
      await _charDripCount!.setNotifyValue(true);
      _charDripCount!.lastValueStream.listen((data) {
        String val = utf8.decode(data).trim();
        int count = int.tryParse(val) ?? 0;
        _dripCountController.add(count);
      });
    }

    if (_charDpm != null) {
      await _charDpm!.setNotifyValue(true);
      _charDpm!.lastValueStream.listen((data) {
        String val = utf8.decode(data).trim();
        double dpm = double.tryParse(val) ?? 0.0;
        _dpmController.add(dpm);
      });
    }

    if (_charFlowStatus != null) {
      await _charFlowStatus!.setNotifyValue(true);
      _charFlowStatus!.lastValueStream.listen((data) {
        String val = utf8.decode(data).trim();
        _flowStatusController.add(val);
      });
    }

    if (_charWifiStatus != null) {
      await _charWifiStatus!.setNotifyValue(true);
      _charWifiStatus!.lastValueStream.listen((data) {
        String val = utf8.decode(data).trim();
        _wifiStatusController.add(val);
      });
    }

    if (_charBatteryLevel != null) {
      await _charBatteryLevel!.setNotifyValue(true);
      _charBatteryLevel!.lastValueStream.listen((data) {
        String val = utf8.decode(data).trim();
        int bat = int.tryParse(val) ?? 100;
        _batteryController.add(bat);
      });
    }
  }

  Future<void> sendResetCommand() async {
    if (_charResetCounter != null) {
      await _charResetCounter!.write(utf8.encode("RESET"));
    }
  }

  Future<void> writeWifiSsid(String ssid) async {
    if (_charWifiSsid != null) {
      await _charWifiSsid!.write(utf8.encode(ssid));
    }
  }

  Future<void> writeWifiPassword(String password) async {
    if (_charWifiPass != null) {
      await _charWifiPass!.write(utf8.encode(password));
    }
  }

  Future<void> sendReconnectWifiCommand() async {
    if (_charReconnectWifi != null) {
      await _charReconnectWifi!.write(utf8.encode("1"));
    }
  }

  Future<String> readDeviceInfo() async {
    if (_charDeviceInfo != null) {
      var val = await _charDeviceInfo!.read();
      return utf8.decode(val);
    }
    return "";
  }

  Future<String> readIpAddress() async {
    if (_charIpAddress != null) {
      var val = await _charIpAddress!.read();
      return utf8.decode(val);
    }
    return "0.0.0.0";
  }

  Future<String> readWifiSsid() async {
    if (_charWifiSsid != null) {
      var val = await _charWifiSsid!.read();
      return utf8.decode(val);
    }
    return "";
  }

  void disconnect() {
    _targetDevice?.disconnect();
    _updateState(BleConnectionState.disconnected);
  }
}
