import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../data/ble/ble_service.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_card.dart';
import '../widgets/signal_indicator.dart';
import 'main_navigation_screen.dart';

class DeviceDiscoveryScreen extends StatelessWidget {
  const DeviceDiscoveryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bleProv = Provider.of<BleProvider>(context);
    final isSearching = bleProv.connectionState == BleConnectionState.searching;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Discovery"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.stop_rounded : Icons.refresh_rounded),
            onPressed: () {
              if (isSearching) {
                bleProv.stopScan();
              } else {
                bleProv.startScan();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner if Bluetooth is Disabled
            if (bleProv.connectionState == BleConnectionState.bluetoothOff)
              CustomCard(
                backgroundColor: AppColors.statusStopped.withOpacity(0.1),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.bluetooth_disabled_rounded, color: AppColors.statusStopped, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Bluetooth is Disabled",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.statusStopped),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusStopped),
                      onPressed: () => bleProv.startScan(),
                      child: const Text("ENABLE BLUETOOTH"),
                    ),
                  ],
                ),
              ),

            // Searching Status Card
            CustomCard(
              backgroundColor: AppColors.electricOrange.withOpacity(0.08),
              child: Row(
                children: [
                  if (isSearching)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.electricOrange),
                    )
                  else
                    const Icon(Icons.radar_rounded, color: AppColors.electricOrange, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSearching ? "Searching for nearby Smart IV Monitors..." : "Scan Complete",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.electricOrange),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${bleProv.discoveredDevices.length} device(s) found",
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "NEARBY SMART IV MONITORS",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),

            // Empty State
            if (bleProv.discoveredDevices.isEmpty)
              CustomCard(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.bluetooth_searching_rounded, size: 48, color: AppColors.textLight),
                      SizedBox(height: 16),
                      Text(
                        "No monitors detected yet.\nPlease ensure the Smart IV Monitor is powered on and within range.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),

            // Discovered Devices List
            ...bleProv.discoveredDevices.map((item) {
              return CustomCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.electricOrange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.medical_services_rounded, color: AppColors.electricOrange, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          SignalIndicator(
                            quality: item.signalQuality,
                            label: "Signal: ${item.signalQualityStr}",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () async {
                        bool success = await bleProv.connectToDevice(item);
                        if (success && context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Connection failed. Please try again.")),
                          );
                        }
                      },
                      child: const Text("CONNECT"),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
