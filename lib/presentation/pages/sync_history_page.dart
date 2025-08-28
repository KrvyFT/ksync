import 'package:flutter/material.dart';

import '../../domain/entities/sync_log.dart';
import '../../core/di/injection.dart';
import '../../domain/repositories/sync_log_repository.dart';

class SyncHistoryPage extends StatefulWidget {
  const SyncHistoryPage({super.key});

  @override
  State<SyncHistoryPage> createState() => _SyncHistoryPageState();
}

class _SyncHistoryPageState extends State<SyncHistoryPage> {
  List<SyncLog> _syncLogs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSyncHistory();
  }

  Future<void> _loadSyncHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final syncLogRepository = await getIt.getAsync<SyncLogRepository>();
      final logs = await syncLogRepository.getRecentSyncLogs(50);

      setState(() {
        _syncLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('同步历史'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSyncHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _syncLogs.isEmpty
                  ? _buildEmptyWidget()
                  : _buildSyncLogsList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSyncHistory,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无同步记录',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '开始同步后，这里将显示同步历史',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncLogsList() {
    return RefreshIndicator(
      onRefresh: _loadSyncHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _syncLogs.length,
        itemBuilder: (context, index) {
          final syncLog = _syncLogs[index];
          return _buildSyncLogItem(syncLog);
        },
      ),
    );
  }

  Widget _buildSyncLogItem(SyncLog syncLog) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildStatusIcon(syncLog.status),
        title: Text(
          _getStatusText(syncLog.status),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getStatusColor(syncLog.status),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('开始时间: ${_formatDateTime(syncLog.startTime)}'),
            if (syncLog.endTime != null)
              Text('结束时间: ${_formatDateTime(syncLog.endTime!)}'),
            if (syncLog.duration != null)
              Text('耗时: ${_formatDuration(syncLog.duration!)}'),
            Text('文件: ${syncLog.filesSynced} 成功, ${syncLog.filesFailed} 失败'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showSyncLogDetails(syncLog),
        ),
        onTap: () => _showSyncLogDetails(syncLog),
      ),
    );
  }

  Widget _buildStatusIcon(SyncStatus status) {
    IconData iconData;
    Color color;

    switch (status) {
      case SyncStatus.success:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case SyncStatus.failed:
        iconData = Icons.error;
        color = Colors.red;
        break;
      case SyncStatus.canceled:
        iconData = Icons.cancel;
        color = Colors.orange;
        break;
      case SyncStatus.inProgress:
        iconData = Icons.sync;
        color = Colors.blue;
        break;
    }

    return Icon(iconData, color: color, size: 32);
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return '同步成功';
      case SyncStatus.failed:
        return '同步失败';
      case SyncStatus.canceled:
        return '同步取消';
      case SyncStatus.inProgress:
        return '同步进行中';
    }
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.canceled:
        return Colors.orange;
      case SyncStatus.inProgress:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分${duration.inSeconds % 60}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  void _showSyncLogDetails(SyncLog syncLog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('同步详情 - ${_getStatusText(syncLog.status)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('任务ID', syncLog.jobId),
              _buildDetailRow('开始时间', _formatDateTime(syncLog.startTime)),
              if (syncLog.endTime != null)
                _buildDetailRow('结束时间', _formatDateTime(syncLog.endTime!)),
              if (syncLog.duration != null)
                _buildDetailRow('耗时', _formatDuration(syncLog.duration!)),
              _buildDetailRow('成功文件', '${syncLog.filesSynced}'),
              _buildDetailRow('失败文件', '${syncLog.filesFailed}'),
              _buildDetailRow(
                  '成功率', '${(syncLog.successRate * 100).toStringAsFixed(1)}%'),
              if (syncLog.errorMessages.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '错误信息:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...syncLog.errorMessages.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )),
              ],
              if (syncLog.syncedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '成功文件:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...syncLog.syncedFiles.map((file) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $file',
                        style: const TextStyle(color: Colors.green),
                      ),
                    )),
              ],
              if (syncLog.failedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '失败文件:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...syncLog.failedFiles.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${entry.key}: ${entry.value}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
