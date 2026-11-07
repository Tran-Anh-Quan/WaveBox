import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/theme/app_theme.dart';
import '../data/app_database.dart';
import '../models/song.dart';
import '../widgets/ui_kit.dart';

class DownloadService {
  final AppDatabase db;
  DownloadService({required this.db});

  Future<String> downloadSong(Song s) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = _extOf(s);
    final safe = s.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final fileName = '${s.id}_$safe.$ext';
    final filePath = p.join(dir.path, fileName);

    if (await File(filePath).exists()) {
      await db.saveDownload(
          songId: s.id,
          filePath: filePath,
          format: ext,
          fileSize: await File(filePath).length());
      await db.upsertSongCache(s.copyWith(isDownloaded: true));
      return filePath;
    }

    final res = await http.get(Uri.parse(s.data));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Tải thất bại (HTTP ${res.statusCode})');
    }
    final f = File(filePath);
    await f.writeAsBytes(res.bodyBytes, flush: true);
    final size = await f.length();
    await db.saveDownload(
        songId: s.id, filePath: filePath, format: ext, fileSize: size);
    await db.upsertSongCache(s.copyWith(isDownloaded: true));
    await db.enqueueSync('DOWNLOAD_SONG', {'songId': s.id, 'payload': filePath});
    return filePath;
  }

  Future<void> deleteDownload(Song s) async {
    final all = await db.getDownloads();
    final match =
        all.where((e) => (e['songId'] as num).toInt() == s.id).toList();
    for (final m in match) {
      final fp = '${m['filePath'] ?? ''}';
      try {
        final f = File(fp);
        if (fp.isNotEmpty && await f.exists()) await f.delete();
      } catch (_) {}
    }
    await db.removeDownload(s.id);
    await db.enqueueSync('DELETE_DOWNLOAD', {'songId': s.id});
  }

  String _extOf(Song s) {
    final fromData = s.data.split('.').isNotEmpty
        ? s.data.split('.').last.split('?').first.toLowerCase()
        : 'mp3';
    if (['mp3', 'wav', 'm4a', 'flac', 'ogg'].contains(fromData)) {
      return fromData;
    }
    return (s.format ?? 'mp3').toLowerCase();
  }

  static Future<Map<String, String>> fileInfo(String path) async {
    try {
      final f = File(path);
      final exists = await f.exists();
      if (!exists) return {'Tệp': 'không tồn tại', 'Đường dẫn': path};
      final size = await f.length();
      final ext = path.split('.').last.toUpperCase();
      return {
        'Đường dẫn': path,
        'Định dạng': ext,
        'Dung lượng': _fmtSize(size),
      };
    } catch (e) {
      return {'Lỗi': '$e'};
    }
  }

  static String _fmtSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
}

class SongDetailScreen extends StatefulWidget {
  final Song song;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  const SongDetailScreen(
      {super.key,
      required this.song,
      this.isFavorite = false,
      this.onToggleFavorite});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  Map<String, String>? _fileRows;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.song.isOnline) return;
    final rows = await DownloadService.fileInfo(widget.song.data);
    if (mounted) setState(() => _fileRows = rows);
  }

  String get _duration {
    final d = Duration(milliseconds: widget.song.durationMs);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.song;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài hát'),
        actions: [
          IconButton(
            icon: Icon(
                widget.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: widget.isFavorite ? Colors.pinkAccent : null),
            onPressed: widget.onToggleFavorite,
            tooltip: widget.isFavorite ? 'Bỏ thích' : 'Thích',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            height: 190,
            decoration: AppTheme.gradientBox(radius: 24),
            child: Stack(
              children: [
                const Center(
                    child: Icon(Icons.music_note_rounded,
                        color: Colors.white, size: 72)),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: SourcePill(
                      isOnline: s.isOnline,
                      isDownloaded: s.isDownloaded),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text(
                        (s.format ??
                                s.data.split('.').last.split('?').first)
                            .toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.title,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.25)),
                const SizedBox(height: 4),
                Text('${s.artist} • ${s.album}',
                    style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness ==
                                Brightness.dark
                            ? Colors.white60
                            : Colors.black54)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: AppTheme.softCard(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông tin',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                DetailRow(
                    label: 'Nguồn',
                    value: s.isOnline
                        ? 'Trực tuyến — streaming'
                        : 'Bộ nhớ máy — offline'),
                DetailRow(label: 'Nghệ sĩ', value: s.artist),
                DetailRow(label: 'Album', value: s.album),
                DetailRow(label: 'Thời lượng', value: _duration),
                if (s.fileSize > 0)
                  DetailRow(
                      label: 'Dung lượng',
                      value: DownloadService._fmtSize(s.fileSize)),
                DetailRow(
                    label: 'Trạng thái',
                    value: s.isDownloaded
                        ? 'Đã tải về máy'
                        : 'Chưa tải về máy'),
              ],
            ),
          ),
          if (_fileRows != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: AppTheme.softCard(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tệp trên thiết bị',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 4),
                  for (final e in _fileRows!.entries)
                    DetailRow(label: e.key, value: e.value),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _onMainAction,
                icon: Icon(s.isDownloaded
                    ? Icons.delete_outline_rounded
                    : Icons.download_rounded),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(_busy
                      ? 'Đang xử lý...'
                      : (s.isDownloaded ? 'Xóa bản tải' : 'Tải về máy')),
                ),
              ),
            ),
          ),
          if (!s.isOnline && !s.isDownloaded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text('Bài này đã nằm trên máy nên không cần tải thêm.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness ==
                              Brightness.dark
                          ? Colors.white54
                          : Colors.black54)),
            ),
        ],
      ),
    );
  }

  Future<void> _onMainAction() async {
    final s = widget.song;
    setState(() => _busy = true);
    try {
      final svc = DownloadService(db: AppDatabase());
      if (s.isDownloaded) {
        await svc.deleteDownload(s);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Đã xóa bản tải để giải phóng bộ nhớ')));
          Navigator.pop(context, 'deleted');
        }
      } else {
        if (!s.isOnline) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text('Bài này đã nằm trên máy, không cần tải thêm')));
          }
        } else {
          await svc.downloadSong(s);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Đã tải về máy để nghe offline')));
            Navigator.pop(context, 'downloaded');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
