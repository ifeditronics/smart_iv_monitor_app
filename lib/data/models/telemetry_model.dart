enum SignalQuality { excellent, good, weak, unknown }

class TelemetryModel {
  final int dripCount;
  final double dpm;
  final String flowStatus; // "READY", "FLOWING", "STOPPED"
  final String wifiStatus; // "Connected", "Offline", etc.
  final String ipAddress;
  final int batteryLevel;
  final DateTime lastUpdated;
  final int rssi;

  TelemetryModel({
    required this.dripCount,
    required this.dpm,
    required this.flowStatus,
    required this.wifiStatus,
    required this.ipAddress,
    required this.batteryLevel,
    required this.lastUpdated,
    required this.rssi,
  });

  factory TelemetryModel.initial() {
    return TelemetryModel(
      dripCount: 0,
      dpm: 0.0,
      flowStatus: "READY",
      wifiStatus: "Offline",
      ipAddress: "0.0.0.0",
      batteryLevel: 100,
      lastUpdated: DateTime.now(),
      rssi: -60,
    );
  }

  TelemetryModel copyWith({
    int? dripCount,
    double? dpm,
    String? flowStatus,
    String? wifiStatus,
    String? ipAddress,
    int? batteryLevel,
    DateTime? lastUpdated,
    int? rssi,
  }) {
    return TelemetryModel(
      dripCount: dripCount ?? this.dripCount,
      dpm: dpm ?? this.dpm,
      flowStatus: flowStatus ?? this.flowStatus,
      wifiStatus: wifiStatus ?? this.wifiStatus,
      ipAddress: ipAddress ?? this.ipAddress,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rssi: rssi ?? this.rssi,
    );
  }

  SignalQuality get signalQuality {
    if (rssi == 0 || rssi == -1000) return SignalQuality.unknown;
    if (rssi >= -65) return SignalQuality.excellent;
    if (rssi >= -85) return SignalQuality.good;
    return SignalQuality.weak;
  }

  String get signalQualityStr {
    switch (signalQuality) {
      case SignalQuality.excellent:
        return "Excellent";
      case SignalQuality.good:
        return "Good";
      case SignalQuality.weak:
        return "Weak";
      case SignalQuality.unknown:
        return "N/A";
    }
  }
}
