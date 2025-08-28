import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  static Future<bool> ensureStoragePermissions() async {
    // Android 13+ 使用 Photos/Media 细粒度权限，这里先请求管理外部存储/读写
    final statuses = await [
      Permission.manageExternalStorage,
      Permission.notification,
    ].request();

    // print("权限获取状态： $statuses");

    final ok = (statuses[Permission.storage]?.isGranted ?? true) &&
        (statuses[Permission.manageExternalStorage]?.isGranted ?? true);

    return ok;
  }
}
