import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cache đĩa cho nhạc trực tuyến.
///
/// Vấn đề: mỗi lần chuyển sang một bài online, app gọi `setAudioSource` với
/// URL và tải lại từ đầu → có độ trễ (buffering) rõ rệt, nghe "lag".
/// Lớp này tải trước bài kế tiếp vào thư mục cache, để khi người dùng bấm
/// "bài tiếp" thì phát bằng file cục bộ → cắt ngay, không chờ mạng.
///
/// Cơ chế an toàn:
/// - Tải vào file tạm `.part`, xong mới đổi tên sang file chính
///   (phát trên file chính luôn là file đã tải trọn vẹn).
/// - Giới hạn kích thước 1 file và tổng dung lượng cache.
class AudioCacheService {
  AudioCacheService._();
  static final AudioCacheService instance = AudioCacheService._();

  /// Dung lượng tối đa cho một file (60 MB).
  static const int maxFileBytes = 60 * 1024 * 1024;

  /// Tổng dung lượng cache tối đa (400 MB).
  static const int maxTotalBytes = 400 * 1024 * 1024;

  Directory? _dir;
  final Map<String, Future<File?>> _inFlight = {};

  Future<Directory> _cacheDir() async {
    final existing = _dir;
    if (existing != null) return existing;
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'audio_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  /// Khoá tên file ổn định theo URL (FNV-1a 64-bit, tự cài đặt để không
  /// phụ thuộc thêm package crypto).
  String _keyFor(String url) {
    var hash = 0xcbf29ce484222325;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Trả về file cache đã tải xong, hoặc null nếu chưa có.
  Future<File?> cachedFile(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return null;
    try {
      final dir = await _cacheDir();
      final f = File(p.join(dir.path, '${_keyFor(url)}.audio'));
      if (!await f.exists()) return null;
      final len = await f.length();
      if (len <= 0) return null;
      return f;
    } catch (_) {
      return null;
    }
  }

  /// Tải trước một bài về cache (bỏ qua nếu đã có hoặc đang tải).
  Future<void> prefetch(String url) async {
    if (url.isEmpty || !url.startsWith('http')) return;
    if (_inFlight.containsKey(url)) return;
    final future = _download(url);
    _inFlight[url] = future;
    try {
      await future;
    } catch (_) {
      // Bỏ qua lỗi mạng: cache là tối ưu, không được phá app.
    } finally {
      _inFlight.remove(url);
    }
  }

  Future<File?> _download(String url) async {
    final existing = await cachedFile(url);
    if (existing != null) return existing;

    final dir = await _cacheDir();
    final target = File(p.join(dir.path, '${_keyFor(url)}.audio'));
    final temp = File('${target.path}.part');

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request).timeout(
            const Duration(seconds: 45),
          );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      var written = 0;
      final sink = temp.openWrite();
      try {
        await for (final chunk in response.stream) {
          written += chunk.length;
          if (written > maxFileBytes) {
            await sink.close();
            if (await temp.exists()) await temp.delete();
            return null;
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      if (await temp.exists()) {
        await temp.rename(target.path);
        unawaited(_enforceQuota());
        return target;
      }
      return null;
    } catch (_) {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }
      return null;
    } finally {
      client.close();
    }
  }

  /// Xoá file cache cũ nhất khi vượt quota.
  Future<void> _enforceQuota() async {
    try {
      final dir = await _cacheDir();
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.audio'))
          .cast<File>()
          .toList();
      var total = 0;
      final withSize = <MapEntry<File, int>>[];
      for (final f in files) {
        final len = await f.length();
        withSize.add(MapEntry(f, len));
        total += len;
      }
      if (total <= maxTotalBytes) return;
      withSize.sort((a, b) => a.value.compareTo(b.value));
      var excess = total - maxTotalBytes;
      for (final entry in withSize) {
        if (excess <= 0) break;
        try {
          await entry.key.delete();
          excess -= entry.value;
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Xoá toàn bộ cache (dùng khi người dùng muốn giải phóng bộ nhớ).
  Future<void> clear() async {
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _dir = null;
    } catch (_) {}
  }
}
