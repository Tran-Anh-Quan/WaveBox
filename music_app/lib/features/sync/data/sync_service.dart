import 'dart:async';
import '../../../core/network/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../data/app_database.dart';
import '../../../models/song.dart';

/// Đồng bộ (UC 9.x): RESTful API + Pending Sync Queue (SQLite) +
/// retry tối đa 5 lần + khôi phục khi đăng nhập thiết bị mới (UC 9.4).
class SyncService {
  final AppDatabase db;
  final ApiClient api;
  final ConnectivityService connectivity;
  Timer? _timer;
  int maxRetries = 5;

  SyncService({required this.db, required this.api, required this.connectivity});

  void startAutoSync({Duration every = const Duration(minutes: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => syncNow());
  }

  void stop() => _timer?.cancel();

  Future<int> syncNow() async {
    if (!connectivity.isOnline) return 0;
    final pending = await db.getPendingSync(limit: 50);
    var done = 0;
    for (final item in pending) {
      final id = (item['id'] as num).toInt();
      final op = (item['op'] ?? '') as String;
      final retries = (item['retries'] as num?)?.toInt() ?? 0;
      try {
        await _push(op, item);
        await db.markSyncDone(id);
        done++;
      } catch (_) {
        if (retries + 1 >= maxRetries) {
          await db.markSyncFailed(id);
        } else {
          await db.bumpSyncRetry(id, retries + 1);
        }
      }
    }
    return done;
  }

  Future<void> _push(String op, Map<String, dynamic> item) async {
    switch (op) {
      case 'CREATE_PLAYLIST':
        await api.post('/api/playlists', {
          'localId': item['playlistId'],
          'name': item['payload'],
        });
        break;
      case 'RENAME_PLAYLIST':
        await api.put('/api/playlists/${item['playlistId']}',
            {'name': item['payload']});
        break;
      case 'DELETE_PLAYLIST':
        await api.delete('/api/playlists/${item['playlistId']}');
        break;
      case 'ADD_TO_PLAYLIST':
        await api.post('/api/playlists/${item['playlistId']}/songs',
            {'songId': item['songId']});
        break;
      case 'REMOVE_FROM_PLAYLIST':
        await api.delete(
            '/api/playlists/${item['playlistId']}/songs/${item['songId']}');
        break;
      case 'TOGGLE_FAVORITE':
        await api.post('/api/favorites',
            {'songId': item['songId'], 'fav': item['fav']});
        break;
      case 'PUSH_HISTORY':
      case 'CLEAR_HISTORY':
        await api.post('/api/history',
            {'op': op, 'songId': item['songId']});
        break;
      case 'DOWNLOAD_SONG':
      case 'DELETE_DOWNLOAD':
        await api.post('/api/downloads',
            {'op': op, 'songId': item['songId']});
        break;
      case 'UPDATE_PROFILE':
        await api.put('/api/auth/profile', {'displayName': item['payload']});
        break;
      default:
        await api.post('/api/sync', {'op': op, 'payload': item['payload']});
    }
  }

  /// Khôi phục dữ liệu cá nhân về thiết bị mới (UC 9.4):
  /// pull playlists + favorites + history từ cloud rồi upsert vào SQLite.
  /// Firestore dùng 3 collection users/{uid}/playlists|favorites|history;
  /// bản REST này gọi 3 endpoint tương đương, backend vắng thì bỏ qua êm.
  Future<bool> restoreFromCloud() async {
    if (!connectivity.isOnline) return false;
    try {
      final pls = await api.get('/api/playlists');
      if (pls is List) {
        for (final p in pls) {
          if (p is! Map) continue;
          final name = '${p['name'] ?? 'Playlist'}';
          final existing = await db.getPlaylists();
          if (!existing.any((e) => e.name == name)) {
            await db.insertPlaylist(name);
          }
        }
      }
      final favs = await api.get('/api/favorites');
      if (favs is List) {
        for (final f in favs) {
          if (f is! Map) continue;
          final sid = (f['songId'] as num?)?.toInt();
          if (sid == null) continue;
          await db.toggleFavorite(
            Song(
              id: sid,
              title: '${f['title'] ?? 'Bài hát $sid'}',
              artist: '${f['artist'] ?? 'Unknown Artist'}',
              album: '${f['album'] ?? ''}',
              data: '${f['data'] ?? ''}',
              durationMs: (f['durationMs'] as num?)?.toInt() ?? 0,
            ),
            true,
          );
        }
      }
      final his = await api.get('/api/history');
      if (his is List) {
        for (final h in his) {
          if (h is! Map) continue;
          final sid = (h['songId'] as num?)?.toInt();
          if (sid == null) continue;
          await db.pushHistory(Song(
            id: sid,
            title: '${h['title'] ?? 'Bài hát $sid'}',
            artist: '${h['artist'] ?? 'Unknown Artist'}',
            album: '${h['album'] ?? ''}',
            data: '${h['data'] ?? ''}',
            durationMs: (h['durationMs'] as num?)?.toInt() ?? 0,
          ));
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
