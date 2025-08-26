/// WebDAV 文件信息
class WebdavFileInfo {
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime lastModified;

  const WebdavFileInfo({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.lastModified,
  });
}

/// 上传进度回调
typedef UploadProgressCallback = void Function(int bytesSent, int totalBytes);

/// 下载进度回调
typedef DownloadProgressCallback = void Function(
    int bytesReceived, int totalBytes);

/// WebDAV 仓库接口
abstract class WebdavRepository {
  /// 连接到 WebDAV 服务器
  Future<void> connect(String url, String username, String password);

  /// 断开连接
  Future<void> disconnect();

  /// 测试连接
  Future<bool> testConnection();

  /// 列出目录内容
  Future<List<WebdavFileInfo>> listDirectory(String path);

  /// 创建目录
  Future<void> createDirectory(String path);

  /// 递归创建目录
  Future<void> createDirectoryRecursive(String path);

  /// 上传文件
  Future<void> uploadFile(
    String localPath,
    String remotePath,
    UploadProgressCallback? onProgress,
  );

  /// 下载文件
  Future<void> downloadFile(
    String remotePath,
    String localPath,
    DownloadProgressCallback? onProgress,
  );

  /// 删除文件或目录
  Future<void> delete(String path);

  /// 检查文件或目录是否存在
  Future<bool> exists(String path);

  /// 获取文件信息
  Future<WebdavFileInfo?> getFileInfo(String path);

  /// 移动文件或目录
  Future<void> move(String sourcePath, String destinationPath);

  /// 复制文件或目录
  Future<void> copy(String sourcePath, String destinationPath);

  /// 获取文件大小
  Future<int> getFileSize(String path);

  /// 获取最后修改时间
  Future<DateTime> getLastModified(String path);

  /// 检查是否为目录
  Future<bool> isDirectory(String path);

  /// 检查是否为文件
  Future<bool> isFile(String path);
}
