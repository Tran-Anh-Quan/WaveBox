class Artist {
  final int id;
  final String name;
  final String? coverUrl;
  final String? bio;

  const Artist({required this.id, required this.name, this.coverUrl, this.bio});

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'coverUrl': coverUrl, 'bio': bio};

  factory Artist.fromMap(Map<String, dynamic> m) => Artist(
        id: (m['id'] as num).toInt(),
        name: (m['name'] ?? '') as String,
        coverUrl: m['coverUrl'] as String?,
        bio: m['bio'] as String?,
      );
}

class Album {
  final int id;
  final String title;
  final int? artistId;
  final String artistName;
  final String? coverUrl;
  final int? releaseYear;

  const Album({
    required this.id,
    required this.title,
    this.artistId,
    this.artistName = '',
    this.coverUrl,
    this.releaseYear,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artistId': artistId,
        'artistName': artistName,
        'coverUrl': coverUrl,
        'releaseYear': releaseYear,
      };

  factory Album.fromMap(Map<String, dynamic> m) => Album(
        id: (m['id'] as num).toInt(),
        title: (m['title'] ?? '') as String,
        artistId: (m['artistId'] as num?)?.toInt(),
        artistName: (m['artistName'] ?? '') as String,
        coverUrl: m['coverUrl'] as String?,
        releaseYear: (m['releaseYear'] as num?)?.toInt(),
      );
}

class Genre {
  final int id;
  final String name;
  final String? coverUrl;

  const Genre({required this.id, required this.name, this.coverUrl});

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'coverUrl': coverUrl};

  factory Genre.fromMap(Map<String, dynamic> m) => Genre(
        id: (m['id'] as num).toInt(),
        name: (m['name'] ?? '') as String,
        coverUrl: m['coverUrl'] as String?,
      );

  static List<Genre> defaults() => const [
        Genre(id: 1, name: 'Pop'),
        Genre(id: 2, name: 'Ballad'),
        Genre(id: 3, name: 'Indie'),
        Genre(id: 4, name: 'EDM'),
        Genre(id: 5, name: 'Rock'),
        Genre(id: 6, name: 'Lo-Fi'),
      ];
}

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int lastSyncAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.lastSyncAt = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'lastSyncAt': lastSyncAt,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: '${m['id']}',
        email: (m['email'] ?? '') as String,
        displayName: (m['displayName'] ?? '') as String,
        photoUrl: m['photoUrl'] as String?,
        lastSyncAt: (m['lastSyncAt'] as num?)?.toInt() ?? 0,
      );
}
