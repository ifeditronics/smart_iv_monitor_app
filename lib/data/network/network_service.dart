import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

enum NetworkConnectionState {
  disconnected,
  connecting,
  connected,
}

class DiscoveredDevice {
  final String ssid;
  final String ipAddress;
  final int rssi;

  DiscoveredDevice({
    required this.ssid,
    required this.ipAddress,
    this.rssi = -45,
  });
}

class NetworkService {
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Timer? _reconnectTimer;
  String _currentIp = "192.168.1.100";

  NetworkConnectionState _currentState = NetworkConnectionState.disconnected;
  NetworkConnectionState get currentState => _currentState;
  bool get isResetReady => _currentState == NetworkConnectionState.connected;

  final _connectionStateController = StreamController<NetworkConnectionState>.broadcast();
  Stream<NetworkConnectionState> get connectionStateStream => _connectionStateController.stream;

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

  final _debugStatusController = StreamController<String>.broadcast();
  Stream<String> get debugStatusStream => _debugStatusController.stream;

  void _setConnectionState(NetworkConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  Future<bool> discoverAndConnect() async {
    _setConnectionState(NetworkConnectionState.connecting);
    List<String> candidateHosts = ["dripcounter.local", "192.168.1.100", "192.168.0.100", "192.168.4.1"];
    
    for (String host in candidateHosts) {
      try {
        final res = await http.get(Uri.parse('http://$host/api/status')).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          _currentIp = host;
          _parseTelemetryJson(res.body);
          _connectWebSocket();
          return true;
        }
      } catch (_) {}
    }
    
    _setConnectionState(NetworkConnectionState.disconnected);
    return false;
  }

  Future<bool> connectToDevice(String ipAddress) async {
    _currentIp = ipAddress.trim().isEmpty ? "dripcounter.local" : ipAddress.trim();
    _setConnectionState(NetworkConnectionState.connecting);

    try {
      final response = await http.get(Uri.parse('http://$_currentIp/api/status')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        _parseTelemetryJson(response.body);
        _connectWebSocket();
        return true;
      } else {
        _setConnectionState(NetworkConnectionState.disconnected);
        return false;
      }
    } catch (e) {
      print("[NetworkService] Connection failed: $e");
      _setConnectionState(NetworkConnectionState.disconnected);
      return false;
    }
  }

  void _connectWebSocket() {
    _wsSubscription?.cancel();
    _wsChannel?.sink.close(status.goingAway);

    final wsUri = Uri.parse('ws://$_currentIp:81');
    try {
      _wsChannel = WebSocketChannel.connect(wsUri);
      _setConnectionState(NetworkConnectionState.connected);
      _rssiController.add(-45);

      _wsSubscription = _wsChannel!.stream.listen(
        (data) {
          if (data is String) {
            _parseTelemetryJson(data);
          }
        },
        onError: (error) {
          _handleDisconnectAndScheduleReconnect();
        },
        onDone: () {
          _handleDisconnectAndScheduleReconnect();
        },
      );
    } catch (e) {
      _handleDisconnectAndScheduleReconnect();
    }
  }

  void _handleDisconnectAndScheduleReconnect() {
    _setConnectionState(NetworkConnectionState.disconnected);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connectToDevice(_currentIp);
    });
  }

  void _parseTelemetryJson(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      if (data is Map<String, dynamic>) {
        if (data.containsKey('dripCount')) {
          _dripCountController.add((data['dripCount'] as num).toInt());
        }
        if (data.containsKey('dropsPerMinute')) {
          _dpmController.add((data['dropsPerMinute'] as num).toDouble());
        } else if (data.containsKey('dpm')) {
          _dpmController.add((data['dpm'] as num).toDouble());
        }
        if (data.containsKey('flowStatus')) {
          _flowStatusController.add(data['flowStatus'].toString());
        }
        if (data.containsKey('batteryLevel')) {
          _batteryController.add((data['batteryLevel'] as num).toInt());
        }
        if (data.containsKey('deviceName')) {
          _wifiStatusController.add(data['deviceName'].toString());
        }
      }
    } catch (e) {
      print("[NetworkService] Error parsing telemetry JSON: $e");
    }
  }

  Future<bool> sendResetCommand() async {
    try {
      final response = await http.post(Uri.parse('http://$_currentIp/api/reset')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        return res['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final response = await http.get(Uri.parse('http://$_currentIp/api/device')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _wsSubscription?.cancel();
    await _wsChannel?.sink.close(status.goingAway);
    _setConnectionState(NetworkConnectionState.disconnected);
  }
}
