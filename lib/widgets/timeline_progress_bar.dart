import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/shipment_status.dart';

class TimelineProgressBar extends StatelessWidget {
  final ShipmentStatus currentStatus;

  const TimelineProgressBar({super.key, required this.currentStatus});

  static const List<String> steps = [
    'Ordered',
    'Shipped',
    'Out for Delivery',
    'Delivered',
  ];

  @override
  Widget build(BuildContext context) {
    int currentStep = currentStatus.stepOrder;
    bool isDelayed = currentStatus == ShipmentStatus.delayed;

    return Column(
      children: [
        Row(
          children: List.generate(steps.length, (index) {
            bool isCompleted = index <= currentStep;
            bool isCurrent = index == currentStep;
            Color nodeColor;

            if (isDelayed && isCurrent) {
              nodeColor = AppColors.statusDelayed;
            } else if (isCompleted) {
              nodeColor = AppColors.accentPrimary;
            } else {
              nodeColor = AppColors.cardBorder;
            }

            return Expanded(
              child: Row(
                children: [
                  // Node dot
                  Container(
                    width: isCurrent ? 14 : 10,
                    height: isCurrent ? 14 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: nodeColor,
                      boxShadow: isCurrent && !isDelayed
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                      border: Border.all(
                        color: isCompleted ? AppColors.accentPrimary : AppColors.cardBorder,
                        width: 2,
                      ),
                    ),
                    child: isCompleted && !isCurrent
                        ? const Icon(
                            Icons.check,
                            size: 6,
                            color: Colors.black,
                          )
                        : null,
                  ),
                  // Connecting Line
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2.5,
                        color: index < currentStep
                            ? AppColors.accentPrimary
                            : AppColors.cardBorder,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            bool isCurrent = index == currentStep;
            bool isCompleted = index <= currentStep;
            return SizedBox(
              width: 60,
              child: Text(
                steps[index],
                textAlign: index == 0
                    ? TextAlign.left
                    : (index == steps.length - 1 ? TextAlign.right : TextAlign.center),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? (isDelayed ? AppColors.statusDelayed : AppColors.accentPrimary)
                      : (isCompleted ? AppColors.textPrimary : AppColors.textMuted),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ),
      ],
    );
  }
}
