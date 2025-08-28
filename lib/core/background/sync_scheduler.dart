import 'package:workmanager/workmanager.dart';

import '../../domain/entities/sync_settings.dart';
import 'background_task_handler.dart';
import '../utils/logging.dart';

class SyncScheduler {
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging background tasks
    );
    logger.info("SyncScheduler initialized with Workmanager.");
  }

  static Future<void> scheduleSync(SyncSettings settings) async {
    if (settings.syncFrequency == SyncFrequency.manual) {
      await cancelScheduledSync();
      return;
    }

    final frequency = _getDurationForFrequency(settings.syncFrequency);
    
    // Using a periodic task. Workmanager handles constraints like network automatically.
    await Workmanager().registerPeriodicTask(
      "1", // A unique name for the task
      backgroundSyncTask,
      frequency: frequency,
      // Constraints can be added here, for example:
      // constraints: Constraints(
      //   networkType: NetworkType.unmetered, // e.g., only on Wi-Fi
      //   requiresCharging: true,
      // ),
    );
    logger.info("Scheduled periodic sync with frequency: $frequency");
  }

  static Future<void> cancelScheduledSync() async {
    await Workmanager().cancelByUniqueName("1");
    logger.info("Cancelled all scheduled sync tasks.");
  }

  static Duration _getDurationForFrequency(SyncFrequency frequency) {
    switch (frequency) {
      case SyncFrequency.every15Minutes:
        return const Duration(minutes: 15);
      case SyncFrequency.every30Minutes:
        return const Duration(minutes: 30);
      case SyncFrequency.everyHour:
        return const Duration(hours: 1);
      case SyncFrequency.every2Hours:
        return const Duration(hours: 2);
      case SyncFrequency.every6Hours:
        return const Duration(hours: 6);
      case SyncFrequency.daily:
        return const Duration(days: 1);
      default:
        // Default to a safe value (1 hour) if manual or other cases.
        return const Duration(hours: 1);
    }
  }
}
