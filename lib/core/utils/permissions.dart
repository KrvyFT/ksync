import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  static Future<bool> ensureStoragePermissions() async {
    // Android 13+ 使用 Photos/Media 细粒度权限，这里先请求管理外部存储/读写
    final statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.photos,
      Permission.mediaLibrary,
      Permission.notification,
    ].request();

    final ok = (statuses[Permission.storage]?.isGranted ?? true) &&
        (statuses[Permission.manageExternalStorage]?.isGranted ?? true);

    return ok;
  }
}
