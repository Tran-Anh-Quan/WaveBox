import '../../../core/network/api_client.dart';
import '../../../data/app_database.dart';
import '../../../models/song.dart';
import '../../../services/library_service.dart';

/// Repository thư viện nhạc (MVVM - tầng Data):
/// - Nguồn cục bộ: MediaStore qua LibraryService + SQLite (offline-first)
/// - Nguồn trực tuyến: RESTful API Backend (PostgreSQL qua Spring Boot, JSON)
/// - Ghi thay đổi khi mất mạng vào Pending Sync Queue trong SQLite.
class SongRepository {
  final LibraryService local;
  final AppDatabase db;
  final ApiClient api;

  SongRepository({required this.local, required this.db, required this.api});

  Future<List<Song>> loadLocalSongs() => local.loadDeviceSongs();

  Future<List<dynamic>> fetchOnlineSongs() async {
    final data = await api.get('/api/songs');
    if (data is List) return data;
    if (data is Map && data['content'] is List) return data['content'] as List;
    return [];
  }

  /// Thêm bài vào playlist: lưu SQLite ngay + đẩy lên server,
  /// nếu lỗi mạng thì ghi Pending Sync Queue để đồng bộ sau.
  Future<void> addSongToPlaylistOnline(int playlistId, Song s, {required bool isOnline}) async {
    await db.addToPlaylist(playlistId, s);
    if (!isOnline) {
      await db.enqueueSync('ADD_TO_PLAYLIST', {'playlistId': playlistId, 'songId': s.id});
      return;
    }
    try {
      await api.post('/api/playlists/$playlistId/songs', {'songId': s.id});
    } catch (_) {
      await db.enqueueSync('ADD_TO_PLAYLIST', {'playlistId': playlistId, 'songId': s.id});
    }
  }
}
