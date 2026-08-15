import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'courier_adapter.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';

class DtdcAdapter implements CourierAdapter {
  @override
  String get courierName => 'DTDC';

  @override
  Future<ShipmentStatusResult> fetchStatus(String trackingId) async {
    // Strategy 1: DTDC JSON tracking API
    try {
      const apiUrl = 'https://tracking.dtdc.com/ctbs-tracking/customerInterface.tr?submitName=getResults&cnNo=';
      final fullUrl = '$apiUrl$trackingId&cType=Tracking';
      final proxyUrl = kIsWeb
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(fullUrl)}'
          : fullUrl;

      final response = await http.get(
        Uri.parse(proxyUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          'Accept': 'application/json, text/html',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // Try JSON parse
        try {
          final body = response.body.trim();
          if (body.startsWith('[') || body.startsWith('{')) {
            final json = jsonDecode(body);
            final List scans = json is List ? json : (json['trackingDetails'] ?? []);
            if (scans.isNotEmpty) {
              final latest = scans.last;
              final statusStr = (latest['statusVal'] ?? latest['status'] ?? '').toString().toLowerCase();
              final status = _parseStatus(statusStr);
              final timeline = scans.map<StatusEvent>((s) {
                return StatusEvent(
                  timestamp: DateTime.tryParse(s['date'] ?? s['scanDate'] ?? '') ?? DateTime.now(),
                  status: _parseStatus((s['statusVal'] ?? s['status'] ?? '').toString().toLowerCase()),
                  location: s['location'] ?? s['scanLocation'] ?? 'DTDC Hub',
                  description: s['statusVal'] ?? s['status'] ?? '',
                );
              }).toList();
              return ShipmentStatusResult(status: status, timeline: timeline);
            }
          }
        } catch (_) {}

        // Fallback: keyword scan of HTML
        final body = response.body.toLowerCase();
        final status = _parseBodyText(body);
        return ShipmentStatusResult(
          status: status,
          timeline: [
            StatusEvent(
              timestamp: DateTime.now(),
              status: status,
              location: 'DTDC Hub',
              description: 'Status fetched from DTDC tracking.',
            )
          ],
        );
      }
    } catch (_) {}

    return ShipmentStatusResult.failure('Could not connect to DTDC. Please try again.');
  }

  ShipmentStatus _parseStatus(String s) {
    if (s.contains('delivered') && !s.contains('undelivered')) return ShipmentStatus.delivered;
    if (s.contains('out for delivery')) return ShipmentStatus.outForDelivery;
    if (s.contains('transit') || s.contains('booked') || s.contains('dispatched')) return ShipmentStatus.shipped;
    if (s.contains('delayed') || s.contains('returned') || s.contains('rto')) return ShipmentStatus.delayed;
    return ShipmentStatus.ordered;
  }

  ShipmentStatus _parseBodyText(String body) {
    if (body.contains('delivered') && !body.contains('undelivered')) return ShipmentStatus.delivered;
    if (body.contains('out for delivery')) return ShipmentStatus.outForDelivery;
    if (body.contains('in transit') || body.contains('booked') || body.contains('dispatched')) return ShipmentStatus.shipped;
    if (body.contains('delayed') || body.contains('rto')) return ShipmentStatus.delayed;
    return ShipmentStatus.ordered;
  }
}
