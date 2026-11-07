import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_theme.dart';
import '../services/library_service.dart';
import '../widgets/ui_kit.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _c;
  String? _label;
  bool _loading = false;

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final path = await LibraryService().pickVideoFile();
    if (path == null) return;
    setState(() => _loading = true);
    await _c?.dispose();
    try {
      final ctrl = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(path))
          : VideoPlayerController.file(File(path));
      await ctrl.initialize();
      await ctrl.play();
      setState(() {
        _c = ctrl;
        _label = path.split(RegExp(r'[/\\]')).last;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không mở được video: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _playSample() async {
    setState(() => _loading = true);
    await _c?.dispose();
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(
          'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'));
      await ctrl.initialize();
      await ctrl.play();
      setState(() {
        _c = ctrl;
        _label = 'Video mẫu online';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _c != null && _c!.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('Phát video')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: AppTheme.softCard(context, radius: 24),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_loading) const LinearProgressIndicator(),
                if (_loading) const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: ready ? _c!.value.aspectRatio : 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: ready
                          ? VideoPlayer(_c!)
                          : const Center(
                              child: Icon(Icons.movie_outlined,
                                  color: Colors.white54, size: 56),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(_label ?? 'Chưa chọn video',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                if (ready)
                  Container(
                    decoration:
                        AppTheme.gradientBox(radius: 999),
                    child: IconButton(
                      icon: Icon(
                          _c!.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30),
                      onPressed: () {
                        _c!.value.isPlaying ? _c!.pause() : _c!.play();
                        setState(() {});
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                    onPressed: _loading ? null : _pick,
                    icon: const Icon(Icons.folder_open_rounded),
                    label: const Text('Chọn file MP4')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                    onPressed: _loading ? null : _playSample,
                    child: const Text('Video mẫu')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const EmptyState(
            icon: Icons.info_outline_rounded,
            title: 'Mẹo phát video',
            subtitle:
                'Chọn file MP4 trong máy để xem demo, hoặc mở video mẫu online khi có mạng.',
          ),
        ],
      ),
    );
  }
}
