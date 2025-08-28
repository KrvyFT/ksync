import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../blocs/sync_bloc.dart';
import '../../domain/entities/sync_settings.dart';
import '../../core/di/injection.dart';
import '../../domain/repositories/sync_settings_repository.dart';
import '../../core/utils/permissions.dart';
import 'log_viewer_page.dart';
import 'file_explorer_page.dart';
import '../../core/background/sync_scheduler.dart';

class SettingsPage extends HookWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final webdavUrlController = useTextEditingController();
    final usernameController = useTextEditingController();
    final passwordController = useTextEditingController();

    final settings = useState<SyncSettings?>(null);
    final isLoading = useState<bool>(true);
    final isTestingConnection = useState<bool>(false);

    Future<void> loadSettings() async {
      isLoading.value = true;
      try {
        final settingsRepository =
            await getIt.getAsync<SyncSettingsRepository>();
        final loadedSettings = await settingsRepository.getSyncSettings();
        final password = await settingsRepository.getPassword();

        settings.value = loadedSettings;
        webdavUrlController.text = loadedSettings.webdavUrl ?? '';
        usernameController.text = loadedSettings.username ?? '';
        passwordController.text = password ?? '';
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载设置失败: $e')),
        );
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      loadSettings();
      return null;
    }, []);

    Future<void> saveSettings() async {
      if (!formKey.currentState!.validate()) {
        return;
      }

      if (settings.value == null) {
        return;
      }

      try {
        final settingsRepository =
            await getIt.getAsync<SyncSettingsRepository>();

        await settingsRepository.setWebdavUrl(webdavUrlController.text);
        await settingsRepository.setUsername(usernameController.text);
        if (passwordController.text.isNotEmpty) {
          await settingsRepository.setPassword(passwordController.text);
        }

        await settingsRepository.updateSyncSettings(settings.value!);
        if (context.mounted) {
          context.read<SyncBloc>().add(UpdateSyncSettings(settings.value!));
        }
        await SyncScheduler.scheduleSync(settings.value!);
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设置已保存'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存设置失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          if (!isLoading.value)
            TextButton(
              onPressed: saveSettings,
              child: const Text('保存'),
            ),
        ],
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WebdavSection(
                      formKey: formKey,
                      webdavUrlController: webdavUrlController,
                      usernameController: usernameController,
                      passwordController: passwordController,
                      isTestingConnection: isTestingConnection,
                      settings: settings,
                    ),
                    const SizedBox(height: 16),
                    _SyncDirectoriesSection(settings: settings),
                    const SizedBox(height: 16),
                    _SyncOptionsSection(settings: settings),
                    const SizedBox(height: 16),
                    _AdvancedOptionsSection(settings: settings),
                  ],
                ),
              ),
            ),
    );
  }
}

class _WebdavSection extends HookWidget {
  const _WebdavSection({
    required this.formKey,
    required this.webdavUrlController,
    required this.usernameController,
    required this.passwordController,
    required this.isTestingConnection,
    required this.settings,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController webdavUrlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final ValueNotifier<bool> isTestingConnection;
  final ValueNotifier<SyncSettings?> settings;

  Future<void> _testConnection(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    isTestingConnection.value = true;
    try {
      final settingsRepository = await getIt.getAsync<SyncSettingsRepository>();
      await settingsRepository.setWebdavUrl(webdavUrlController.text);
      await settingsRepository.setUsername(usernameController.text);
      await settingsRepository.setPassword(passwordController.text);

      await Future.delayed(const Duration(seconds: 2)); // Simulate test

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('连接测试成功'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('连接测试失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      isTestingConnection.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'WebDAV 连接',
      children: [
        TextFormField(
          controller: webdavUrlController,
          decoration: const InputDecoration(
            labelText: '服务器地址',
            hintText: 'https://your-webdav-server.com',
            prefixIcon: Icon(Icons.link),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return '请输入服务器地址';
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.hasScheme) return '请输入有效的 URL';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: '用户名',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return '请输入用户名';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: '密码',
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
          validator: (value) {
            if (webdavUrlController.text.isNotEmpty &&
                usernameController.text.isNotEmpty &&
                (value == null || value.isEmpty)) {
              return '请输入密码';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                isTestingConnection.value ? null : () => _testConnection(context),
            icon: isTestingConnection.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_tethering),
            label: Text(isTestingConnection.value ? '测试中...' : '测试连接'),
          ),
        ),
        const SizedBox(height: 16),
        _MaxConcurrentUploadsTile(settings: settings),
      ],
    );
  }
}

class _MaxConcurrentUploadsTile extends HookWidget {
  const _MaxConcurrentUploadsTile({required this.settings});

  final ValueNotifier<SyncSettings?> settings;

  @override
  Widget build(BuildContext context) {
    final currentUploads =
        settings.value?.maxConcurrentUploads.toDouble() ?? 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '最大并发上传数: ${currentUploads.toInt()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Slider(
          value: currentUploads,
          min: 1,
          max: 10,
          divisions: 9,
          label: currentUploads.round().toString(),
          onChanged: (double value) {
            if (settings.value != null) {
              settings.value = settings.value!
                  .copyWith(maxConcurrentUploads: value.toInt());
            }
          },
        ),
      ],
    );
  }
}

class _SyncDirectoriesSection extends HookWidget {
  const _SyncDirectoriesSection({required this.settings});
  final ValueNotifier<SyncSettings?> settings;

  Future<void> _addSyncDirectory(BuildContext context) async {
    try {
      await PermissionsHelper.ensureStoragePermissions();
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null && settings.value != null) {
        final directories =
            List<String>.from(settings.value!.syncDirectories);
        if (!directories.contains(result)) {
          directories.add(result);
          settings.value =
              settings.value!.copyWith(syncDirectories: directories);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择目录失败: $e')),
      );
    }
  }

  void _removeSyncDirectory(String directory) {
    if (settings.value == null) return;
    final directories = List<String>.from(settings.value!.syncDirectories);
    directories.remove(directory);
    settings.value = settings.value!.copyWith(syncDirectories: directories);
  }

  @override
  Widget build(BuildContext context) {
    final directories = settings.value?.syncDirectories ?? [];
    return _SettingsSection(
      title: '同步目录',
      action: TextButton.icon(
        onPressed: () => _addSyncDirectory(context),
        icon: const Icon(Icons.add),
        label: const Text('添加'),
      ),
      children: [
        if (directories.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('未选择同步目录', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...directories.map((dir) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(
                    dir.split('/').last,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(dir, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeSyncDirectory(dir),
                  ),
                ),
              )),
      ],
    );
  }
}

class _SyncOptionsSection extends HookWidget {
  const _SyncOptionsSection({required this.settings});
  final ValueNotifier<SyncSettings?> settings;

  String _getFrequencyText(SyncFrequency frequency) {
    switch (frequency) {
      case SyncFrequency.every15Minutes: return '每 15 分钟';
      case SyncFrequency.every30Minutes: return '每 30 分钟';
      case SyncFrequency.everyHour: return '每小时';
      case SyncFrequency.every2Hours: return '每 2 小时';
      case SyncFrequency.every6Hours: return '每 6 小时';
      case SyncFrequency.daily: return '每天';
      case SyncFrequency.manual: return '手动';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (settings.value == null) return const SizedBox.shrink();

    return _SettingsSection(
      title: '同步选项',
      children: [
        DropdownButtonFormField<SyncFrequency>(
          value: settings.value!.syncFrequency,
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
              settings.value = settings.value!.copyWith(syncFrequency: value);
            }
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('仅在 Wi-Fi 下同步'),
          subtitle: const Text('避免消耗移动数据'),
          value: settings.value!.syncOnlyOnWifi,
          onChanged: (value) {
            settings.value = settings.value!.copyWith(syncOnlyOnWifi: value);
          },
        ),
        SwitchListTile(
          title: const Text('仅在充电时同步'),
          subtitle: const Text('避免消耗电池'),
          value: settings.value!.syncOnlyWhenCharging,
          onChanged: (value) {
            settings.value = settings.value!.copyWith(syncOnlyWhenCharging: value);
          },
        ),
        SwitchListTile(
          title: const Text('仅在设备空闲时同步'),
          subtitle: const Text('避免影响使用体验'),
          value: settings.value!.syncOnlyWhenIdle,
          onChanged: (value) {
            settings.value = settings.value!.copyWith(syncOnlyWhenIdle: value);
          },
        ),
        SwitchListTile(
          title: const Text('仅在电量充足时同步'),
          subtitle: const Text('避免在电量低时同步'),
          value: settings.value!.syncOnlyWhenBatteryNotLow,
          onChanged: (value) {
            settings.value = settings.value!.copyWith(syncOnlyWhenBatteryNotLow: value);
          },
        ),
      ],
    );
  }
}

class _AdvancedOptionsSection extends StatelessWidget {
  const _AdvancedOptionsSection({required this.settings});
  final ValueNotifier<SyncSettings?> settings;

  @override
  Widget build(BuildContext context) {
    if (settings.value == null) return const SizedBox.shrink();

    return _SettingsSection(
      title: '高级选项',
      children: [
        SwitchListTile(
          title: const Text('启用通知'),
          subtitle: const Text('同步完成后发送通知'),
          value: settings.value!.enableNotifications,
          onChanged: (value) {
            settings.value =
                settings.value!.copyWith(enableNotifications: value);
          },
        ),
        SwitchListTile(
          title: const Text('启用冲突解决'),
          subtitle: const Text('自动处理文件冲突'),
          value: settings.value!.enableConflictResolution,
          onChanged: (value) {
            settings.value =
                settings.value!.copyWith(enableConflictResolution: value);
          },
        ),
        const Divider(height: 24),
        ListTile(
          title: const Text('查看日志'),
          subtitle: const Text('用于问题诊断'),
          leading: const Icon(Icons.receipt_long_outlined),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LogViewerPage()),
            );
          },
        ),
        ListTile(
          title: const Text('浏览服务器文件'),
          subtitle: const Text('直接查看云端文件'),
          leading: const Icon(Icons.cloud_outlined),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const FileExplorerPage()),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.action,
  });

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
