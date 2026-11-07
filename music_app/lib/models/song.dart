class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String data; // file path or stream URL
  final int durationMs;
  final String? artUri;
  final bool isOnline;

  // --- v3 mở rộng: mapping UC 1.3 / 2.4 / 7.x ---
  final int? artistId;
  final int? albumId;
  final int? genreId;
  final int fileSize; // bytes, UC 1.3
  final String? format; // mp3/wav/m4a/flac, UC 1.1
  final bool isDownloaded; // UC 1.2 / 7.5
  final int playCount; // UC 7.1 trending
  final int updatedAt;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.data,
    required this.durationMs,
    this.artUri,
    this.isOnline = false,
    this.artistId,
    this.albumId,
    this.genreId,
    this.fileSize = 0,
    this.format,
    this.isDownloaded = false,
    this.playCount = 0,
    this.updatedAt = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'data': data,
        'durationMs': durationMs,
        'artUri': artUri,
        'isOnline': isOnline ? 1 : 0,
        'artistId': artistId,
        'albumId': albumId,
        'genreId': genreId,
        'fileSize': fileSize,
        'format': format,
        'isDownloaded': isDownloaded ? 1 : 0,
        'playCount': playCount,
        'updatedAt': updatedAt,
      };

  /// Map cho bảng songs_cache (khóa chính id, cột title/artist/...).
  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'artistId': artistId,
        'album': album,
        'albumId': albumId,
        'genreId': genreId,
        'data': data,
        'durationMs': durationMs,
        'artUri': artUri,
        'fileSize': fileSize,
        'format': format,
        'isOnline': isOnline ? 1 : 0,
        'isDownloaded': isDownloaded ? 1 : 0,
        'playCount': playCount,
        'updatedAt': updatedAt == 0
            ? DateTime.now().millisecondsSinceEpoch
            : updatedAt,
      };

  factory Song.fromMap(Map<String, dynamic> m) => Song(
        id: (m['id'] as num).toInt(),
        title: (m['title'] ?? 'Unknown') as String,
        artist: (m['artist'] ?? 'Unknown Artist') as String,
        album: (m['album'] ?? 'Unknown Album') as String,
        data: (m['data'] ?? '') as String,
        durationMs: (m['durationMs'] as num?)?.toInt() ?? 0,
        artUri: m['artUri'] as String?,
        isOnline: ((m['isOnline'] as num?)?.toInt() ?? 0) == 1,
        artistId: (m['artistId'] as num?)?.toInt(),
        albumId: (m['albumId'] as num?)?.toInt(),
        genreId: (m['genreId'] as num?)?.toInt(),
        fileSize: (m['fileSize'] as num?)?.toInt() ?? 0,
        format: m['format'] as String?,
        isDownloaded: ((m['isDownloaded'] as num?)?.toInt() ?? 0) == 1,
        playCount: (m['playCount'] as num?)?.toInt() ?? 0,
        updatedAt: (m['updatedAt'] as num?)?.toInt() ?? 0,
      );

  Song copyWith({
    String? title,
    String? artist,
    String? album,
    bool? isDownloaded,
    int? playCount,
    String? artUri,
    int? genreId,
    int? artistId,
    int? albumId,
    int? fileSize,
    String? format,
  }) =>
      Song(
        id: id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        data: data,
        durationMs: durationMs,
        artUri: artUri ?? this.artUri,
        isOnline: isOnline,
        artistId: artistId ?? this.artistId,
        albumId: albumId ?? this.albumId,
        genreId: genreId ?? this.genreId,
        fileSize: fileSize ?? this.fileSize,
        format: format ?? this.format,
        isDownloaded: isDownloaded ?? this.isDownloaded,
        playCount: playCount ?? this.playCount,
        updatedAt: updatedAt,
      );
}
