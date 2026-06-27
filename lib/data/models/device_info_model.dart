class DeviceInfoModel {
  final String deviceName;
  final String firmwareVersion;
  final String chipModel;
  final String flashSize;
  final String macAddress;
  final String buildDate;
  final String otaStatus;

  DeviceInfoModel({
    required this.deviceName,
    required this.firmwareVersion,
    required this.chipModel,
    required this.flashSize,
    required this.macAddress,
    required this.buildDate,
    required this.otaStatus,
  });

  factory DeviceInfoModel.initial() {
    return DeviceInfoModel(
      deviceName: "Smart IV Monitor",
      firmwareVersion: "v1.0.0",
      chipModel: "ESP32-D0WDQ6",
      flashSize: "4 MB",
      macAddress: "AA:BB:CC:DD:EE:FF",
      buildDate: "Jun 27 2026",
      otaStatus: "Ready",
    );
  }

  factory DeviceInfoModel.parseRawString(String raw) {
    // Example: "Model: ESP32-D0WDQ6, Flash: 4MB, MAC: AA:BB:CC:DD:EE:FF, FW: v1.0.0, Build: Jun 27 2026"
    String model = "ESP32";
    String flash = "4 MB";
    String mac = "AA:BB:CC:DD:EE:FF";
    String fw = "v1.0.0";
    String build = "Jun 27 2026";

    try {
      List<String> parts = raw.split(',');
      for (var part in parts) {
        part = part.trim();
        if (part.startsWith("Model:")) model = part.replaceFirst("Model:", "").trim();
        if (part.startsWith("Flash:")) flash = part.replaceFirst("Flash:", "").trim();
        if (part.startsWith("MAC:")) mac = part.replaceFirst("MAC:", "").trim();
        if (part.startsWith("FW:")) fw = part.replaceFirst("FW:", "").trim();
        if (part.startsWith("Build:")) build = part.replaceFirst("Build:", "").trim();
      }
    } catch (_) {}

    return DeviceInfoModel(
      deviceName: "Smart IV Monitor",
      firmwareVersion: fw,
      chipModel: model,
      flashSize: flash,
      macAddress: mac,
      buildDate: build,
      otaStatus: "Ready",
    );
  }
}
