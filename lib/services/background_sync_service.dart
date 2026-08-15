import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

import '../adapters/adapter_factory.dart';
import '../models/notification_log.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// The task name registered with Workmanager for background sync.
const String kBgSyncTaskName = 'delhivery_bg_sync';
const String kBgSyncUniqueName = 'delhivery_periodic_sync';

/// Called by Workmanager in a background isolate.
/// NOTE: This function must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Initialize services in isolate context
      await StorageService.init();
      await NotificationService.init();

      if (taskName == kBgSyncTaskName) {
        await _runShipmentStatusSync();
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('[BG] Background sync error: $e');
      return Future.value(false);
    }
  });
}

/// Core sync logic: loops all auto-tracked shipments, diffs status, fires notifications.
Future<void> _runShipmentStatusSync() async {
  final shipments = StorageService.getAllShipments();
  final now = DateTime.now();
  int notifId = 1000; // Start at a high ID so it doesn't conflict with foreground notifs

  for (final shipment in shipments) {
    if (!shipment.isAutoTracked) continue;

    try {
      final adapter = AdapterFactory.getAdapter(shipment.courier);
      final result = await adapter.fetchStatus(shipment.trackingId);

      if (result.isSuccess && result.status != shipment.status) {
        final oldStatus = shipment.status;

        // Mutate and persist
        shipment.status = result.status;
        shipment.lastChecked = now;
        if (result.timeline.isNotEmpty) {
          shipment.timeline.addAll(result.timeline);
        }
        await StorageService.saveShipment(shipment);

        // Log the notification
        final title = '${shipment.itemName ?? shipment.trackingId}: Status Updated';
        final body =
            '${oldStatus.displayName} → ${result.status.displayName} via ${shipment.courier}';

        final log = NotificationLog(
          id: const Uuid().v4(),
          shipmentId: shipment.id,
          title: title,
          body: body,
          timestamp: now,
          status: result.status,
        );
        await StorageService.addNotificationLog(log);

        // Fire local notification
        await NotificationService.showStatusChangeNotification(
          id: notifId++,
          title: title,
          body: body,
        );
      } else {
        shipment.lastChecked = now;
        await StorageService.saveShipment(shipment);
      }
    } catch (e) {
      debugPrint('[BG] Error fetching ${shipment.trackingId}: $e');
    }
  }
}

class BackgroundSyncService {
  /// Registers the periodic background task with Workmanager.
  static Future<void> registerPeriodicTask({
    Duration frequency = const Duration(hours: 3),
  }) async {
    if (kIsWeb) return; // Workmanager is mobile-only

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      await Workmanager().registerPeriodicTask(
        kBgSyncUniqueName,
        kBgSyncTaskName,
        frequency: frequency,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      debugPrint('[BG] Periodic sync registered: ${frequency.inMinutes} min interval');
    } catch (e) {
      debugPrint('[BG] Workmanager registration skipped or not supported on this target: $e');
    }
  }

  /// Cancels the periodic background task.
  static Future<void> cancelPeriodicTask() async {
    if (kIsWeb) return;

    try {
      await Workmanager().cancelByUniqueName(kBgSyncUniqueName);
      debugPrint('[BG] Periodic sync cancelled');
    } catch (e) {
      debugPrint('[BG] Workmanager cancel error: $e');
    }
  }

  /// Runs a one-off immediate background sync (for testing or manual trigger).
  static Future<void> runOnce() async {
    if (kIsWeb) return;

    try {
      await Workmanager().registerOneOffTask(
        '${kBgSyncUniqueName}_manual',
        kBgSyncTaskName,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (e) {
      debugPrint('[BG] Workmanager runOnce error: $e');
    }
  }
}
