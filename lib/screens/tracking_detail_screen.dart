import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../adapters/adapter_factory.dart';
import '../core/theme/app_colors.dart';
import '../models/shipment.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';
import '../services/storage_service.dart';
import '../widgets/status_badge.dart';
import '../widgets/timeline_progress_bar.dart';

class TrackingDetailScreen extends StatefulWidget {
  final String shipmentId;

  const TrackingDetailScreen({super.key, required this.shipmentId});

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  Shipment? _shipment;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadShipment();
  }

  void _loadShipment() {
    final s = StorageService.getShipment(widget.shipmentId);
    setState(() {
      _shipment = s;
    });
  }

  Future<void> _refreshShipment() async {
    if (_shipment == null) return;

    setState(() {
      _isRefreshing = true;
    });

    final adapter = AdapterFactory.getAdapter(_shipment!.courier);
    final result = await adapter.fetchStatus(_shipment!.trackingId);

    final now = DateTime.now();

    if (result.isSuccess) {
      _shipment!.status = result.status;
      _shipment!.lastChecked = now;
      if (result.timeline.isNotEmpty) {
        _shipment!.timeline.addAll(result.timeline);
      }
      await StorageService.saveShipment(_shipment!);
    } else {
      _shipment!.lastChecked = now;
      await StorageService.saveShipment(_shipment!);
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      _loadShipment();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isSuccess ? 'Shipment status updated!' : 'Notice: ${result.errorMessage}',
          ),
          backgroundColor: AppColors.cardBg,
        ),
      );
    }
  }

  Future<void> _launchCourierSite() async {
    if (_shipment == null || _shipment!.trackingUrl.isEmpty) return;

    final uri = Uri.parse(_shipment!.trackingUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch courier URL')),
        );
      }
    }
  }

  void _showManualStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mark Status Manually',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Update shipment status for manual or unsupported links.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ...ShipmentStatus.values.map((st) {
                final isCurrent = _shipment?.status == st;
                return ListTile(
                  title: Text(
                    st.displayName,
                    style: TextStyle(
                      color: isCurrent ? AppColors.accentPrimary : AppColors.textPrimary,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: StatusBadge(status: st),
                  trailing: isCurrent
                      ? const Icon(Icons.check_circle, color: AppColors.accentPrimary)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (_shipment != null) {
                      _shipment!.status = st;
                      _shipment!.lastChecked = DateTime.now();
                      _shipment!.timeline.insert(
                        0,
                        StatusEvent(
                          timestamp: DateTime.now(),
                          status: st,
                          location: 'User Action',
                          description: 'Status manually updated to ${st.displayName}.',
                        ),
                      );
                      await StorageService.saveShipment(_shipment!);
                      _loadShipment();
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Shipment?'),
        content: const Text('Are you sure you want to delete this shipment from your local dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.statusDelayed)),
          ),
        ],
      ),
    );

    if (confirm == true && _shipment != null) {
      await StorageService.deleteShipment(_shipment!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shipment == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: Text('Shipment not found')),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shipment Details'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            onPressed: _isRefreshing ? null : _refreshShipment,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusDelayed),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Summary Flight Ticket Style Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          _shipment!.platform.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      StatusBadge(status: _shipment!.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _shipment!.itemName ?? 'Package ${_shipment!.trackingId}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        '${_shipment!.courier} • ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SelectableText(
                        _shipment!.trackingId,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TimelineProgressBar(currentStatus: _shipment!.status),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.cardBorder),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Delivery',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          Text(
                            _shipment!.estimatedDelivery != null
                                ? DateFormat('EEEE, MMM dd').format(_shipment!.estimatedDelivery!)
                                : 'Pending courier update',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Last Checked',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          Text(
                            DateFormat('hh:mm a').format(_shipment!.lastChecked),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons Row: Open Courier Site & Mark Status
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _launchCourierSite,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open Courier Site'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _showManualStatusPicker,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                  label: const Text('Mark Status', style: TextStyle(color: AppColors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Timeline Header
            const Text(
              'Tracking Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // Timeline Vertical List
            if (_shipment!.timeline.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text('No timeline events recorded yet.', style: TextStyle(color: AppColors.textMuted)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _shipment!.timeline.length,
                itemBuilder: (context, index) {
                  final event = _shipment!.timeline[index];
                  final isLatest = index == 0;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLatest ? AppColors.textPrimary : AppColors.cardBorder,
                              boxShadow: isLatest
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.4),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          if (index < _shipment!.timeline.length - 1)
                            Container(
                              width: 2,
                              height: 50,
                              color: AppColors.cardBorder,
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isLatest ? AppColors.textSecondary.withOpacity(0.4) : AppColors.cardBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      event.status.displayName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isLatest ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      dateFormat.format(event.timestamp),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                if (event.location != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    event.location!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                if (event.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    event.description!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
