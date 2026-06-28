import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/ble_provider.dart';
import '../../providers/telemetry_provider.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/custom_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/signal_indicator.dart';
import '../widgets/alarm_banner.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.electricOrange, size: 32),
            SizedBox(width: 12),
            Text(
              "Reset Drip Count?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "This will set the current drip count and flow rate back to zero.",
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricOrange,
              minimumSize: const Size(120, 48),
            ),
            onPressed: () async {
              print("[STAGE 1 CHECK] Nurse tapped YES, RESET button.");
              bool sent = await Provider.of<TelemetryProvider>(context, listen: false).resetCounter();
              print("[STAGE 1 RESULT] BleService.sendResetCommand result: $sent");
              if (context.mounted) Navigator.of(ctx).pop();
            },
            child: const Text("YES, RESET"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bleProv = Provider.of<BleProvider>(context);
    final telemProv = Provider.of<TelemetryProvider>(context);
    final telemetry = telemProv.telemetry;

    final String updatedTimeStr = DateFormat('HH:mm:ss').format(telemetry.lastUpdated);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SignalIndicator(
              quality: telemetry.signalQuality,
              label: telemetry.signalQualityStr,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Banner if not connected or reconnecting
            if (!bleProv.isConnected)
              CustomCard(
                backgroundColor: AppColors.electricOrange.withOpacity(0.1),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.electricOrange),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        bleProv.connectionStatusText,
                        style: const TextStyle(
                          color: AppColors.electricOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Flow Stopped Warning Card
            if (telemProv.showFlowStoppedWarning) const AlarmBanner(),

            // Top Header Card: Battery & Connection Status
            CustomCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bleProv.isConnected ? AppColors.lightGreen.withOpacity(0.15) : AppColors.textLight.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          bleProv.isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded,
                          color: bleProv.isConnected ? AppColors.lightGreen : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bleProv.isConnected ? "CONNECTED" : "OFFLINE",
                            style: TextStyle(
                              color: bleProv.isConnected ? AppColors.lightGreen : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "Smart IV Monitor",
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.battery_5_bar_rounded, color: AppColors.lightGreen, size: 28),
                      const SizedBox(width: 4),
                      Text(
                        "${telemetry.batteryLevel}%",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Giant Hero Drip Count Card
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "DRIP COUNT",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1),
                      ),
                      Icon(Icons.water_drop_rounded, color: AppColors.electricOrange.withOpacity(0.8), size: 28),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${telemetry.dripCount}",
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: AppColors.electricOrange,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Total Drops Registered",
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary.withOpacity(0.8)),
                  ),
                ],
              ),
            ),

            // Middle Row: Drops Per Minute & Flow Status
            Row(
              children: [
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "DROPS / MIN",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              telemetry.dpm.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.lightGreen),
                            ),
                            const SizedBox(width: 4),
                            const Text("DPM", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "FLOW STATUS",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 12),
                        StatusPill(status: telemetry.flowStatus),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Large Reset Counter Button
            ElevatedButton.icon(
              onPressed: bleProv.isConnected ? () => _showResetConfirmation(context) : null,
              icon: const Icon(Icons.refresh_rounded, size: 28),
              label: const Text("RESET COUNTER"),
            ),

            const SizedBox(height: 16),

            // Footer: Last Updated timestamp
            Center(
              child: Text(
                "Last Updated: $updatedTimeStr",
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
