class Playlist {
  final int? id;
  final String name;
  final int createdAt;
  // --- v3: đồng bộ đa thiết bị (UC 9.1) ---
  final String? uuid;
  final String description;
  final String? coverUrl;
  final String? ownerId;
  final int updatedAt;
  final bool isSynced;

  const Playlist({
    this.id,
    required this.name,
    required this.createdAt,
    this.uuid,
    this.description = '',
    this.coverUrl,
    this.ownerId,
    this.updatedAt = 0,
    this.isSynced = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'uuid': uuid,
        'description': description,
        'coverUrl': coverUrl,
        'ownerId': ownerId,
        'updatedAt': updatedAt == 0 ? createdAt : updatedAt,
        'isSynced': isSynced ? 1 : 0,
      };

  factory Playlist.fromMap(Map<String, dynamic> m) => Playlist(
        id: (m['id'] as num?)?.toInt(),
        name: (m['name'] ?? '') as String,
        createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
        uuid: m['uuid'] as String?,
        description: (m['description'] ?? '') as String,
        coverUrl: m['coverUrl'] as String?,
        ownerId: m['ownerId'] as String?,
        updatedAt: (m['updatedAt'] as num?)?.toInt() ??
            ((m['createdAt'] as num?)?.toInt() ?? 0),
        isSynced: ((m['isSynced'] as num?)?.toInt() ?? 1) == 1,
      );
}
