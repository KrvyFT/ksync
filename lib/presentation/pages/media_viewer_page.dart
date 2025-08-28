import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../domain/repositories/webdav_repository.dart'; // To get WebdavFileInfo

// --- Main Page Widget ---
class MediaViewerPage extends StatefulWidget {
  final List<WebdavFileInfo> mediaFiles;
  final int initialIndex;
  final String webdavUrl;
  final String username;
  final String password;

  const MediaViewerPage({
    super.key,
    required this.mediaFiles,
    required this.initialIndex,
    required this.webdavUrl,
    required this.username,
    required this.password,
  });

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  late PageController _pageController;
  late ValueNotifier<int> _currentPageNotifier;
  bool _isUiVisible = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentPageNotifier = ValueNotifier<int>(widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    // Ensure the system UI is visible when we leave.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _toggleUiVisibility() {
    setState(() {
      _isUiVisible = !_isUiVisible;
      if (_isUiVisible) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaFiles.length,
              onPageChanged: (index) {
                _currentPageNotifier.value = index;
              },
              itemBuilder: (context, index) {
                final fileInfo = widget.mediaFiles[index];
                return MediaItemViewer(
                  key: ValueKey(fileInfo.path), // Important for state management
                  fileInfo: fileInfo,
                  webdavUrl: widget.webdavUrl,
                  username: widget.username,
                  password: widget.password,
                  isUiVisible: _isUiVisible,
                  onTap: _toggleUiVisibility,
                );
              },
            ),
            // --- UI Overlay ---
            _buildAnimatedUiOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedUiOverlay() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _isUiVisible
          ? Column(
              key: const ValueKey('ui-visible'),
              children: [
                AppBar(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  title: ValueListenableBuilder<int>(
                    valueListenable: _currentPageNotifier,
                    builder: (context, value, child) {
                      return Text(
                        widget.mediaFiles[value].name,
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  leading: const BackButton(color: Colors.white),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      onPressed: _toggleUiVisibility,
                      tooltip: 'Toggle Fullscreen',
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentPageNotifier,
                    builder: (context, value, child) {
                      return Text(
                        '${value + 1} / ${widget.mediaFiles.length}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      );
                    },
                  ),
                )
              ],
            )
          : const SizedBox.shrink(key: ValueKey('ui-hidden')),
    );
  }
}

// --- Individual Media Item Viewer ---
class MediaItemViewer extends StatefulWidget {
  final WebdavFileInfo fileInfo;
  final String webdavUrl;
  final String username;
  final String password;
  final bool isUiVisible;
  final VoidCallback onTap;

  const MediaItemViewer({
    super.key,
    required this.fileInfo,
    required this.webdavUrl,
    required this.username,
    required this.password,
    required this.isUiVisible,
    required this.onTap,
  });

  @override
  _MediaItemViewerState createState() => _MediaItemViewerState();
}

class _MediaItemViewerState extends State<MediaItemViewer>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  late final Map<String, String> _headers;
  late final String _fileUrl;

  @override
  bool get wantKeepAlive => true; // Keep state when swiping

  @override
  void initState() {
    super.initState();
    _createAuthHeaders();
    _fileUrl = Uri.encodeFull('${widget.webdavUrl}${widget.fileInfo.path}');

    if (_isVideo(widget.fileInfo.path)) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(_fileUrl),
        httpHeaders: _headers,
      );
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false, // Don't autoplay when swiping
        looping: false,
        placeholder: const Center(child: CircularProgressIndicator()),
        // Chewie has its own fullscreen logic
      );
    }
  }

  void _createAuthHeaders() {
    final credentials = '${widget.username}:${widget.password}';
    final encodedCredentials = base64.encode(utf8.encode(credentials));
    _headers = {'Authorization': 'Basic $encodedCredentials'};
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  bool _isImage(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  bool _isVideo(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv'].contains(extension);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed for AutomaticKeepAliveClientMixin
    return GestureDetector(
      onTap: () {
        // Only allow tapping to exit fullscreen, not to enter it.
        if (!widget.isUiVisible) {
          widget.onTap();
        }
      },
      child: Center(
        child: _buildMediaWidget(),
      ),
    );
  }

  Widget _buildMediaWidget() {
    if (_isImage(widget.fileInfo.path)) {
      return InteractiveViewer(
        panEnabled: true,
        minScale: 1.0,
        maxScale: 4.0,
        child: Image.network(
          _fileUrl,
          headers: _headers,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
                child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ));
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
                child:
                    Text('Failed to load image.', style: TextStyle(color: Colors.white)));
          },
        ),
      );
    } else if (_isVideo(widget.fileInfo.path)) {
      return Chewie(controller: _chewieController!);
    }
    return const Text('Unsupported file type', style: TextStyle(color: Colors.white));
  }
}
