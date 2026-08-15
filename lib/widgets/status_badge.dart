import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../models/shipment_status.dart';

class StatusBadge extends StatelessWidget {
  final ShipmentStatus status;

  const StatusBadge({super.key, required this.status});

  Color _getStatusColor() {
    switch (status) {
      case ShipmentStatus.ordered:
        return AppColors.statusOrdered;
      case ShipmentStatus.shipped:
        return AppColors.statusShipped;
      case ShipmentStatus.outForDelivery:
        return AppColors.statusOutForDelivery;
      case ShipmentStatus.delivered:
        return AppColors.accentPrimary;
      case ShipmentStatus.delayed:
        return AppColors.statusDelayed;
      case ShipmentStatus.unknown:
        return AppColors.statusUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final isDeliveredOrOut = status == ShipmentStatus.delivered || status == ShipmentStatus.outForDelivery;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDeliveredOrOut ? Colors.white.withOpacity(0.12) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDeliveredOrOut ? Colors.white.withOpacity(0.4) : AppColors.cardBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
