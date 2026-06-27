import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/models/telemetry_model.dart';
import '../../data/ble/ble_service.dart';

class TelemetryProvider with ChangeNotifier {
  final BleService _bleService;
  TelemetryModel _telemetry = TelemetryModel.initial();

  // Streams Subscriptions
  StreamSubscription? _dripSub;
  StreamSubscription? _dpmSub;
  StreamSubscription? _flowSub;
  StreamSubscription? _wifiSub;
  StreamSubscription? _batterySub;
  StreamSubscription? _rssiSub;

  // Infusion Session & Alarm Tracking
  Timer? _sessionTimer;
  int _flowingDurationSeconds = 0;
  bool _isInfusionSessionActive = false;
  bool _showFlowStoppedWarning = false;
  bool _hasAlreadyNotifiedStopped = false;

  // Local Notifications Plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  TelemetryProvider(this._bleService) {
    _initLocalNotifications();

    _dripSub = _bleService.dripCountStream.listen((count) {
      _telemetry = _telemetry.copyWith(dripCount: count, lastUpdated: DateTime.now());
      notifyListeners();
    });

    _dpmSub = _bleService.dpmStream.listen((dpm) {
      _telemetry = _telemetry.copyWith(dpm: dpm, lastUpdated: DateTime.now());
      notifyListeners();
    });

    _flowSub = _bleService.flowStatusStream.listen((status) {
      _handleFlowStatusChange(status);
    });

    _wifiSub = _bleService.wifiStatusStream.listen((wifi) {
      _telemetry = _telemetry.copyWith(wifiStatus: wifi, lastUpdated: DateTime.now());
      notifyListeners();
    });

    _batterySub = _bleService.batteryStream.listen((bat) {
      _telemetry = _telemetry.copyWith(batteryLevel: bat, lastUpdated: DateTime.now());
      notifyListeners();
    });

    _rssiSub = _bleService.rssiStream.listen((rssi) {
      _telemetry = _telemetry.copyWith(rssi: rssi, lastUpdated: DateTime.now());
      notifyListeners();
    });
  }

  TelemetryModel get telemetry => _telemetry;
  bool get showFlowStoppedWarning => _showFlowStoppedWarning;
  bool get isInfusionSessionActive => _isInfusionSessionActive;

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
  }

  void _handleFlowStatusChange(String status) {
    _telemetry = _telemetry.copyWith(flowStatus: status, lastUpdated: DateTime.now());

    if (status == "FLOWING") {
      // Auto-clear warning if flow resumes
      _showFlowStoppedWarning = false;
      _hasAlreadyNotifiedStopped = false;

      // Start 60-second stabilization timer if not already active
      _sessionTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_telemetry.flowStatus == "FLOWING") {
          _flowingDurationSeconds++;
          if (_flowingDurationSeconds >= 60) {
            _isInfusionSessionActive = true;
          }
        } else {
          _flowingDurationSeconds = 0;
          timer.cancel();
          _sessionTimer = null;
        }
      });
    } else if (status == "STOPPED") {
      _flowingDurationSeconds = 0;
      _sessionTimer?.cancel();
      _sessionTimer = null;

      // Trigger alarm ONLY if monitoring session was active
      if (_isInfusionSessionActive && !_hasAlreadyNotifiedStopped) {
        _triggerFlowStoppedAlarm();
      }
    }

    notifyListeners();
  }

  Future<void> _triggerFlowStoppedAlarm() async {
    _showFlowStoppedWarning = true;
    _hasAlreadyNotifiedStopped = true;

    // Vibrate phone
    HapticFeedback.heavyImpact();
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
    }

    // Trigger local notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'iv_flow_alarm_channel',
      'IV Flow Alarm Notifications',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFE53935),
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      101,
      'IV Flow Stopped',
      'No IV drops have been detected. Please check the patient\'s infusion immediately.',
      details,
    );

    notifyListeners();
  }

  Future<bool> resetCounter() async {
    bool success = await _bleService.sendResetCommand();
    if (success) {
      _telemetry = _telemetry.copyWith(
        dripCount: 0,
        dpm: 0.0,
        flowStatus: "READY",
        lastUpdated: DateTime.now(),
      );
      _isInfusionSessionActive = false;
      _flowingDurationSeconds = 0;
      _showFlowStoppedWarning = false;
      _hasAlreadyNotifiedStopped = false;
      notifyListeners();
    }
    return success;
  }

  @override
  void dispose() {
    _dripSub?.cancel();
    _dpmSub?.cancel();
    _flowSub?.cancel();
    _wifiSub?.cancel();
    _batterySub?.cancel();
    _rssiSub?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }
}
