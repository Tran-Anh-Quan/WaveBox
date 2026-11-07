import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/catalog.dart';
import '../models/playlist.dart';
import '../models/song.dart';

/// SQLite v3 — offline-first, phủ 10 nhóm UC (xem DATABASE_DESIGN.md).
/// Giữ tương thích dữ liệu v2: onUpgrade tạo bảng mới + ALTER playlists.
class AppDatabase {
  static final AppDatabase _i = AppDatabase._();
  factory AppDatabase() => _i;
  AppDatabase._();

  Database? _db;
  final Map<String, List<Map<String, dynamic>>> _mem = {
    'playlists': [],
    'playlist_songs': [],
    'favorites': [],
    'history': [],
    'pending_sync': [],
    'artists': [],
    'albums': [],
    'genres': [],
    'songs_cache': [],
    'downloads': [],
    'users': [],
    'settings': [],
  };
  int _autoId = 1;

  Future<Database?> _open() async {
    if (_db != null) return _db;
    if (kIsWeb) return null;
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'music_app.db');
      _db = await openDatabase(path, version: 3,
          onCreate: (db, v) async => _createV3(db),
          onUpgrade: (db, oldV, newV) async => _upgrade(db, oldV));
      return _db;
    } catch (_) {
      return null;
    }
  }

  Future<void> _createV3(Database db) async {
    await db.execute(
        'CREATE TABLE playlists(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, createdAt INTEGER NOT NULL, uuid TEXT UNIQUE, description TEXT DEFAULT "", coverUrl TEXT, ownerId TEXT, updatedAt INTEGER NOT NULL DEFAULT 0, isSynced INTEGER NOT NULL DEFAULT 1)');
    await db.execute(
        'CREATE TABLE playlist_songs(id INTEGER PRIMARY KEY AUTOINCREMENT, playlistId INTEGER NOT NULL REFERENCES playlists(id) ON DELETE CASCADE, songId INTEGER NOT NULL, songTitle TEXT, songArtist TEXT, songAlbum TEXT, songData TEXT, songDuration INTEGER, addedAt INTEGER NOT NULL DEFAULT 0, UNIQUE(playlistId, songId))');
    await db.execute(
        'CREATE TABLE favorites(songId INTEGER PRIMARY KEY, songTitle TEXT, songArtist TEXT, songAlbum TEXT, songData TEXT, songDuration INTEGER, ownerId TEXT, likedAt INTEGER NOT NULL DEFAULT 0, isSynced INTEGER NOT NULL DEFAULT 1)');
    await db.execute(
        'CREATE TABLE history(id INTEGER PRIMARY KEY AUTOINCREMENT, songId INTEGER NOT NULL, songTitle TEXT, songArtist TEXT, songAlbum TEXT, songData TEXT, songDuration INTEGER, ownerId TEXT, playedAt INTEGER NOT NULL)');
    await db.execute(
        'CREATE TABLE pending_sync(id INTEGER PRIMARY KEY AUTOINCREMENT, op TEXT NOT NULL, playlistId INTEGER, songId INTEGER, fav INTEGER, payload TEXT, status TEXT DEFAULT "pending", retries INTEGER DEFAULT 0, createdAt INTEGER NOT NULL)');
    await db.execute(
        'CREATE TABLE artists(id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL, coverUrl TEXT, bio TEXT)');
    await db.execute(
        'CREATE TABLE albums(id INTEGER PRIMARY KEY, title TEXT NOT NULL, artistId INTEGER REFERENCES artists(id), artistName TEXT DEFAULT "", coverUrl TEXT, releaseYear INTEGER)');
    await db.execute(
        'CREATE TABLE genres(id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL, coverUrl TEXT)');
    await db.execute(
        'CREATE TABLE songs_cache(id INTEGER PRIMARY KEY, title TEXT NOT NULL, artist TEXT, artistId INTEGER, album TEXT, albumId INTEGER, genreId INTEGER, data TEXT NOT NULL, durationMs INTEGER DEFAULT 0, artUri TEXT, fileSize INTEGER DEFAULT 0, format TEXT, isOnline INTEGER DEFAULT 0, isDownloaded INTEGER DEFAULT 0, playCount INTEGER DEFAULT 0, updatedAt INTEGER DEFAULT 0)');
    await db.execute('CREATE INDEX idx_songs_title ON songs_cache(title)');
    await db.execute('CREATE INDEX idx_songs_artist ON songs_cache(artist)');
    await db.execute('CREATE INDEX idx_songs_album ON songs_cache(album)');
    await db.execute('CREATE INDEX idx_songs_genre ON songs_cache(genreId)');
    await db.execute(
        'CREATE TABLE downloads(songId INTEGER PRIMARY KEY, filePath TEXT NOT NULL, fileSize INTEGER DEFAULT 0, format TEXT, status TEXT DEFAULT "done", downloadedAt INTEGER NOT NULL)');
    await db.execute(
        'CREATE TABLE users(id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, displayName TEXT, photoUrl TEXT, lastSyncAt INTEGER DEFAULT 0)');
    await db.execute(
        'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');
    await db.execute('CREATE INDEX idx_history_played ON history(playedAt DESC)');
  }

  Future<void> _upgrade(Database db, int oldV) async {
    if (oldV < 2) {
      await db.execute(
          'CREATE TABLE IF NOT EXISTS pending_sync(id INTEGER PRIMARY KEY AUTOINCREMENT, op TEXT NOT NULL, playlistId INTEGER, songId INTEGER, fav INTEGER, payload TEXT, status TEXT DEFAULT "pending", retries INTEGER DEFAULT 0, createdAt INTEGER NOT NULL)');
    }
    if (oldV < 3) {
      await db.execute(
          'CREATE TABLE IF NOT EXISTS artists(id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL, coverUrl TEXT, bio TEXT)');
      await db.execute(
          'CREATE TABLE IF NOT EXISTS albums(id INTEGER PRIMARY KEY, title TEXT NOT NULL, artistId INTEGER, artistName TEXT DEFAULT "", coverUrl TEXT, releaseYear INTEGER)');
      await db.execute(
          'CREATE TABLE IF NOT EXISTS genres(id INTEGER PRIMARY KEY, name TEXT UNIQUE NOT NULL, coverUrl TEXT)');
      await db.execute(
          'CREATE TABLE IF NOT EXISTS songs_cache(id INTEGER PRIMARY KEY, title TEXT NOT NULL, artist TEXT, artistId INTEGER, album TEXT, albumId INTEGER, genreId INTEGER, data TEXT NOT NULL, durationMs INTEGER DEFAULT 0, artUri TEXT, fileSize INTEGER DEFAULT 0, format TEXT, isOnline INTEGER DEFAULT 0, isDownloaded INTEGER DEFAULT 0, playCount INTEGER DEFAULT 0, updatedAt INTEGER DEFAULT 0)');
      await db.execute(
          'CREATE TABLE IF NOT EXISTS downloads(songId INTEGER PRIMARY KEY, filePath TEXT NOT NULL, fileSize INTEGER DEFAULT 0, format TEXT, status TEXT DEFAULT "done", downloadedAt INTEGER NOT NULL)');
      await db.execute(
          'CREATE TABLE IF NOT EXISTS users(id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, displayName TEXT, photoUrl TEXT, lastSyncAt INTEGER DEFAULT 0)');
      await db.execute(
          'CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT)');
      for (final col in [
        'uuid TEXT UNIQUE',
        'description TEXT DEFAULT ""',
        'coverUrl TEXT',
        'ownerId TEXT',
        'updatedAt INTEGER NOT NULL DEFAULT 0',
        'isSynced INTEGER NOT NULL DEFAULT 1'
      ]) {
        try {
          await db.execute('ALTER TABLE playlists ADD COLUMN $col');
        } catch (_) {}
      }
      for (final col in ['ownerId TEXT', 'likedAt INTEGER NOT NULL DEFAULT 0', 'isSynced INTEGER NOT NULL DEFAULT 1']) {
        try {
          await db.execute('ALTER TABLE favorites ADD COLUMN $col');
        } catch (_) {}
      }
      try {
        await db.execute('ALTER TABLE history ADD COLUMN ownerId TEXT');
      } catch (_) {}
      try {
        await db.execute(
            'UPDATE playlists SET updatedAt=createdAt WHERE updatedAt=0 OR updatedAt IS NULL');
      } catch (_) {}
    }
  }

  // ================= Playlists (UC 5.x + 9.1) =================
  Future<int> insertPlaylist(String name, {String? ownerId}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final row = {
      'name': name,
      'createdAt': now,
      'description': '',
      'ownerId': ownerId,
      'updatedAt': now,
      'isSynced': 0,
    };
    final db = await _open();
    if (db == null) {
      final id = _autoId++;
      _mem['playlists']!.add({'id': id, ...row});
      return id;
    }
    return db.insert('playlists', row);
  }

  Future<List<Playlist>> getPlaylists() async {
    final db = await _open();
    if (db == null) return _mem['playlists']!.map(Playlist.fromMap).toList();
    final rows = await db.query('playlists', orderBy: 'updatedAt DESC');
    return rows.map(Playlist.fromMap).toList();
  }

  Future<void> renamePlaylist(int id, String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _open();
    if (db == null) {
      final i = _mem['playlists']!.indexWhere((e) => e['id'] == id);
      if (i >= 0) {
        _mem['playlists']![i]['name'] = name;
        _mem['playlists']![i]['updatedAt'] = now;
        _mem['playlists']![i]['isSynced'] = 0;
      }
      return;
    }
    await db.update('playlists', {'name': name, 'updatedAt': now, 'isSynced': 0},
        where: 'id=?', whereArgs: [id]);
  }

  Future<void> deletePlaylist(int id) async {
    final db = await _open();
    if (db == null) {
      _mem['playlists']!.removeWhere((e) => e['id'] == id);
      _mem['playlist_songs']!.removeWhere((e) => e['playlistId'] == id);
      return;
    }
    await db.delete('playlist_songs', where: 'playlistId=?', whereArgs: [id]);
    await db.delete('playlists', where: 'id=?', whereArgs: [id]);
  }

  Future<void> addToPlaylist(int playlistId, Song s) async {
    final db = await _open();
    final row = {
      'playlistId': playlistId,
      'songId': s.id,
      'songTitle': s.title,
      'songArtist': s.artist,
      'songAlbum': s.album,
      'songData': s.data,
      'songDuration': s.durationMs,
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    };
    if (db == null) {
      final exists = _mem['playlist_songs']!
          .any((e) => e['playlistId'] == playlistId && e['songId'] == s.id);
      if (!exists) _mem['playlist_songs']!.add({'id': _autoId++, ...row});
      return;
    }
    final dup = await db.query('playlist_songs',
        where: 'playlistId=? AND songId=?', whereArgs: [playlistId, s.id]);
    if (dup.isEmpty) await db.insert('playlist_songs', row);
    await db.update('playlists', {
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'isSynced': 0
    }, where: 'id=?', whereArgs: [playlistId]);
  }

  Future<void> removeFromPlaylist(int playlistId, int songId) async {
    final db = await _open();
    if (db == null) {
      _mem['playlist_songs']!.removeWhere(
          (e) => e['playlistId'] == playlistId && e['songId'] == songId);
      return;
    }
    await db.delete('playlist_songs',
        where: 'playlistId=? AND songId=?', whereArgs: [playlistId, songId]);
  }

  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    final db = await _open();
    List<Map<String, dynamic>> rows;
    if (db == null) {
      rows = _mem['playlist_songs']!
          .where((e) => e['playlistId'] == playlistId)
          .toList();
    } else {
      rows = await db.query('playlist_songs',
          where: 'playlistId=?', whereArgs: [playlistId], orderBy: 'addedAt ASC');
    }
    return rows
        .map((e) => Song(
              id: (e['songId'] as num).toInt(),
              title: (e['songTitle'] ?? 'Unknown') as String,
              artist: (e['songArtist'] ?? 'Unknown') as String,
              album: (e['songAlbum'] ?? '') as String,
              data: (e['songData'] ?? '') as String,
              durationMs: (e['songDuration'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  // ================= Favorites (UC 6.1-6.3 + 9.2) =================
  Future<void> toggleFavorite(Song s, bool fav, {String? ownerId}) async {
    final db = await _open();
    if (db == null) {
      if (fav) {
        if (!_mem['favorites']!.any((e) => e['songId'] == s.id)) {
          _mem['favorites']!.add({
            'songId': s.id,
            'songTitle': s.title,
            'songArtist': s.artist,
            'songAlbum': s.album,
            'songData': s.data,
            'songDuration': s.durationMs,
            'ownerId': ownerId,
            'likedAt': DateTime.now().millisecondsSinceEpoch,
            'isSynced': 0,
          });
        }
      } else {
        _mem['favorites']!.removeWhere((e) => e['songId'] == s.id);
      }
      return;
    }
    if (fav) {
      await db.insert(
          'favorites',
          {
            'songId': s.id,
            'songTitle': s.title,
            'songArtist': s.artist,
            'songAlbum': s.album,
            'songData': s.data,
            'songDuration': s.durationMs,
            'ownerId': ownerId,
            'likedAt': DateTime.now().millisecondsSinceEpoch,
            'isSynced': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete('favorites', where: 'songId=?', whereArgs: [s.id]);
    }
  }

  Future<Set<int>> getFavoriteIds() async {
    final db = await _open();
    if (db == null) {
      return _mem['favorites']!.map((e) => (e['songId'] as num).toInt()).toSet();
    }
    final rows = await db.query('favorites');
    return rows.map((e) => (e['songId'] as num).toInt()).toSet();
  }

  Future<List<Song>> getFavorites() async {
    final db = await _open();
    List<Map<String, dynamic>> rows;
    if (db == null) {
      rows = _mem['favorites']!;
    } else {
      rows = await db.query('favorites', orderBy: 'likedAt DESC');
    }
    return rows
        .map((e) => Song(
              id: (e['songId'] as num).toInt(),
              title: (e['songTitle'] ?? 'Unknown') as String,
              artist: (e['songArtist'] ?? 'Unknown') as String,
              album: (e['songAlbum'] ?? '') as String,
              data: (e['songData'] ?? '') as String,
              durationMs: (e['songDuration'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  // ================= History (UC 6.4 + 9.3) =================
  Future<void> pushHistory(Song s, {String? ownerId}) async {
    final db = await _open();
    final row = {
      'songId': s.id,
      'songTitle': s.title,
      'songArtist': s.artist,
      'songAlbum': s.album,
      'songData': s.data,
      'songDuration': s.durationMs,
      'ownerId': ownerId,
      'playedAt': DateTime.now().millisecondsSinceEpoch,
    };
    if (db == null) {
      _mem['history']!.insert(0, {'id': _autoId++, ...row});
      if (_mem['history']!.length > 100) _mem['history']!.length = 100;
    } else {
      await db.insert('history', row);
      await db.rawDelete(
          'DELETE FROM history WHERE id NOT IN (SELECT id FROM history ORDER BY playedAt DESC LIMIT 100)');
    }
    // UC 9.3: hàng đợi đồng bộ lịch sử — bỏ qua lỗi nếu trùng lặp
    try {
      await enqueueSync('PUSH_HISTORY', {'songId': s.id, 'payload': s.title});
    } catch (_) {}
  }

  Future<List<Song>> getHistory() async {
    final db = await _open();
    List<Map<String, dynamic>> rows;
    if (db == null) {
      rows = _mem['history']!;
    } else {
      rows = await db.query('history', orderBy: 'playedAt DESC', limit: 100);
    }
    return rows
        .map((e) => Song(
              id: (e['songId'] as num).toInt(),
              title: (e['songTitle'] ?? 'Unknown') as String,
              artist: (e['songArtist'] ?? 'Unknown') as String,
              album: (e['songAlbum'] ?? '') as String,
              data: (e['songData'] ?? '') as String,
              durationMs: (e['songDuration'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  Future<void> clearHistory() async {
    final db = await _open();
    if (db == null) {
      _mem['history']!.clear();
      return;
    }
    await db.delete('history');
    await enqueueSync('CLEAR_HISTORY', {});
  }

  Future<void> deleteHistoryItem(int id) async {
    final db = await _open();
    if (db == null) {
      _mem['history']!.removeWhere((e) => (e['id'] as num?)?.toInt() == id);
      return;
    }
    await db.delete('history', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getHistoryRows() async {
    final db = await _open();
    if (db == null) return List.of(_mem['history']!);
    return db.query('history', orderBy: 'playedAt DESC', limit: 100);
  }

  // ================= Catalog cache (UC 2.x + 7.x) =================
  Future<void> upsertSongCache(Song s) async {
    final db = await _open();
    if (db == null) {
      final i = _mem['songs_cache']!.indexWhere((e) => e['id'] == s.id);
      final row = {'id': s.id, ...s.toCacheMap()};
      if (i >= 0) {
        _mem['songs_cache']![i] = row;
      } else {
        _mem['songs_cache']!.add(row);
      }
      return;
    }
    await db.insert('songs_cache', s.toCacheMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertSongsCache(List<Song> songs) async {
    for (final s in songs) {
      await upsertSongCache(s);
    }
  }

  /// Tìm kiếm offline: theo tên bài / nghệ sĩ / album + lọc thể loại (UC 2.1-2.4).
  Future<List<Song>> searchCache(String keyword, {int? genreId}) async {
    final db = await _open();
    final q = '%${keyword.trim().toLowerCase()}%';
    if (db == null) {
      return _mem['songs_cache']!
          .where((e) =>
              '${e['title']} ${e['artist']} ${e['album']}'
                  .toLowerCase()
                  .contains(keyword.toLowerCase()) &&
              (genreId == null || e['genreId'] == genreId))
          .map(Song.fromMap)
          .toList();
    }
    final where = StringBuffer(
        '(LOWER(title) LIKE ? OR LOWER(artist) LIKE ? OR LOWER(album) LIKE ?)');
    final args = <Object?>[q, q, q];
    if (genreId != null) {
      where.write(' AND genreId=?');
      args.add(genreId);
    }
    final rows = await db.query('songs_cache',
        where: where.toString(), whereArgs: args, orderBy: 'playCount DESC, title ASC', limit: 200);
    return rows.map(Song.fromMap).toList();
  }

  Future<List<Song>> getDownloadedSongs() async {
    final db = await _open();
    if (db == null) {
      return _mem['songs_cache']!
          .where((e) => (e['isDownloaded'] as num? ?? 0) == 1)
          .map(Song.fromMap)
          .toList();
    }
    final rows = await db.query('songs_cache',
        where: 'isDownloaded=1', orderBy: 'title ASC');
    return rows.map(Song.fromMap).toList();
  }

  Future<void> markDownloaded(int songId, bool downloaded) async {
    final db = await _open();
    if (db == null) {
      final i = _mem['songs_cache']!.indexWhere((e) => e['id'] == songId);
      if (i >= 0) _mem['songs_cache']![i]['isDownloaded'] = downloaded ? 1 : 0;
      return;
    }
    await db.update('songs_cache', {'isDownloaded': downloaded ? 1 : 0},
        where: 'id=?', whereArgs: [songId]);
  }

  // ================= genres / artists / albums =================
  Future<void> seedGenresIfEmpty() async {
    final current = await getGenres();
    if (current.isNotEmpty) return;
    for (final g in Genre.defaults()) {
      await upsertGenre(g);
    }
  }

  Future<void> upsertGenre(Genre g) async {
    final db = await _open();
    if (db == null) {
      final i = _mem['genres']!.indexWhere((e) => e['id'] == g.id);
      if (i >= 0) {
        _mem['genres']![i] = g.toMap();
      } else {
        _mem['genres']!.add(g.toMap());
      }
      return;
    }
    await db.insert('genres', g.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Genre>> getGenres() async {
    final db = await _open();
    if (db == null) return _mem['genres']!.map(Genre.fromMap).toList();
    final rows = await db.query('genres', orderBy: 'name ASC');
    return rows.map(Genre.fromMap).toList();
  }

  Future<void> upsertArtist(Artist a) async {
    final db = await _open();
    if (db == null) {
      final i = _mem['artists']!.indexWhere((e) => e['id'] == a.id);
      if (i >= 0) {
        _mem['artists']![i] = a.toMap();
      } else {
        _mem['artists']!.add(a.toMap());
      }
      return;
    }
    await db.insert('artists', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Artist>> getArtists() async {
    final db = await _open();
    if (db == null) return _mem['artists']!.map(Artist.fromMap).toList();
    final rows = await db.query('artists', orderBy: 'name ASC');
    return rows.map(Artist.fromMap).toList();
  }

  Future<void> upsertAlbum(Album a) async {
    final db = await _open();
    if (db == null) {
      final i = _mem['albums']!.indexWhere((e) => e['id'] == a.id);
      if (i >= 0) {
        _mem['albums']![i] = a.toMap();
      } else {
        _mem['albums']!.add(a.toMap());
      }
      return;
    }
    await db.insert('albums', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Album>> getAlbums() async {
    final db = await _open();
    if (db == null) return _mem['albums']!.map(Album.fromMap).toList();
    final rows = await db.query('albums', orderBy: 'title ASC');
    return rows.map(Album.fromMap).toList();
  }

  // ================= downloads (UC 1.4 + 7.5) =================
  Future<void> saveDownload(
      {required int songId,
      required String filePath,
      int fileSize = 0,
      String? format}) async {
    final row = {
      'songId': songId,
      'filePath': filePath,
      'fileSize': fileSize,
      'format': format,
      'status': 'done',
      'downloadedAt': DateTime.now().millisecondsSinceEpoch,
    };
    final db = await _open();
    if (db == null) {
      _mem['downloads']!.removeWhere((e) => e['songId'] == songId);
      _mem['downloads']!.add(row);
      return;
    }
    await db.insert('downloads', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
    await markDownloaded(songId, true);
  }

  Future<void> removeDownload(int songId) async {
    final db = await _open();
    if (db == null) {
      _mem['downloads']!.removeWhere((e) => e['songId'] == songId);
      return;
    }
    await db.delete('downloads', where: 'songId=?', whereArgs: [songId]);
    await markDownloaded(songId, false);
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    final db = await _open();
    if (db == null) return List.of(_mem['downloads']!);
    return db.query('downloads', orderBy: 'downloadedAt DESC');
  }

  // ================= users + settings (UC 8.x + 10.x) =================
  Future<void> upsertUser(AppUser u) async {
    final db = await _open();
    if (db == null) {
      final i = _mem['users']!.indexWhere((e) => e['id'] == u.id);
      if (i >= 0) {
        _mem['users']![i] = u.toMap();
      } else {
        _mem['users']!.add(u.toMap());
      }
      return;
    }
    await db.insert('users', u.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _open();
    if (db == null) {
      _mem['settings']!.removeWhere((e) => e['key'] == key);
      _mem['settings']!.add({'key': key, 'value': value});
      return;
    }
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await _open();
    if (db == null) {
      final i = _mem['settings']!.indexWhere((e) => e['key'] == key);
      return i >= 0 ? '${_mem['settings']![i]['value']}' : null;
    }
    final rows =
        await db.query('settings', where: 'key=?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return '${rows.first['value']}';
  }

  // ---------- Pending Sync Queue (UC 9.x) ----------
  Future<void> enqueueSync(String op, Map<String, dynamic> payload) async {
    final row = {
      'op': op,
      'playlistId': payload['playlistId'],
      'songId': payload['songId'],
      'fav': payload['fav'],
      'payload': payload['payload']?.toString(),
      'status': 'pending',
      'retries': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    final db = await _open();
    if (db == null) {
      _mem.putIfAbsent('pending_sync', () => []);
      _mem['pending_sync']!.add({'id': _autoId++, ...row});
      return;
    }
    await db.insert('pending_sync', row);
  }

  Future<List<Map<String, dynamic>>> getPendingSync({int limit = 50}) async {
    final db = await _open();
    if (db == null) {
      return (_mem['pending_sync'] ?? [])
          .where((e) => (e['status'] ?? 'pending') == 'pending')
          .take(limit)
          .toList();
    }
    return db.query('pending_sync',
        where: 'status=?', whereArgs: ['pending'], orderBy: 'createdAt ASC', limit: limit);
  }

  Future<void> markSyncDone(int id) async {
    final db = await _open();
    if (db == null) {
      _mem['pending_sync']?.removeWhere((e) => e['id'] == id);
      return;
    }
    await db.update('pending_sync', {'status': 'synced'}, where: 'id=?', whereArgs: [id]);
  }

  Future<void> markSyncFailed(int id) async {
    final db = await _open();
    if (db == null) {
      final i = (_mem['pending_sync'] ?? []).indexWhere((e) => e['id'] == id);
      if (i >= 0) _mem['pending_sync']![i]['status'] = 'failed';
      return;
    }
    await db.update('pending_sync', {'status': 'failed'}, where: 'id=?', whereArgs: [id]);
  }

  Future<void> bumpSyncRetry(int id, int retries) async {
    final db = await _open();
    if (db == null) {
      final i = (_mem['pending_sync'] ?? []).indexWhere((e) => e['id'] == id);
      if (i >= 0) _mem['pending_sync']![i]['retries'] = retries;
      return;
    }
    await db.update('pending_sync', {'retries': retries}, where: 'id=?', whereArgs: [id]);
  }
}
