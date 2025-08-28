import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MediaViewerPage extends StatefulWidget {
  final String filePath;
  final String fileUrl;
  final String username;
  final String password;

  const MediaViewerPage({
    super.key,
    required this.filePath,
    required this.fileUrl,
    required this.username,
    required this.password,
  });

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Future<void>? _initializeVideoPlayerFuture;
  late final Map<String, String> _headers;

  @override
  void initState() {
    super.initState();
    _createAuthHeaders();

    if (_isVideo(widget.filePath)) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.fileUrl),
        httpHeaders: _headers,
      );
      // We create a future here and use a FutureBuilder in the build method
      // to handle the asynchronous initialization.
      _initializeVideoPlayerFuture =
          _videoPlayerController!.initialize().then((_) {
        // Once the controller is initialized, create the Chewie controller
        // and rebuild the widget.
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            looping: false,
          );
        });
      });
    }
  }

  void _createAuthHeaders() {
    final credentials = '${widget.username}:${widget.password}';
    final encodedCredentials = base64.encode(utf8.encode(credentials));
    _headers = {
      'Authorization': 'Basic $encodedCredentials',
    };
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.filePath.split('/').last),
      ),
      body: Center(
        child: _buildMediaWidget(),
      ),
    );
  }

  Widget _buildMediaWidget() {
    if (_isImage(widget.filePath)) {
      // For images, we can directly use the headers.
      return Image.network(
        widget.fileUrl,
        headers: _headers,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
              child:
                  Text('Failed to load image.', style: TextStyle(color: Colors.white)));
        },
      );
    } else if (_isVideo(widget.filePath)) {
      // For videos, use a FutureBuilder to show a loading indicator
      // while the controller is initializing.
      return FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError || _chewieController == null) {
              return const Center(
                  child: Text('Failed to load video.',
                      style: TextStyle(color: Colors.white)));
            }
            // If the video is initialized, display it
            return Chewie(controller: _chewieController!);
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }
    return const Text('Unsupported file type',
        style: TextStyle(color: Colors.white));
  }
}
