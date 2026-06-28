import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/models/telemetry_model.dart';
import '../../data/network/network_service.dart';

class TelemetryProvider with ChangeNotifier {
  final NetworkService _networkService;
  TelemetryModel _telemetry = TelemetryModel.initial();

  StreamSubscription? _dripSub;
  StreamSubscription? _dpmSub;
  StreamSubscription? _flowSub;
  StreamSubscription? _wifiSub;
  StreamSubscription? _batterySub;

  bool _showFlowStoppedWarning = false;
  FlutterLocalNotificationsPlugin? _notificationsPlugin;

  TelemetryProvider(this._networkService) {
    _initNotifications();
    _subscribeToStreams();
  }

  TelemetryModel get telemetry => _telemetry;
  bool get showFlowStoppedWarning => _showFlowStoppedWarning;
  bool get isResetReady => _networkService.isResetReady;
  String get debugStatus => "STATION_WIFI_OK";

  void _initNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _notificationsPlugin?.initialize(initSettings);
  }

  void _subscribeToStreams() {
    _dripSub = _networkService.dripCountStream.listen((count) {
      _telemetry = _telemetry.copyWith(dripCount: count, lastUpdated: DateTime.now());
      notifyListeners();
    });

    _dpmSub = _networkService.dpmStream.listen((dpm) {
      _telemetry = _telemetry.copyWith(dpm: dpm, lastUpdated: DateTime.now());
      notifyListeners();
    });

    _flowSub = _networkService.flowStatusStream.listen((statusStr) {
      String upper = statusStr.toUpperCase();
      if (upper == "STOPPED" && _telemetry.flowStatus != "STOPPED") {
        _triggerFlowStoppedAlert();
      } else if (upper != "STOPPED") {
        _showFlowStoppedWarning = false;
      }
      _telemetry = _telemetry.copyWith(flowStatus: upper, lastUpdated: DateTime.now());
      notifyListeners();
    });

    _wifiSub = _networkService.wifiStatusStream.listen((wifiStr) {
      _telemetry = _telemetry.copyWith(wifiStatus: wifiStr, lastUpdated: DateTime.now());
      notifyListeners();
    });

    _batterySub = _networkService.batteryStream.listen((bat) {
      _telemetry = _telemetry.copyWith(batteryLevel: bat, lastUpdated: DateTime.now());
      notifyListeners();
    });
  }

  void _triggerFlowStoppedAlert() async {
    _showFlowStoppedWarning = true;
    notifyListeners();

    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 500, 200, 500]);
      }
    } catch (_) {}

    const androidDetails = AndroidNotificationDetails(
      'iv_flow_alarm',
      'IV Flow Alarms',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
    );
    const notificationDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _notificationsPlugin?.show(
      101,
      'WARNING: IV FLOW STOPPED',
      'The drip monitor detected that fluid infusion has stopped completely.',
      notificationDetails,
    );
  }

  Future<bool> sendResetCommand() async {
    return await _networkService.sendResetCommand();
  }

  Future<bool> resetCounter() async {
    return await sendResetCommand();
  }

  @override
  void dispose() {
    _dripSub?.cancel();
    _dpmSub?.cancel();
    _flowSub?.cancel();
    _wifiSub?.cancel();
    _batterySub?.cancel();
    super.dispose();
  }
}
