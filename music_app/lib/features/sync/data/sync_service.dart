import 'dart:async';
import 'dart:convert';
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
  Future<int>? _activeSync;

  SyncService({required this.db, required this.api, required this.connectivity});

  void startAutoSync({Duration every = const Duration(minutes: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => syncNow());
  }

  void stop() => _timer?.cancel();

  Future<int> syncNow() {
    if (_activeSync != null) return _activeSync!;
    final run = _syncPending();
    _activeSync = run;
    return run.whenComplete(() => _activeSync = null);
  }

  Future<int> _syncPending() async {
    if (!connectivity.isOnline) return 0;
    final failedCreates = await db.getFailedPlaylistCreateIds();
    final pending = await db.getPendingSync(limit: 50);
    var done = 0;
    final blockedPlaylists = <int>{...failedCreates};
    for (final item in pending) {
      if (!connectivity.isOnline) break;
      final id = (item['id'] as num).toInt();
      final op = (item['op'] ?? '') as String;
      final playlistId = (item['playlistId'] as num?)?.toInt();
      if (playlistId != null && blockedPlaylists.contains(playlistId)) continue;
      final retries = (item['retries'] as num?)?.toInt() ?? 0;
      final payload = _decodePayload(item);
      final operationId = item['operationId']?.toString();
      try {
        await _push(op, item, payload, operationId);
        await db.markSyncDone(id);
        done++;
      } catch (_) {
        if (op == 'CREATE_PLAYLIST' && playlistId != null) {
          blockedPlaylists.add(playlistId);
        }
        if (!connectivity.isOnline) break;
        if (retries + 1 >= maxRetries) {
          await db.markSyncFailed(id);
        } else {
          await db.bumpSyncRetry(id, retries + 1);
        }
      }
    }
    return done;
  }

  Map<String, dynamic> _decodePayload(Map<String, dynamic> item) {
    final encoded = item['payloadJson'];
    if (encoded is String && encoded.isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {
      if (item['playlistId'] != null) 'playlistId': item['playlistId'],
      if (item['songId'] != null) 'songId': item['songId'],
      if (item['fav'] != null) 'fav': item['fav'],
      if (item['payload'] != null) 'payload': item['payload'],
    };
  }

  Future<void> _push(String op, Map<String, dynamic> item,
      Map<String, dynamic> payload, String? operationId) async {
    Map<String, dynamic> request(Map<String, dynamic> body) => {
          ...body,
          if (operationId != null) 'operationId': operationId,
        };
    final playlistUuid = payload['playlistUuid'] as String?;
    final playlistId = item['playlistId'];
    final playlistKey = playlistUuid ?? '$playlistId';
    switch (op) {
      case 'CREATE_PLAYLIST':
        await api.post('/api/playlists', request({
          'playlistUuid': playlistUuid,
          'name': payload['name'] ?? payload['payload'],
          'description': payload['description'] ?? '',
          'createdAt': payload['createdAt'],
        }));
        break;
      case 'RENAME_PLAYLIST':
        await api.put('/api/playlists/$playlistKey',
            request({'playlistUuid': payload['playlistUuid'], 'name': payload['name'] ?? payload['payload']}));
        break;
      case 'DELETE_PLAYLIST':
        await api.delete('/api/playlists/$playlistKey?operationId=$operationId');
        break;
      case 'ADD_TO_PLAYLIST':
        await api.post('/api/playlists/$playlistKey/songs',
            request({'playlistUuid': payload['playlistUuid'], 'songId': payload['songId']}));
        break;
      case 'REMOVE_FROM_PLAYLIST':
        await api.delete(
            '/api/playlists/$playlistKey/songs/${payload['songId']}?operationId=$operationId');
        break;
      case 'TOGGLE_FAVORITE':
        await api.post('/api/favorites', request({
          'songId': payload['songId'],
          'fav': payload['fav'],
        }));
        break;
      case 'PUSH_HISTORY':
        await api.post('/api/history', request({
          'op': op,
          'songId': payload['songId'],
          'playedAt': payload['playedAt'],
        }));
        break;
      case 'CLEAR_HISTORY':
        await api.post('/api/history', request({'op': op}));
        break;
      case 'DOWNLOAD_SONG':
      case 'DELETE_DOWNLOAD':
        await api.post('/api/downloads', request({
          'op': op,
          'songId': payload['songId'],
          'filePath': payload['filePath'] ?? payload['payload'],
        }));
        break;
      case 'UPDATE_PROFILE':
        await api.put('/api/auth/profile', request({
          'displayName': payload['displayName'] ?? payload['payload'],
        }));
        break;
      default:
        await api.post('/api/sync', request({'op': op, 'payload': payload}));
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
          final serverId = (p['id'] as num?)?.toInt();
          final playlist = Playlist(
            id: serverId,
            uuid: p['uuid']?.toString() ?? p['playlistUuid']?.toString(),
            name: '${p['name'] ?? 'Playlist'}',
            createdAt: (p['createdAt'] as num?)?.toInt() ?? 0,
            description: '${p['description'] ?? ''}',
            coverUrl: p['coverUrl']?.toString(),
            ownerId: p['ownerId']?.toString(),
            updatedAt: (p['updatedAt'] as num?)?.toInt() ?? 0,
            isSynced: true,
          );
          await db.upsertPlaylistFromSync(playlist);
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
            ownerId: f['ownerId']?.toString(),
            sync: false,
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
            ), ownerId: h['ownerId']?.toString(), sync: false);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
