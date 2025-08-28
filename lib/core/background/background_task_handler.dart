import 'dart:async';

import 'package:workmanager/workmanager.dart';

import '../../domain/entities/sync_log.dart';
import '../../domain/usecases/sync_engine_usecase.dart';
import '../di/injection.dart';
import 'notification_service.dart';
import '../utils/logging.dart';

const backgroundSyncTask = "com.example.webdav_sync_tool.backgroundSync";

@pragma(
    'vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This is the real magic. The sync logic will be executed here.
    if (task == backgroundSyncTask) {
      logger.info("Background sync task started!");
      
      // We need to re-initialize dependencies here because this runs in a separate isolate.
      await configureDependencies();
      await getIt.allReady();

      final notificationService = NotificationService();
      await notificationService.initialize();

      try {
        final syncEngine = await getIt.getAsync<SyncEngineUseCase>();
        // Note: We don't need progress updates in the background, so onProgress is null.
        final result = await syncEngine.executeSync();
        
        logger.info("Background sync finished with status: ${result.status}");
        
        // Check for success or failure and send notification accordingly.
        if (result.status == SyncStatus.success || result.status == SyncStatus.failed) {
           await notificationService.showSyncSuccessNotification(result.filesSynced);
        } else if (result.status == SyncStatus.failed) {
            final errorMessage = result.errorMessages.isNotEmpty ? result.errorMessages.first : "Unknown error";
            await notificationService.showSyncErrorNotification(errorMessage);
        }
        
        return Future.value(true);
      } catch (e) {
        logger.error("Error during background sync", e);
        await notificationService.showSyncErrorNotification(e.toString());
        return Future.value(false);
      }
    }

    // Return true for successful task execution
    return Future.value(true);
  });
}
