import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../adapters/adapter_factory.dart';
import '../core/theme/app_colors.dart';
import '../models/shipment.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';
import '../services/link_parser.dart';
import '../services/storage_service.dart';

class AddTrackingScreen extends StatefulWidget {
  final String? initialText;

  const AddTrackingScreen({super.key, this.initialText});

  @override
  State<AddTrackingScreen> createState() => _AddTrackingScreenState();
}

class _AddTrackingScreenState extends State<AddTrackingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();
  final _itemNameController = TextEditingController();

  String _selectedCourier = 'Delhivery';
  String _selectedPlatform = 'Amazon';
  bool _isAutoTracked = true;
  bool _isLoading = false;

  final List<String> _couriers = [
    'Delhivery',
    'India Post',
    'DTDC',
    'Ecom Express',
    'Blue Dart',
    'Unknown / Other',
  ];

  final List<String> _platforms = [
    'Amazon',
    'Flipkart',
    'Myntra',
    'Ajio',
    'Purplle',
    'Meesho',
    'Nykaa',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _inputController.text = widget.initialText!;
      _onInputChanged(widget.initialText!);
    }
  }

  void _onInputChanged(String text) {
    if (text.trim().isEmpty) return;

    final parsed = LinkParser.parse(text);
    setState(() {
      if (parsed.courier != 'Unknown' && _couriers.contains(parsed.courier)) {
        _selectedCourier = parsed.courier;
      }
      if (parsed.platform != 'Other' && _platforms.contains(parsed.platform)) {
        _selectedPlatform = parsed.platform;
      }
      _isAutoTracked = parsed.isAutoTrackable;
    });
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      _inputController.text = clipboardData.text!;
      _onInputChanged(clipboardData.text!);
    }
  }

  Future<void> _submitAddTracking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final rawInput = _inputController.text.trim();
    final parsed = LinkParser.parse(rawInput);

    final trackingId = parsed.trackingId.isNotEmpty ? parsed.trackingId : rawInput;
    final trackingUrl = parsed.trackingUrl.isNotEmpty
        ? parsed.trackingUrl
        : LinkParser.getTrackingUrlForCourier(_selectedCourier, trackingId);

    final now = DateTime.now();

    // Default status & timeline
    ShipmentStatus currentStatus = ShipmentStatus.ordered;
    List<StatusEvent> timeline = [
      StatusEvent(
        timestamp: now,
        status: ShipmentStatus.ordered,
        location: 'Order Placed',
        description: 'Tracking registered in DELHIVERY.',
      ),
    ];

    // If auto-tracked, attempt instant initial fetch via CourierAdapter
    if (_isAutoTracked && _selectedCourier != 'Unknown / Other') {
      try {
        final adapter = AdapterFactory.getAdapter(_selectedCourier);
        final fetchResult = await adapter.fetchStatus(trackingId);
        if (fetchResult.isSuccess) {
          currentStatus = fetchResult.status;
          if (fetchResult.timeline.isNotEmpty) {
            timeline.addAll(fetchResult.timeline);
          }
        }
      } catch (e) {
        debugPrint('Initial scrape error: $e');
      }
    }

    final shipment = Shipment(
      id: const Uuid().v4(),
      platform: _selectedPlatform,
      courier: _selectedCourier,
      trackingId: trackingId,
      trackingUrl: trackingUrl,
      itemName: _itemNameController.text.trim().isNotEmpty
          ? _itemNameController.text.trim()
          : null,
      status: currentStatus,
      timeline: timeline,
      isAutoTracked: _isAutoTracked,
      lastChecked: now,
      estimatedDelivery: now.add(const Duration(days: 3)),
    );

    await StorageService.saveShipment(shipment);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _itemNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add New Tracking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card (Flight Booking Container style)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Paste Tracking ID or Link',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Auto-detects couriers like Delhivery, India Post, DTDC & more',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tracking Input Field with Paste Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tracking Link or AWB Number *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste, size: 14, color: AppColors.textPrimary),
                    label: const Text(
                      'Paste',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _inputController,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: _onInputChanged,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a tracking ID or tracking URL';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. 14392810482019 or https://delhivery.com/...',
                  prefixIcon: Icon(Icons.link_rounded, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),

              // Item Name Optional Field
              const Text(
                'Item / Package Name (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _itemNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. Wireless Earbuds, Shoes',
                  prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),

              // Courier & Platform Selection Dropdowns
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Courier Provider',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCourier,
                          dropdownColor: AppColors.cardBg,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _couriers
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCourier = val;
                                _isAutoTracked = LinkParser.supportedCouriers.contains(val);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Platform / Store',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedPlatform,
                          dropdownColor: AppColors.cardBg,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: _platforms
                              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPlatform = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Auto-track info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isAutoTracked ? Icons.autorenew_rounded : Icons.info_outline,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isAutoTracked
                            ? 'Auto-tracking supported for $_selectedCourier'
                            : 'Manual link mode (Amazon/Flipkart internal logistics)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button (Flight style solid primary button)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAddTracking,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text('TRACK SHIPMENT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
