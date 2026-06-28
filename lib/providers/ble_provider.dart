import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/network/network_service.dart';

class BleProvider with ChangeNotifier {
  final NetworkService _networkService = NetworkService();
  NetworkConnectionState _connectionState = NetworkConnectionState.disconnected;

  StreamSubscription? _stateSub;

  BleProvider() {
    _stateSub = _networkService.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  NetworkService get networkService => _networkService;
  NetworkConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == NetworkConnectionState.connected;

  String get connectionStatusText {
    switch (_connectionState) {
      case NetworkConnectionState.disconnected:
        return "Disconnected";
      case NetworkConnectionState.connecting:
        return "Connecting to Smart IV Monitor...";
      case NetworkConnectionState.connected:
        return "Connected to Monitor";
    }
  }

  Future<bool> autoDiscoverAndConnect() async {
    return await _networkService.discoverAndConnect();
  }

  Future<bool> connectToIp(String ip) async {
    return await _networkService.connectToDevice(ip);
  }

  void disconnect() => _networkService.disconnect();

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }
}
