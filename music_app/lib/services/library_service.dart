import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';

/// Scans device audio via MediaStore (Android) + manual file picking.
/// Falls back to bundled sample tracks so the app is demoable on any device.
class LibraryService {
  final OnAudioQuery _query = OnAudioQuery();

  static final List<Song> sampleTracks = [
    Song(
      id: 900001,
      title: 'SoundHelix Sample 1',
      artist: 'T. Schürger',
      album: 'Sample Album',
      data: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      durationMs: 372000,
      isOnline: true,
      genreId: 1,
      format: 'mp3',
      playCount: 120,
    ),
    Song(
      id: 900002,
      title: 'SoundHelix Sample 2',
      artist: 'T. Schürger',
      album: 'Sample Album',
      data: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      durationMs: 425000,
      isOnline: true,
      genreId: 4,
      format: 'mp3',
      playCount: 98,
    ),
    Song(
      id: 900003,
      title: 'SoundHelix Sample 3',
      artist: 'T. Schürger',
      album: 'Sample Album',
      data: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      durationMs: 349000,
      isOnline: true,
      genreId: 6,
      format: 'mp3',
      playCount: 76,
    ),
  ];

  Future<bool> ensurePermission() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;
    var audio = await Permission.audio.status;
    if (audio.isGranted) return true;
    final req = await [Permission.audio, Permission.storage].request();
    if ((req[Permission.audio]?.isGranted ?? false) ||
        (req[Permission.storage]?.isGranted ?? false)) {
      return true;
    }
    // Legacy fallback for Android <= 12
    final legacy = await Permission.storage.request();
    return legacy.isGranted;
  }

  Future<List<Song>> loadDeviceSongs() async {
    final out = <Song>[];
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final ok = await ensurePermission();
        if (ok) {
          final items = await _query.querySongs(
            sortType: SongSortType.TITLE,
            orderType: OrderType.ASC_OR_SMALLER,
            uriType: UriType.EXTERNAL,
            ignoreCase: true,
          );
          for (final s in items) {
            final String path = s.data;
            if (path.isEmpty) continue;
            final lower = path.toLowerCase();
            if (!(lower.endsWith('.mp3') ||
                lower.endsWith('.flac') ||
                lower.endsWith('.wav') ||
                lower.endsWith('.m4a') ||
                lower.endsWith('.ogg'))) {
              continue;
            }
            final String artist = s.artist ?? '';
            final String album = s.album ?? '';
            final lowerPath = path.toLowerCase();
            final fmt = lowerPath.endsWith('.flac')
                ? 'flac'
                : lowerPath.endsWith('.wav')
                    ? 'wav'
                    : lowerPath.endsWith('.m4a')
                        ? 'm4a'
                        : lowerPath.endsWith('.ogg')
                            ? 'ogg'
                            : 'mp3';
            out.add(Song(
              id: s.id,
              title: s.title.isEmpty ? 'Unknown' : s.title,
              artist: (artist == '<unknown>' || artist.isEmpty)
                  ? 'Unknown Artist'
                  : artist,
              album: (album == '<unknown>' || album.isEmpty)
                  ? 'Unknown Album'
                  : album,
              data: path,
              durationMs: s.duration ?? 0,
              // Gán thể loại vòng quanh để lọc thể loại (UC 2.4) vẫn có kết quả với nhạc máy
              genreId: (s.id % 6) + 1,
              format: fmt,
            ));
          }
        }
      } catch (_) {
        // fall through to manual/demo
      }
    }
    return out;
  }

  /// Let user pick audio files manually (works on Android/iOS/Desktop).
  Future<List<Song>> pickAudioFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'flac', 'wav', 'm4a', 'ogg'],
    );
    if (files.isEmpty) return [];
    final now = DateTime.now().millisecondsSinceEpoch;
    var i = 0;
    final out = <Song>[];
    for (final f in files) {
      final String? fp = f.path;
      if (fp == null || fp.isEmpty) continue;
      i++;
      final name = f.name.replaceAll(RegExp(r'\.(mp3|flac|wav|m4a|ogg)$', caseSensitive: false), '');
      out.add(Song(
        id: now + i,
        title: name.isEmpty ? f.name : name,
        artist: 'Local file',
        album: 'Picked files',
        data: fp,
        durationMs: 0,
        genreId: ((now + i) % 6) + 1,
        format: f.name.split('.').last.toLowerCase(),
      ));
    }
    return out;
  }

  Future<String?> pickVideoFile() async {
    final files = await FilePicker.pickFiles(type: FileType.video);
    if (files.isEmpty) return null;
    return files.first.path ?? files.first.xFile.path;
  }
}
