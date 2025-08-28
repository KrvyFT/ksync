import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/sync_bloc.dart';
import '../pages/file_explorer_page.dart';

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
                    icon: Icons.folder_open,
                    label: '远程浏览',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FileExplorerPage()),
                      );
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

}
