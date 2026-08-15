import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'courier_adapter.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';

class EcomExpressAdapter implements CourierAdapter {
  @override
  String get courierName => 'Ecom Express';

  @override
  Future<ShipmentStatusResult> fetchStatus(String trackingId) async {
    try {
      final targetUrl = 'https://ecomexpress.in/tracking/?awb_number=$trackingId';
      final requestUrl = kIsWeb
          ? Uri.parse('https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}')
          : Uri.parse(targetUrl);

      final response = await http.get(requestUrl, headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)',
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
              location: 'Ecom Express Facility',
              description: 'Latest tracking status updated from Ecom Express.',
            )
          ],
        );
      }
      return ShipmentStatusResult.failure('Ecom Express HTTP ${response.statusCode}');
    } catch (e) {
      return ShipmentStatusResult.failure('Ecom Express error: $e');
    }
  }
}
