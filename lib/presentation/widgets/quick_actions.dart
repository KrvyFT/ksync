import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/sync_bloc.dart';
import '../../domain/entities/sync_settings.dart';

class QuickActions extends StatelessWidget {
  final SyncState state;

  const QuickActions({
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
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.sync,
                    label: '立即同步',
                    onTap: () {
                      context.read<SyncBloc>().add(const StartSync());
                    },
                    enabled: _canStartSync(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.settings,
                    label: '设置',
                    onTap: () {
                      // 导航到设置页面
                      Navigator.pushNamed(context, '/settings');
                    },
                    enabled: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.history,
                    label: '同步历史',
                    onTap: () {
                      // 导航到同步历史页面
                      Navigator.pushNamed(context, '/history');
                    },
                    enabled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.info,
                    label: '状态信息',
                    onTap: () {
                      _showStatusInfo(context);
                    },
                    enabled: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _canStartSync() {
    if (state is SyncInProgress) {
      return false;
    }
    
    if (state is SyncSettingsLoaded) {
      final settings = (state as SyncSettingsLoaded).settings;
      return settings.isWebdavConfigured && settings.hasSyncDirectories;
    }
    
    return false;
  }

  void _showStatusInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('状态信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusInfoRow('当前状态', _getStatusText()),
            if (state is SyncSettingsLoaded) ...[
              const SizedBox(height: 8),
              _buildStatusInfoRow('WebDAV 配置', _getWebdavConfigText()),
              const SizedBox(height: 8),
              _buildStatusInfoRow('同步目录', _getDirectoriesText()),
              const SizedBox(height: 8),
              _buildStatusInfoRow('同步频率', _getFrequencyText()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfoRow(String label, String value) {
    return Row(
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
    );
  }

  String _getStatusText() {
    if (state is SyncInProgress) {
      return '正在同步';
    } else if (state is SyncSuccess) {
      return '同步完成';
    } else if (state is SyncFailure) {
      return '同步失败';
    } else if (state is SyncSettingsLoaded) {
      final settings = (state as SyncSettingsLoaded).settings;
      if (settings.canAutoSync) {
        return '已配置自动同步';
      } else if (settings.isWebdavConfigured) {
        return 'WebDAV 已配置';
      } else {
        return '未配置';
      }
    } else {
      return '未配置';
    }
  }

  String _getWebdavConfigText() {
    if (state is SyncSettingsLoaded) {
      final settings = (state as SyncSettingsLoaded).settings;
      if (settings.isWebdavConfigured) {
        return '已配置 (${settings.webdavUrl})';
      } else {
        return '未配置';
      }
    }
    return '未知';
  }

  String _getDirectoriesText() {
    if (state is SyncSettingsLoaded) {
      final settings = (state as SyncSettingsLoaded).settings;
      if (settings.hasSyncDirectories) {
        return '${settings.syncDirectories.length} 个目录';
      } else {
        return '未选择';
      }
    }
    return '未知';
  }

  String _getFrequencyText() {
    if (state is SyncSettingsLoaded) {
      final settings = (state as SyncSettingsLoaded).settings;
      switch (settings.syncFrequency) {
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
    return '未知';
  }
}
