import 'package:flutter/material.dart';
import '../../data/models/telemetry_model.dart';
import '../../core/constants/app_colors.dart';

class SignalIndicator extends StatelessWidget {
  final SignalQuality quality;
  final String label;

  const SignalIndicator({
    Key? key,
    required this.quality,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (quality) {
      case SignalQuality.excellent:
        color = AppColors.lightGreen;
        icon = Icons.signal_cellular_alt_rounded;
        break;
      case SignalQuality.good:
        color = AppColors.electricOrange;
        icon = Icons.signal_cellular_alt_2_bar_rounded;
        break;
      case SignalQuality.weak:
        color = AppColors.statusStopped;
        icon = Icons.signal_cellular_alt_1_bar_rounded;
        break;
      case SignalQuality.unknown:
        color = AppColors.textLight;
        icon = Icons.signal_cellular_off_rounded;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
