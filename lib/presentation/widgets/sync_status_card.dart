import 'package:flutter/material.dart';

import '../blocs/sync_bloc.dart';
import '../../domain/entities/sync_settings.dart';

class SyncStatusCard extends StatelessWidget {
  final SyncState state;

  const SyncStatusCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(context),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        _getStatusSubtitle(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConfigurationInfo(context),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    final s = state;
    if (s is SyncInProgress) {
      return Icons.sync;
    } else if (s is SyncSuccess) {
      if (s.syncLog.filesFailed > 0) {
        return Icons.warning_amber_rounded;
      }
      if (s.syncLog.filesSynced == 0 && s.syncLog.filesFailed == 0) {
        return Icons.cloud_done;
      }
      return Icons.check_circle;
    } else if (s is SyncFailure) {
      return Icons.error;
    } else if (s is SyncSettingsLoaded) {
      if (s.settings.canAutoSync) {
        return Icons.cloud_done;
      } else {
        return Icons.cloud_off;
      }
    } else {
      return Icons.cloud_off;
    }
  }

  Color _getStatusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = state;
    if (s is SyncInProgress) {
      return colorScheme.secondary;
    } else if (s is SyncSuccess) {
      if (s.syncLog.filesFailed > 0) {
        return colorScheme.tertiary;
      }
      return colorScheme.primary;
    } else if (s is SyncFailure) {
      return colorScheme.error;
    } else if (s is SyncSettingsLoaded) {
      if (s.settings.canAutoSync) {
        return colorScheme.primary;
      } else if (s.settings.isWebdavConfigured) {
        return colorScheme.tertiary;
      } else {
        return colorScheme.onSurface.withOpacity(0.4);
      }
    } else {
      return colorScheme.onSurface.withOpacity(0.4);
    }
  }

  String _getStatusTitle() {
    final s = state;
    if (s is SyncInProgress) {
      return '正在同步';
    } else if (s is SyncSuccess) {
      if (s.syncLog.filesFailed > 0) {
        return '部分同步完成';
      }
      if (s.syncLog.filesSynced == 0 && s.syncLog.filesFailed == 0) {
        return '文件已是最新';
      }
      return '同步完成';
    } else if (s is SyncFailure) {
      return '同步失败';
    } else if (s is SyncSettingsLoaded) {
      if (s.settings.canAutoSync) {
        return '已配置自动同步';
      } else if (s.settings.isWebdavConfigured) {
        return 'WebDAV 已配置';
      } else {
        return '未配置';
      }
    } else {
      return '未配置';
    }
  }

  String _getStatusSubtitle() {
    final s = state;
    if (s is SyncInProgress) {
      return '正在同步文件到 WebDAV 服务器';
    } else if (s is SyncSuccess) {
      final log = s.syncLog;
      if (log.filesFailed > 0) {
        return '${log.filesSynced} 个文件成功, ${log.filesFailed} 个文件失败';
      }
      if (log.filesSynced == 0 && log.filesFailed == 0) {
        return '本地与云端文件一致';
      }
      return '成功同步 ${log.filesSynced} 个文件';
    } else if (s is SyncFailure) {
      return '同步过程中出现错误';
    } else if (s is SyncSettingsLoaded) {
      if (s.settings.canAutoSync) {
        return '将按照设定频率自动同步';
      } else if (s.settings.isWebdavConfigured) {
        return '请选择同步目录并设置同步频率';
      } else {
        return '请先配置 WebDAV 连接信息';
      }
    } else {
      return '请先配置 WebDAV 连接信息';
    }
  }

  Widget _buildConfigurationInfo(BuildContext context) {
    if (state is SyncSettingsLoaded) {
      final settings = (state as SyncSettingsLoaded).settings;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.isWebdavConfigured) ...[
            _buildInfoRow('服务器', settings.webdavUrl ?? ''),
            _buildInfoRow('用户名', settings.username ?? ''),
          ],
          if (settings.hasSyncDirectories) ...[
            _buildInfoRow('同步目录', '${settings.syncDirectories.length} 个目录'),
          ],
          if (settings.syncFrequency != SyncFrequency.manual) ...[
            _buildInfoRow('同步频率', _getFrequencyText(settings.syncFrequency)),
          ],
          if (settings.syncOnlyOnWifi) ...[
            _buildInfoRow('网络限制', '仅 Wi-Fi'),
          ],
          if (settings.syncOnlyWhenCharging) ...[
            _buildInfoRow('充电限制', '仅充电时'),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyText(SyncFrequency frequency) {
    switch (frequency) {
      case SyncFrequency.every15Minutes:
        return '每 15 分钟';
      case SyncFrequency.every30Minutes:
        return '每 30 分钟';
      case SyncFrequency.everyHour:
        return '每小时';
      case SyncFrequency.every2Hours:
        return '每 2 小时';
      case SyncFrequency.every6Hours:
        return '每 6 小时';
      case SyncFrequency.daily:
        return '每天';
      case SyncFrequency.manual:
        return '手动';
    }
  }
}
