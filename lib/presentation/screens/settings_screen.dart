import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ble_provider.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("IV Monitor Help"),
        content: const SingleChildScrollView(
          child: Text(
            "1. Auto Connection: The app scans and connects automatically to the Smart IV Monitor.\n\n"
            "2. Live Telemetry: Drip count and flow rates update in real time via Bluetooth notifications.\n\n"
            "3. Flow Stopped Alarm: An infusion monitoring session activates after 60 seconds of continuous flow. If flow stops, an urgent alarm sounds.\n\n"
            "4. Reset Counter: Press RESET COUNTER on the Dashboard to start a new infusion session.",
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CLOSE", style: TextStyle(color: AppColors.electricOrange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("About Smart IV Monitor"),
        content: const Text(
          "Smart IV Drip Monitor Application\n"
          "Version 1.0.0 (Build 1)\n\n"
          "Designed for hospital nurses to monitor fluid infusion rates safely and efficiently.",
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CLOSE", style: TextStyle(color: AppColors.electricOrange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bleProv = Provider.of<BleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  CustomCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.help_outline_rounded, color: AppColors.electricOrange),
                          title: const Text("Help & Usage Instructions", style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showHelpDialog(context),
                        ),
                        const Divider(color: AppColors.borderLight),
                        ListTile(
                          leading: const Icon(Icons.info_outline_rounded, color: AppColors.electricOrange),
                          title: const Text("About App", style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showAboutDialog(context),
                        ),
                        const Divider(color: AppColors.borderLight),
                        ListTile(
                          leading: const Icon(Icons.build_rounded, color: AppColors.textSecondary),
                          title: const Text("Application Version", style: TextStyle(fontWeight: FontWeight.w600)),
                          trailing: const Text("v1.0.0", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomCard(
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth_disabled_rounded, color: AppColors.statusStopped),
                      title: const Text("Disconnect Device", style: TextStyle(color: AppColors.statusStopped, fontWeight: FontWeight.bold)),
                      onTap: () {
                        bleProv.disconnect();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Disconnected from Smart IV Monitor.")),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Subtle, understated footer
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0, top: 8.0),
              child: Text(
                "Powered by Imaxeuno",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
