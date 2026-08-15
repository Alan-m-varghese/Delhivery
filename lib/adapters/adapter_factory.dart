import 'courier_adapter.dart';
import 'delhivery_adapter.dart';
import 'india_post_adapter.dart';
import 'dtdc_adapter.dart';
import 'ecom_express_adapter.dart';
import 'blue_dart_adapter.dart';
import 'fallback_adapter.dart';

class AdapterFactory {
  static CourierAdapter getAdapter(String courierName) {
    switch (courierName.trim().toLowerCase()) {
      case 'delhivery':
        return DelhiveryAdapter();
      case 'india post':
        return IndiaPostAdapter();
      case 'dtdc':
        return DtdcAdapter();
      case 'ecom express':
        return EcomExpressAdapter();
      case 'blue dart':
      case 'bluedart':
        return BlueDartAdapter();
      default:
        return FallbackAdapter(courierName);
    }
  }
}
