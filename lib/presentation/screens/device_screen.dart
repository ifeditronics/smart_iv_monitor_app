import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../providers/telemetry_provider.dart';
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
      String raw = await bleProv.bleService.readDeviceInfo();
      if (raw.isNotEmpty) {
        setState(() {
          _info = DeviceInfoModel.parseRawString(raw);
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.electricOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.electricOrange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = Provider.of<TelemetryProvider>(context).telemetry;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Info"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomCard(
              child: Column(
                children: [
                  _buildInfoTile(Icons.medical_services_rounded, "Device Name", _info.deviceName),
                  const Divider(color: AppColors.borderLight),
                  _buildInfoTile(Icons.system_update_rounded, "Firmware Version", _info.firmwareVersion),
                  const Divider(color: AppColors.borderLight),
                  _buildInfoTile(Icons.memory_rounded, "Chip Model", _info.chipModel),
                  const Divider(color: AppColors.borderLight),
                  _buildInfoTile(Icons.sd_card_rounded, "Flash Size", _info.flashSize),
                  const Divider(color: AppColors.borderLight),
                  _buildInfoTile(Icons.qr_code_rounded, "MAC Address", _info.macAddress),
                ],
              ),
            ),
            CustomCard(
              child: Column(
                children: [
                  _buildInfoTile(Icons.wifi_rounded, "WiFi Status", telemetry.wifiStatus),
                  const Divider(color: AppColors.borderLight),
                  _buildInfoTile(Icons.lan_rounded, "IP Address", telemetry.ipAddress),
                  const Divider(color: AppColors.borderLight),
                  _buildInfoTile(Icons.cloud_upload_rounded, "OTA Status", _info.otaStatus),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _loadDeviceInfo,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              label: Text(_isLoading ? "REFRESHING..." : "REFRESH INFO"),
            ),
          ],
        ),
      ),
    );
  }
}
