import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wifi_setup_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_card.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({Key? key}) : super(key: key);

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  final _ssidController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wifiProv = Provider.of<WifiSetupProvider>(context, listen: false);
      await wifiProv.loadCurrentSettings();
      _ssidController.text = wifiProv.ssid;
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Widget _buildStatusFeedbackCard(WifiActionState state) {
    if (state == WifiActionState.idle) return const SizedBox.shrink();

    Color bg;
    Color fg;
    IconData icon;
    String title;
    String message;

    switch (state) {
      case WifiActionState.connecting:
        bg = AppColors.electricOrange.withOpacity(0.1);
        fg = AppColors.electricOrange;
        icon = Icons.sync_rounded;
        title = "Connecting...";
        message = "Attempting connection using new credentials.";
        break;
      case WifiActionState.success:
        bg = AppColors.lightGreen.withOpacity(0.15);
        fg = AppColors.lightGreen;
        icon = Icons.check_circle_rounded;
        title = "Connected Successfully";
        message = "Device has joined the target network.";
        break;
      case WifiActionState.failed:
        bg = AppColors.statusStopped.withOpacity(0.15);
        fg = AppColors.statusStopped;
        icon = Icons.error_rounded;
        title = "Connection Failed";
        message = "Could not connect. Please check SSID and password.";
        break;
      default:
        return const SizedBox.shrink();
    }

    return CustomCard(
      backgroundColor: bg,
      child: Row(
        children: [
          Icon(icon, color: fg, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
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
    final wifiProv = Provider.of<WifiSetupProvider>(context);
    final telemetry = Provider.of<TelemetryProvider>(context).telemetry;

    return Scaffold(
      appBar: AppBar(
        title: const Text("WiFi Settings"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback status card
            _buildStatusFeedbackCard(wifiProv.actionState),

            // Current Status Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "CURRENT NETWORK STATUS",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: telemetry.wifiStatus == "Connected" ? AppColors.lightGreen.withOpacity(0.15) : AppColors.textLight.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_rounded,
                          color: telemetry.wifiStatus == "Connected" ? AppColors.lightGreen : AppColors.textSecondary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            telemetry.wifiStatus,
                            style: TextStyle(
                              color: telemetry.wifiStatus == "Connected" ? AppColors.lightGreen : AppColors.textSecondary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "IP: ${telemetry.ipAddress}",
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Update Credentials Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "UPDATE NETWORK CREDENTIALS",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ssidController,
                    onChanged: (val) => wifiProv.setSSID(val),
                    decoration: const InputDecoration(
                      labelText: "WiFi SSID",
                      prefixIcon: Icon(Icons.wifi_lock_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    obscureText: _obscurePassword,
                    onChanged: (val) => wifiProv.setPassword(val),
                    decoration: InputDecoration(
                      labelText: "WiFi Password",
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: wifiProv.actionState == WifiActionState.connecting
                  ? null
                  : () async {
                      await wifiProv.saveCredentials();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Credentials saved to device NVS.")),
                      );
                    },
              icon: const Icon(Icons.save_rounded),
              label: const Text("SAVE CREDENTIALS"),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: wifiProv.actionState == WifiActionState.connecting
                  ? null
                  : () => wifiProv.saveAndReconnect(),
              icon: const Icon(Icons.sync_rounded),
              label: const Text("RECONNECT WIFI"),
            ),
          ],
        ),
      ),
    );
  }
}
