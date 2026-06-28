import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../data/models/device_info_model.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_card.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  DeviceInfoModel _info = DeviceInfoModel.initial();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    setState(() => _isLoading = true);
    final bleProv = Provider.of<BleProvider>(context, listen: false);
    if (bleProv.isConnected) {
      final map = await bleProv.networkService.getDeviceInfo();
      if (map != null) {
        setState(() {
          _info = DeviceInfoModel(
            deviceName: "Smart IV Monitor",
            firmwareVersion: map['firmwareVersion'] ?? "v1.0.0",
            chipModel: map['chipModel'] ?? "ESP32",
            flashSize: "${map['flashMb'] ?? 4} MB",
            macAddress: map['mac'] ?? "00:00:00:00:00:00",
            buildDate: map['buildDate'] ?? "",
            otaStatus: "Ready",
          );
        });
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bleProv = Provider.of<BleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Status"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDeviceInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomCard(
              child: Column(
                children: [
                  const Icon(Icons.medical_services_rounded, size: 48, color: AppColors.electricOrange),
                  const SizedBox(height: 12),
                  Text(
                    _info.deviceName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "FW: ${_info.firmwareVersion}",
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.memory_rounded, color: AppColors.electricOrange),
                    title: const Text("Microcontroller"),
                    trailing: Text(_info.chipModel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.sd_card_rounded, color: AppColors.electricOrange),
                    title: const Text("Flash Memory"),
                    trailing: Text(_info.flashSize, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.fingerprint_rounded, color: AppColors.electricOrange),
                    title: const Text("MAC Address"),
                    trailing: Text(_info.macAddress, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_rounded, color: AppColors.electricOrange),
                    title: const Text("Build Date"),
                    trailing: Text(_info.buildDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
