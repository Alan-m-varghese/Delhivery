import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'courier_adapter.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';

class DelhiveryAdapter implements CourierAdapter {
  @override
  String get courierName => 'Delhivery';

  @override
  Future<ShipmentStatusResult> fetchStatus(String trackingId) async {
    // Strategy 1: Try Delhivery's public JSON tracking API
    try {
      final apiUrl =
          'https://api.delhivery.com/v3/packages/json/?waybill=$trackingId&token=';
      final proxyUrl = kIsWeb
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(apiUrl)}'
          : apiUrl;

      final response = await http
          .get(
            Uri.parse(proxyUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final json = jsonDecode(response.body);
          final shipmentData = json['ShipmentData'];
          if (shipmentData != null && shipmentData is List && shipmentData.isNotEmpty) {
            final shipment = shipmentData[0]['Shipment'];
            final statusStr = (shipment?['Status']?['Status'] ?? '').toString().toLowerCase();
            final location = shipment?['Status']?['StatusLocation'] ?? 'Delhivery Hub';
            final instructions = shipment?['Status']?['Instructions'] ?? '';

            ShipmentStatus status = _parseStatus(statusStr);
            final timeline = <StatusEvent>[];

            // Parse scans array for full timeline
            final scans = shipment?['Scans'] as List? ?? [];
            for (final scan in scans.reversed) {
              final sc = scan['ScanDetail'];
              if (sc == null) continue;
              final scanStatus = _parseStatus(
                  (sc['Scan'] ?? '').toString().toLowerCase());
              timeline.add(StatusEvent(
                timestamp: DateTime.tryParse(sc['ScanDateTime'] ?? '') ??
                    DateTime.now(),
                status: scanStatus,
                location: sc['ScannedLocation'] ?? '',
                description: sc['Instructions'] ?? '',
              ));
            }

            return ShipmentStatusResult(
              status: status,
              timeline: timeline.isNotEmpty
                  ? timeline
                  : [
                      StatusEvent(
                        timestamp: DateTime.now(),
                        status: status,
                        location: location.toString(),
                        description: instructions.toString(),
                      )
                    ],
            );
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Strategy 2: Fallback — scrape the tracking page HTML
    try {
      final pageUrl =
          'https://www.delhivery.com/track/package/$trackingId';
      final proxyUrl = kIsWeb
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(pageUrl)}'
          : pageUrl;

      final response = await http
          .get(Uri.parse(proxyUrl), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body.toLowerCase();
        final status = _parseBodyText(body);
        return ShipmentStatusResult(
          status: status,
          timeline: [
            StatusEvent(
              timestamp: DateTime.now(),
              status: status,
              location: 'Delhivery Logistics',
              description: 'Status fetched from Delhivery tracking page.',
            )
          ],
        );
      }
    } catch (_) {}

    return ShipmentStatusResult.failure(
        'Could not connect to Delhivery. Check your internet connection and try again.');
  }

  ShipmentStatus _parseStatus(String s) {
    if (s.contains('delivered') && !s.contains('undelivered')) return ShipmentStatus.delivered;
    if (s.contains('out for delivery') || s.contains('dispatched for delivery')) return ShipmentStatus.outForDelivery;
    if (s.contains('transit') || s.contains('in transit') || s.contains('received') || s.contains('arrived') || s.contains('manifested')) return ShipmentStatus.shipped;
    if (s.contains('delayed') || s.contains('undelivered') || s.contains('rto') || s.contains('returned')) return ShipmentStatus.delayed;
    return ShipmentStatus.ordered;
  }

  ShipmentStatus _parseBodyText(String body) {
    if (body.contains('delivered') && !body.contains('undelivered')) return ShipmentStatus.delivered;
    if (body.contains('out for delivery')) return ShipmentStatus.outForDelivery;
    if (body.contains('in transit') || body.contains('dispatched') || body.contains('reached at')) return ShipmentStatus.shipped;
    if (body.contains('delayed') || body.contains('undelivered') || body.contains('rto')) return ShipmentStatus.delayed;
    return ShipmentStatus.ordered;
  }
}
