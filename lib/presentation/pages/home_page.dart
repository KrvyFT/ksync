import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/sync_bloc.dart';
import '../widgets/sync_status_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/sync_progress_card.dart';
import 'settings_page.dart';
import 'sync_history_page.dart';
import '../../core/utils/permissions.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV 同步工具'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<SyncBloc>().add(const LoadSyncSettings());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 权限提醒
                  _PermissionsBanner(),
                  // 首次引导（未配置时提示去设置）
                  if (state is SyncSettingsLoaded &&
                      !(state as SyncSettingsLoaded).settings.isWebdavConfigured) ...[
                    _OnboardingBanner(),
                    const SizedBox(height: 16),
                  ],

                  // 同步状态卡片
                  SyncStatusCard(state: state),
                  
                  const SizedBox(height: 16),
                  
                  // 同步进度卡片（仅在同步进行时显示）
                  if (state is SyncInProgress) ...[
                    SyncProgressCard(progress: state.progress),
                    const SizedBox(height: 16),
                  ],
                  
                  // 快速操作
                  QuickActions(state: state),
                  
                  const SizedBox(height: 16),
                  
                  // 同步历史按钮
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('同步历史'),
                      subtitle: const Text('查看历史同步记录'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SyncHistoryPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 状态信息
                  if (state is SyncSuccess) ...[
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '同步成功',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '成功同步 ${state.syncLog.filesSynced} 个文件',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (state.syncLog.filesFailed > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '失败 ${state.syncLog.filesFailed} 个文件',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                            if (state.syncLog.duration != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '耗时: ${_formatDuration(state.syncLog.duration!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ] else if (state is SyncFailure) ...[
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.error,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '同步失败',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.error,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<SyncBloc, SyncState>(
        builder: (context, state) {
          if (state is SyncInProgress) {
            return FloatingActionButton(
              onPressed: () {
                context.read<SyncBloc>().add(const StopSync());
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            );
          } else {
            return FloatingActionButton(
              onPressed: () {
                context.read<SyncBloc>().add(const StartSync());
              },
              child: const Icon(Icons.sync),
            );
          }
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分${duration.inSeconds % 60}秒';
    } else {
      return '${duration.inSeconds}秒';
    }
  }
}

class _PermissionsBanner extends StatefulWidget {
  @override
  State<_PermissionsBanner> createState() => _PermissionsBannerState();
}

class _PermissionsBannerState extends State<_PermissionsBanner> {
  bool _granted = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await PermissionsHelper.ensureStoragePermissions();
    if (mounted) {
      setState(() => _granted = ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_granted) return const SizedBox.shrink();
    return Card(
      color: Colors.orange.shade50,
      child: ListTile(
        leading: Icon(Icons.privacy_tip, color: Colors.orange.shade700),
        title: const Text('需要存储权限以进行同步'),
        subtitle: const Text('请授予文件读写权限以访问所选目录'),
        trailing: TextButton(
          onPressed: _check,
          child: const Text('授予'),
        ),
      ),
    );
  }
}

class _OnboardingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: ListTile(
        leading: Icon(Icons.rocket_launch, color: Colors.blue.shade700),
        title: const Text('开始使用：先配置 WebDAV 和同步目录'),
        subtitle: const Text('点击前往设置，填入服务器地址与账号密码，并选择需要同步的目录'),
        trailing: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          child: const Text('去设置'),
        ),
      ),
    );
  }
}
