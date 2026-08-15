import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'courier_adapter.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';

class BlueDartAdapter implements CourierAdapter {
  @override
  String get courierName => 'Blue Dart';

  @override
  Future<ShipmentStatusResult> fetchStatus(String trackingId) async {
    try {
      final targetUrl = 'https://www.bluedart.com/tracking?waybill=$trackingId';
      final requestUrl = kIsWeb
          ? Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}')
          : Uri.parse(targetUrl);

      final response = await http.get(requestUrl, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      }).timeout(const Duration(seconds: 15));

      ShipmentStatus status = ShipmentStatus.ordered;
      if (response.statusCode == 200) {
        final bodyText = response.body.toLowerCase();

        if (bodyText.contains('delivered')) {
          status = ShipmentStatus.delivered;
        } else if (bodyText.contains('out for delivery')) {
          status = ShipmentStatus.outForDelivery;
        } else if (bodyText.contains('in transit') || bodyText.contains('dispatched')) {
          status = ShipmentStatus.shipped;
        }

        return ShipmentStatusResult(
          status: status,
          timeline: [
            StatusEvent(
              timestamp: DateTime.now(),
              status: status,
              location: 'Blue Dart Hub',
              description: 'Latest tracking details updated from Blue Dart.',
            )
          ],
        );
      }
      return ShipmentStatusResult.failure('Blue Dart returned HTTP ${response.statusCode}');
    } catch (e) {
      return ShipmentStatusResult.failure('Blue Dart error: $e');
    }
  }
}
