import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../blocs/sync_bloc.dart';
import '../../domain/entities/sync_settings.dart';
import '../../core/di/injection.dart';
import '../../domain/repositories/sync_settings_repository.dart';
import '../../core/utils/permissions.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _webdavUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  SyncSettings? _currentSettings;
  bool _isLoading = false;
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _webdavUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settingsRepository = await getIt.getAsync<SyncSettingsRepository>();
      final settings = await settingsRepository.getSyncSettings();
      
      setState(() {
        _currentSettings = settings;
        _webdavUrlController.text = settings.webdavUrl ?? '';
        _usernameController.text = settings.username ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载设置失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveSettings,
              child: const Text('保存'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWebdavSection(),
                    const SizedBox(height: 24),
                    _buildSyncDirectoriesSection(),
                    const SizedBox(height: 24),
                    _buildSyncOptionsSection(),
                    const SizedBox(height: 24),
                    _buildAdvancedOptionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWebdavSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WebDAV 连接',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _webdavUrlController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: 'https://your-webdav-server.com',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入服务器地址';
                }
                final uri = Uri.tryParse(value);
                if (uri == null || !uri.hasScheme) {
                  return '请输入有效的 URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入用户名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入密码';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTestingConnection ? null : _testConnection,
                icon: _isTestingConnection
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_isTestingConnection ? '测试中...' : '测试连接'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncDirectoriesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '同步目录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSyncDirectory,
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentSettings?.syncDirectories.isEmpty == true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '未选择同步目录',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...(_currentSettings?.syncDirectories.map((directory) => 
                _buildDirectoryItem(directory)) ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryItem(String directory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.folder),
        title: Text(directory),
        subtitle: Text('本地目录'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _removeSyncDirectory(directory),
        ),
      ),
    );
  }

  Widget _buildSyncOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '同步选项',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SyncFrequency>(
              value: _currentSettings?.syncFrequency ?? SyncFrequency.manual,
              decoration: const InputDecoration(
                labelText: '同步频率',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: SyncFrequency.values.map((frequency) {
                return DropdownMenuItem(
                  value: frequency,
                  child: Text(_getFrequencyText(frequency)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _currentSettings = _currentSettings?.copyWith(
                      syncFrequency: value,
                    );
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('仅在 Wi-Fi 下同步'),
              subtitle: const Text('避免消耗移动数据'),
              value: _currentSettings?.syncOnlyOnWifi ?? true,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings?.copyWith(
                    syncOnlyOnWifi: value,
                  );
                });
              },
            ),
            SwitchListTile(
              title: const Text('仅在充电时同步'),
              subtitle: const Text('避免消耗电池'),
              value: _currentSettings?.syncOnlyWhenCharging ?? false,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings?.copyWith(
                    syncOnlyWhenCharging: value,
                  );
                });
              },
            ),
            SwitchListTile(
              title: const Text('仅在设备空闲时同步'),
              subtitle: const Text('避免影响使用体验'),
              value: _currentSettings?.syncOnlyWhenIdle ?? false,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings?.copyWith(
                    syncOnlyWhenIdle: value,
                  );
                });
              },
            ),
            SwitchListTile(
              title: const Text('仅在电量充足时同步'),
              subtitle: const Text('避免在电量低时同步'),
              value: _currentSettings?.syncOnlyWhenBatteryNotLow ?? true,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings?.copyWith(
                    syncOnlyWhenBatteryNotLow: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '高级选项',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用通知'),
              subtitle: const Text('同步完成后发送通知'),
              value: _currentSettings?.enableNotifications ?? true,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings?.copyWith(
                    enableNotifications: value,
                  );
                });
              },
            ),
            SwitchListTile(
              title: const Text('启用冲突解决'),
              subtitle: const Text('自动处理文件冲突'),
              value: _currentSettings?.enableConflictResolution ?? true,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings?.copyWith(
                    enableConflictResolution: value,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTestingConnection = true;
    });

    try {
      final settingsRepository = await getIt.getAsync<SyncSettingsRepository>();
      await settingsRepository.setWebdavUrl(_webdavUrlController.text);
      await settingsRepository.setUsername(_usernameController.text);
      await settingsRepository.setPassword(_passwordController.text);

      // 这里应该调用 WebDAV 仓库的测试连接方法
      // 暂时模拟测试
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('连接测试成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('连接测试失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _addSyncDirectory() async {
    try {
      // 确保权限
      await PermissionsHelper.ensureStoragePermissions();
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        setState(() {
          final directories = List<String>.from(_currentSettings?.syncDirectories ?? []);
          if (!directories.contains(result)) {
            directories.add(result);
            _currentSettings = _currentSettings?.copyWith(
              syncDirectories: directories,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择目录失败: $e')),
      );
    }
  }

  void _removeSyncDirectory(String directory) {
    setState(() {
      final directories = List<String>.from(_currentSettings?.syncDirectories ?? []);
      directories.remove(directory);
      _currentSettings = _currentSettings?.copyWith(
        syncDirectories: directories,
      );
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentSettings == null) {
      return;
    }

    try {
      final settingsRepository = await getIt.getAsync<SyncSettingsRepository>();
      
      // 更新 WebDAV 连接信息
      await settingsRepository.setWebdavUrl(_webdavUrlController.text);
      await settingsRepository.setUsername(_usernameController.text);
      if (_passwordController.text.isNotEmpty) {
        await settingsRepository.setPassword(_passwordController.text);
      }

      // 更新其他设置
      await settingsRepository.updateSyncSettings(_currentSettings!);

      // 通知 BLoC 更新设置
      context.read<SyncBloc>().add(UpdateSyncSettings(_currentSettings!));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存设置失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
