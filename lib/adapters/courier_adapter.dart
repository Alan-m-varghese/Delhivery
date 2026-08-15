import '../models/shipment_status.dart';
import '../models/status_event.dart';

class ShipmentStatusResult {
  final ShipmentStatus status;
  final List<StatusEvent> timeline;
  final DateTime? estimatedDelivery;
  final String? rawResponse;
  final bool isSuccess;
  final String? errorMessage;

  ShipmentStatusResult({
    required this.status,
    required this.timeline,
    this.estimatedDelivery,
    this.rawResponse,
    this.isSuccess = true,
    this.errorMessage,
  });

  factory ShipmentStatusResult.failure(String message) {
    return ShipmentStatusResult(
      status: ShipmentStatus.unknown,
      timeline: [],
      isSuccess: false,
      errorMessage: message,
    );
  }
}

abstract class CourierAdapter {
  String get courierName;

  /// Fetches and parses current status from public tracking page / API endpoint
  Future<ShipmentStatusResult> fetchStatus(String trackingId);
}
