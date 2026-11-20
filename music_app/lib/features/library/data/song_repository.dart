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

  /// Saves the playlist change locally and queues it for ordered synchronization.
  Future<void> addSongToPlaylistOnline(int playlistId, Song s,
      {required bool isOnline}) async {
    await db.addToPlaylist(playlistId, s);
  }
}
