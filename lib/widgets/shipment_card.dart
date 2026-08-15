import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/shipment.dart';
import 'status_badge.dart';
import 'timeline_progress_bar.dart';

class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback onTap;

  const ShipmentCard({
    super.key,
    required this.shipment,
    required this.onTap,
  });

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'amazon':
        return Icons.shopping_bag_outlined;
      case 'flipkart':
        return Icons.local_mall_outlined;
      case 'myntra':
        return Icons.checkroom_outlined;
      case 'ajio':
        return Icons.style_outlined;
      case 'purplle':
        return Icons.brush_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Platform Icon + Item Name/ID + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Icon(
                    _getPlatformIcon(shipment.platform),
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shipment.itemName ?? shipment.trackingId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            shipment.courier,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          Expanded(
                            child: Text(
                              shipment.trackingId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: shipment.status),
              ],
            ),
            const SizedBox(height: 18),
            // Middle: Horizontal Timeline Step Progress Bar
            TimelineProgressBar(currentStatus: shipment.status),
            const SizedBox(height: 16),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 12),
            // Bottom Row: ETA / Last Updated + Mode Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      shipment.estimatedDelivery != null
                          ? 'ETA: ${DateFormat('EEE, MMM dd').format(shipment.estimatedDelivery!)}'
                          : 'Updated: ${dateFormat.format(shipment.lastChecked)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: shipment.isAutoTracked
                        ? AppColors.surface
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: shipment.isAutoTracked
                          ? AppColors.cardBorder
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    shipment.isAutoTracked ? 'AUTO-TRACKED' : 'MANUAL LINK',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: shipment.isAutoTracked
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
