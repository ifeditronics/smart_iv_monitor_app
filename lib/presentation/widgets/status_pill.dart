import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toUpperCase()) {
      case "FLOWING":
        bg = AppColors.electricOrange.withOpacity(0.15);
        fg = AppColors.electricOrange;
        icon = Icons.waves_rounded;
        break;
      case "STOPPED":
        bg = AppColors.statusStopped.withOpacity(0.15);
        fg = AppColors.statusStopped;
        icon = Icons.error_outline_rounded;
        break;
      case "READY":
      default:
        bg = AppColors.lightGreen.withOpacity(0.15);
        fg = AppColors.lightGreen;
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
