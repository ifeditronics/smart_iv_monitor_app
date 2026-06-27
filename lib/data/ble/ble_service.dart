import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/ble_uuids.dart';
import '../models/telemetry_model.dart';

enum BleConnectionState {
  disconnected,
  searching,
  connecting,
  synchronizing,
  connected,
  failed,
  bluetoothOff,
  permissionDenied,
}

class DiscoveredBleDevice {
  final BluetoothDevice device;
  final String name;
  final int rssi;

  DiscoveredBleDevice({
    required this.device,
    required this.name,
    required this.rssi,
  });

  SignalQuality get signalQuality {
    if (rssi >= -60) return SignalQuality.excellent;
    if (rssi >= -75) return SignalQuality.good;
    if (rssi >= -85) return SignalQuality.weak; // Treated as Fair/Weak
    return SignalQuality.weak;
  }

  String get signalQualityStr {
    if (rssi >= -60) return "Excellent";
    if (rssi >= -75) return "Good";
    if (rssi >= -85) return "Fair";
    return "Weak";
  }
}

class BleService {
  static const String keyLastDeviceId = "last_connected_device_id";

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

  final _discoveredDevicesController = StreamController<List<DiscoveredBleDevice>>.broadcast();
  Stream<List<DiscoveredBleDevice>> get discoveredDevicesStream => _discoveredDevicesController.stream;

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

  final List<DiscoveredBleDevice> _discoveredList = [];

  void _updateState(BleConnectionState newState) {
    _currentState = newState;
    _connectionStateController.add(newState);
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      if (statuses[Permission.bluetoothScan]?.isDenied == true ||
          statuses[Permission.bluetoothConnect]?.isDenied == true) {
        _updateState(BleConnectionState.permissionDenied);
        return false;
      }
    }
    return true;
  }

  Future<bool> ensureBluetoothOn() async {
    BluetoothAdapterState adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (_) {}
      }
      _updateState(BleConnectionState.bluetoothOff);
      return false;
    }
    return true;
  }

  Future<bool> attemptAutoReconnect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString(keyLastDeviceId);

    if (savedId == null || savedId.isEmpty) return false;

    bool permOk = await requestPermissions();
    if (!permOk) return false;
    bool btOk = await ensureBluetoothOn();
    if (!btOk) return false;

    _updateState(BleConnectionState.connecting);
    try {
      BluetoothDevice device = BluetoothDevice.fromId(savedId);
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 5));
      _targetDevice = device;
      
      _updateState(BleConnectionState.synchronizing);
      await _discoverAndSetupCharacteristics(device);
      _updateState(BleConnectionState.connected);
      _setupDisconnectListener(device);
      return true;
    } catch (e) {
      _updateState(BleConnectionState.disconnected);
      return false;
    }
  }

  Future<void> startScan() async {
    bool permOk = await requestPermissions();
    if (!permOk) return;
    bool btOk = await ensureBluetoothOn();
    if (!btOk) return;

    _discoveredList.clear();
    _discoveredDevicesController.add(List.from(_discoveredList));
    _updateState(BleConnectionState.searching);

    try {
      await FlutterBluePlus.stopScan();

      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          String devName = r.device.platformName.trim();
          bool matchesUuid = r.advertisementData.serviceUuids.contains(Guid(BleUuids.serviceUuid));
          bool matchesName = devName.toLowerCase().contains("smart iv") || devName.toLowerCase().contains("drip");

          if (matchesUuid || matchesName || devName == "Smart IV Monitor") {
            String displayName = devName.isNotEmpty ? devName : "Smart IV Monitor";
            int index = _discoveredList.indexWhere((element) => element.device.remoteId == r.device.remoteId);
            DiscoveredBleDevice item = DiscoveredBleDevice(
              device: r.device,
              name: displayName,
              rssi: r.rssi,
            );

            if (index >= 0) {
              _discoveredList[index] = item;
            } else {
              _discoveredList.add(item);
            }
            _discoveredDevicesController.add(List.from(_discoveredList));
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      _updateState(BleConnectionState.failed);
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
  }

  Future<bool> connectToSelectedDevice(DiscoveredBleDevice target) async {
    await stopScan();
    _updateState(BleConnectionState.connecting);

    try {
      await target.device.connect(autoConnect: false, timeout: const Duration(seconds: 10));
      _targetDevice = target.device;

      _updateState(BleConnectionState.synchronizing);
      bool verified = await _discoverAndSetupCharacteristics(target.device);

      if (verified) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(keyLastDeviceId, target.device.remoteId.str);

        _updateState(BleConnectionState.connected);
        _setupDisconnectListener(target.device);
        return true;
      } else {
        await target.device.disconnect();
        _updateState(BleConnectionState.failed);
        return false;
      }
    } catch (e) {
      _updateState(BleConnectionState.failed);
      return false;
    }
  }

  void _setupDisconnectListener(BluetoothDevice device) {
    device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.disconnected && _currentState == BleConnectionState.connected) {
        _updateState(BleConnectionState.disconnected);
        bool reconnected = await attemptAutoReconnect();
        if (!reconnected) {
          startScan();
        }
      }
    });

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
  }

  Future<bool> _discoverAndSetupCharacteristics(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    bool serviceFound = false;

    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == BleUuids.serviceUuid.toLowerCase()) {
        serviceFound = true;
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

    if (!serviceFound) return false;

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

    return true;
  }

  Future<bool> sendResetCommand() async {
    if (_charResetCounter != null) {
      try {
        print("[BLE Write] Sending 'RESET' to characteristic ${BleUuids.charResetCounter}...");
        await _charResetCounter!.write(utf8.encode("RESET"), withoutResponse: false);
        print("[BLE Write] RESET command successfully transmitted to ESP32.");
        return true;
      } catch (e) {
        print("[BLE Write Error] Failed to send RESET command: $e");
        return false;
      }
    } else {
      print("[BLE Write Error] _charResetCounter is null!");
      return false;
    }
  }

  Future<bool> writeWifiSsid(String ssid) async {
    if (_charWifiSsid != null) {
      try {
        print("[BLE Write] Sending SSID '$ssid' to characteristic ${BleUuids.charWifiSsid}...");
        await _charWifiSsid!.write(utf8.encode(ssid), withoutResponse: false);
        print("[BLE Write] SSID successfully transmitted to ESP32.");
        return true;
      } catch (e) {
        print("[BLE Write Error] Failed to write SSID: $e");
        return false;
      }
    }
    return false;
  }

  Future<bool> writeWifiPassword(String password) async {
    if (_charWifiPass != null) {
      try {
        print("[BLE Write] Sending Password to characteristic ${BleUuids.charWifiPass}...");
        await _charWifiPass!.write(utf8.encode(password), withoutResponse: false);
        print("[BLE Write] Password successfully transmitted to ESP32.");
        return true;
      } catch (e) {
        print("[BLE Write Error] Failed to write Password: $e");
        return false;
      }
    }
    return false;
  }

  Future<bool> sendReconnectWifiCommand() async {
    if (_charReconnectWifi != null) {
      try {
        print("[BLE Write] Sending Reconnect command '1' to characteristic ${BleUuids.charReconnectWifi}...");
        await _charReconnectWifi!.write(utf8.encode("1"), withoutResponse: false);
        print("[BLE Write] Reconnect command successfully transmitted to ESP32.");
        return true;
      } catch (e) {
        print("[BLE Write Error] Failed to send Reconnect command: $e");
        return false;
      }
    }
    return false;
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
