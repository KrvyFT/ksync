import 'package:flutter/material.dart';

import '../../domain/usecases/sync_engine_usecase.dart';

class SyncProgressCard extends StatelessWidget {
  final SyncProgress progress;

  const SyncProgressCard({
    super.key,
    required this.progress,
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
                const Icon(Icons.sync, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '同步进度',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${progress.currentFileIndex + 1}/${progress.totalFiles}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 进度条
            if (progress.uploadingFiles.isNotEmpty)
              ..._buildUploadingFiles(context)
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('正在准备同步...'),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // 进度信息
            Row(
              children: [
                Expanded(
                  child: _buildProgressInfo(
                    '已同步',
                    '${progress.filesSynced}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProgressInfo(
                    '失败',
                    '${progress.filesFailed}',
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUploadingFiles(BuildContext context) {
    final widgets = <Widget>[];
    for (final entry in progress.uploadingFiles.entries) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '正在上传: ${_getFileName(entry.key)}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: entry.value,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }
    return widgets;
  }

  Widget _buildProgressInfo(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getFileName(String filePath) {
    final parts = filePath.split('/');
    return parts.isNotEmpty ? parts.last : filePath;
  }
}
