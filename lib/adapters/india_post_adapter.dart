import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'courier_adapter.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';

class IndiaPostAdapter implements CourierAdapter {
  @override
  String get courierName => 'India Post';

  @override
  Future<ShipmentStatusResult> fetchStatus(String trackingId) async {
    // Strategy 1: India Post JSON API
    try {
      const apiUrl = 'https://track.indiapost.gov.in/TrackConsignment.aspx/SearchConsignment';
      final proxyUrl = kIsWeb
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(apiUrl)}'
          : apiUrl;

      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0',
        },
        body: jsonEncode({
          'ConsignmentNumber': trackingId,
          'CaptchaText': '',
          'CaptchaValue': '',
          'RequestID': '',
          'UserID': '',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        try {
          final json = jsonDecode(response.body);
          final data = json['d'] ?? json['data'] ?? json;
          if (data is String) {
            final inner = jsonDecode(data);
            final List events = inner['Events'] ?? inner['events'] ?? [];
            if (events.isNotEmpty) {
              final latestEvent = events.first;
              final statusStr = (latestEvent['EventType'] ?? latestEvent['Status'] ?? '').toString().toLowerCase();
              final status = _parseStatus(statusStr);
              final timeline = events.map<StatusEvent>((e) {
                return StatusEvent(
                  timestamp: DateTime.tryParse(e['EventDate'] ?? '') ?? DateTime.now(),
                  status: _parseStatus((e['EventType'] ?? '').toString().toLowerCase()),
                  location: e['Office'] ?? e['Location'] ?? 'India Post Office',
                  description: e['EventDescription'] ?? e['EventType'] ?? '',
                );
              }).toList();
              return ShipmentStatusResult(status: status, timeline: timeline);
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Strategy 2: Fallback — POST form to tracking page
    try {
      const pageUrl = 'https://www.indiapost.gov.in/_layouts/15/dop.portal.tracking/trackconsignment.aspx';
      final proxyUrl = kIsWeb
          ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(pageUrl)}'
          : pageUrl;

      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {'User-Agent': 'Mozilla/5.0'},
        body: {'txtArticleNo': trackingId},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body.toLowerCase();
        final status = _parseBodyText(body);
        return ShipmentStatusResult(
          status: status,
          timeline: [
            StatusEvent(
              timestamp: DateTime.now(),
              status: status,
              location: 'India Post Office',
              description: 'Status fetched from India Post tracking page.',
            )
          ],
        );
      }
    } catch (_) {}

    return ShipmentStatusResult.failure('Could not connect to India Post. Please try again.');
  }

  ShipmentStatus _parseStatus(String s) {
    if (s.contains('delivered') && !s.contains('not')) return ShipmentStatus.delivered;
    if (s.contains('out for delivery') || s.contains('out for dispatch')) return ShipmentStatus.outForDelivery;
    if (s.contains('dispatched') || s.contains('received') || s.contains('transit') || s.contains('booked')) return ShipmentStatus.shipped;
    if (s.contains('unsuccessful') || s.contains('returned') || s.contains('rto')) return ShipmentStatus.delayed;
    return ShipmentStatus.ordered;
  }

  ShipmentStatus _parseBodyText(String body) {
    if (body.contains('item delivered') || (body.contains('delivered') && !body.contains('not delivered'))) return ShipmentStatus.delivered;
    if (body.contains('out for delivery') || body.contains('out for dispatch')) return ShipmentStatus.outForDelivery;
    if (body.contains('item dispatched') || body.contains('item received') || body.contains('in transit')) return ShipmentStatus.shipped;
    if (body.contains('unsuccessful') || body.contains('returned')) return ShipmentStatus.delayed;
    return ShipmentStatus.ordered;
  }
}
