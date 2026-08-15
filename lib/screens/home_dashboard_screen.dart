import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../adapters/adapter_factory.dart';
import '../core/theme/app_colors.dart';
import '../models/notification_log.dart';
import '../models/shipment.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';
import '../services/link_parser.dart';
import '../services/storage_service.dart';
import '../widgets/clipboard_banner.dart';
import '../widgets/shipment_card.dart';
import 'add_tracking_screen.dart';
import 'tracking_detail_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  String _selectedFilter = 'All'; // All, In Transit, Delivered, Delayed
  String? _detectedClipboardTrackingId;
  bool _clipboardBannerDismissed = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _checkClipboardForTrackingId();
    _seedInitialDummyDataIfNeeded();
  }

  Future<void> _seedInitialDummyDataIfNeeded() async {
    final existing = StorageService.getAllShipments();
    if (existing.isEmpty) {
      final now = DateTime.now();
      final dummyShipments = [
        Shipment(
          id: const Uuid().v4(),
          platform: 'Amazon',
          courier: 'Delhivery',
          trackingId: '14392810482019',
          trackingUrl: 'https://www.delhivery.com/track/package/14392810482019',
          itemName: 'Sony WH-1000XM5 Headphones',
          status: ShipmentStatus.outForDelivery,
          timeline: [
            StatusEvent(
              timestamp: now.subtract(const Duration(days: 2)),
              status: ShipmentStatus.ordered,
              location: 'Bengaluru Fulfillment Center',
              description: 'Order placed & packed.',
            ),
            StatusEvent(
              timestamp: now.subtract(const Duration(days: 1)),
              status: ShipmentStatus.shipped,
              location: 'Bengaluru Sort Hub',
              description: 'Dispatched to destination hub.',
            ),
            StatusEvent(
              timestamp: now.subtract(const Duration(hours: 3)),
              status: ShipmentStatus.outForDelivery,
              location: 'Mumbai Delivery Facility',
              description: 'Out for delivery with delivery executive.',
            ),
          ],
          isAutoTracked: true,
          lastChecked: now,
          estimatedDelivery: now.add(const Duration(hours: 4)),
        ),
        Shipment(
          id: const Uuid().v4(),
          platform: 'Flipkart',
          courier: 'India Post',
          trackingId: 'EM987654321IN',
          trackingUrl: 'https://www.indiapost.gov.in/_layouts/15/dop.portal.tracking/trackconsignment.aspx',
          itemName: 'Mechanical Keyboard (RGB)',
          status: ShipmentStatus.shipped,
          timeline: [
            StatusEvent(
              timestamp: now.subtract(const Duration(days: 3)),
              status: ShipmentStatus.ordered,
              location: 'New Delhi GPO',
              description: 'Item booked at Post Office.',
            ),
            StatusEvent(
              timestamp: now.subtract(const Duration(days: 1)),
              status: ShipmentStatus.shipped,
              location: 'National Sorting Hub Delhi',
              description: 'Item dispatched to destination post office.',
            ),
          ],
          isAutoTracked: true,
          lastChecked: now.subtract(const Duration(minutes: 35)),
          estimatedDelivery: now.add(const Duration(days: 2)),
        ),
        Shipment(
          id: const Uuid().v4(),
          platform: 'Myntra',
          courier: 'DTDC',
          trackingId: 'Z98214563',
          trackingUrl: 'https://www.dtdc.in/tracking/shipment-tracking.asp?strTrkNo=Z98214563',
          itemName: 'Nike Air Max Sneakers',
          status: ShipmentStatus.delivered,
          timeline: [
            StatusEvent(
              timestamp: now.subtract(const Duration(days: 4)),
              status: ShipmentStatus.ordered,
              location: 'Gurugram Hub',
              description: 'Manifested by seller.',
            ),
            StatusEvent(
              timestamp: now.subtract(const Duration(days: 2)),
              status: ShipmentStatus.shipped,
              location: 'Transit Center',
              description: 'In transit to local facility.',
            ),
            StatusEvent(
              timestamp: now.subtract(const Duration(days: 1)),
              status: ShipmentStatus.delivered,
              location: 'Customer Address',
              description: 'Delivered successfully.',
            ),
          ],
          isAutoTracked: true,
          lastChecked: now.subtract(const Duration(days: 1)),
          estimatedDelivery: now.subtract(const Duration(days: 1)),
        ),
      ];

      for (var s in dummyShipments) {
        await StorageService.saveShipment(s);
      }
    }
  }

  Future<void> _checkClipboardForTrackingId() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        final text = clipboardData.text!.trim();
        final parsed = LinkParser.parse(text);
        if (parsed.trackingId.isNotEmpty && parsed.trackingId.length >= 6) {
          // Check if already in DB
          final shipments = StorageService.getAllShipments();
          final exists = shipments.any((s) => s.trackingId == parsed.trackingId);
          if (!exists && mounted) {
            setState(() {
              _detectedClipboardTrackingId = parsed.trackingId;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshAllShipments() async {
    setState(() {
      _isRefreshing = true;
    });

    final shipments = StorageService.getAllShipments();
    final now = DateTime.now();

    for (var shipment in shipments) {
      if (shipment.isAutoTracked) {
        final adapter = AdapterFactory.getAdapter(shipment.courier);
        final result = await adapter.fetchStatus(shipment.trackingId);

        if (result.isSuccess && result.status != shipment.status) {
          final oldStatus = shipment.status;
          shipment.status = result.status;
          shipment.lastChecked = now;

          if (result.timeline.isNotEmpty) {
            shipment.timeline.addAll(result.timeline);
          }

          await StorageService.saveShipment(shipment);

          // Log notification
          final log = NotificationLog(
            id: const Uuid().v4(),
            shipmentId: shipment.id,
            title: '${shipment.itemName ?? shipment.trackingId} Status Updated',
            body: 'Status changed from ${oldStatus.displayName} to ${result.status.displayName} (${shipment.courier})',
            timestamp: now,
            status: result.status,
          );
          await StorageService.addNotificationLog(log);
        } else {
          shipment.lastChecked = now;
          await StorageService.saveShipment(shipment);
        }
      }
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipment statuses updated!'),
          backgroundColor: AppColors.cardBg,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<Shipment> _filterShipments(List<Shipment> shipments) {
    switch (_selectedFilter) {
      case 'In Transit':
        return shipments
            .where((s) =>
                s.status == ShipmentStatus.shipped ||
                s.status == ShipmentStatus.outForDelivery ||
                s.status == ShipmentStatus.ordered)
            .toList();
      case 'Delivered':
        return shipments.where((s) => s.status == ShipmentStatus.delivered).toList();
      case 'Delayed':
        return shipments.where((s) => s.status == ShipmentStatus.delayed).toList();
      default:
        return shipments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'DELHIVERY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
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
            onPressed: _isRefreshing ? null : _refreshAllShipments,
            tooltip: 'Refresh Statuses',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTrackingScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Add Shipment',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAllShipments,
        color: AppColors.textPrimary,
        backgroundColor: AppColors.cardBg,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Clipboard auto-prompt banner
            if (_detectedClipboardTrackingId != null && !_clipboardBannerDismissed)
              SliverToBoxAdapter(
                child: ClipboardBanner(
                  trackingId: _detectedClipboardTrackingId!,
                  onAddPressed: () {
                    final tid = _detectedClipboardTrackingId;
                    setState(() {
                      _clipboardBannerDismissed = true;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTrackingScreen(initialText: tid),
                      ),
                    );
                  },
                  onDismissPressed: () {
                    setState(() {
                      _clipboardBannerDismissed = true;
                    });
                  },
                ),
              ),

            // Filter Chips Bar (Reference flight UI pill buttons)
            SliverToBoxAdapter(
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', 'In Transit', 'Delivered', 'Delayed'].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.black : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.accentPrimary,
                        backgroundColor: AppColors.cardBg,
                        side: BorderSide(
                          color: isSelected ? AppColors.accentPrimary : AppColors.cardBorder,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Shipment List Header Count
            ValueListenableBuilder<Box<Shipment>>(
              valueListenable: StorageService.getShipmentsListenable(),
              builder: (context, box, child) {
                final allShipments = box.values.toList();
                final filtered = _filterShipments(allShipments);

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.textMuted.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == 'All'
                                ? 'No Shipments Tracked Yet'
                                : 'No $_selectedFilter Shipments',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap "+ Add Shipment" to track any package',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final shipment = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: ShipmentCard(
                            shipment: shipment,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TrackingDetailScreen(shipmentId: shipment.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}
