import 'courier_adapter.dart';
import '../models/shipment_status.dart';
import '../models/status_event.dart';

class FallbackAdapter implements CourierAdapter {
  final String _courierName;

  FallbackAdapter([this._courierName = 'Manual / Unsupported']);

  @override
  String get courierName => _courierName;

  @override
  Future<ShipmentStatusResult> fetchStatus(String trackingId) async {
    // In fallback mode, tracking is managed manually by the user
    return ShipmentStatusResult(
      status: ShipmentStatus.ordered,
      timeline: [
        StatusEvent(
          timestamp: DateTime.now(),
          status: ShipmentStatus.ordered,
          location: 'Manual Entry',
          description: 'Shipment added via manual fallback mode.',
        ),
      ],
      isSuccess: true,
    );
  }
}
