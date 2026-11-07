import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_service.dart';
import '../core/theme/app_theme.dart';
import '../data/app_database.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/viewmodel/auth_viewmodel.dart';
import '../features/library/data/song_repository.dart';
import '../features/sync/data/sync_service.dart';
import '../models/catalog.dart';
import '../models/song.dart';
import '../player/player_controller.dart';
import '../services/download_service.dart';
import '../services/library_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/ui_kit.dart';
import 'catalog_detail.dart';
import 'favorites_screen.dart';
import 'player_screen.dart';
import 'playlists_screen.dart';
import 'search_screen.dart';
import 'video_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool dark;
  final VoidCallback? onToggleTheme;
  const HomeScreen({super.key, this.dark = true, this.onToggleTheme});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _nav = 0;
  final LibraryService _lib = LibraryService();
  final AppDatabase _db = AppDatabase();
  List<Song> _deviceSongs = [];
  List<Song> _picked = [];
  List<Song> _onlineSongs = [];
  Set<int> _favIds = {};
  List<Genre> _genres = [];
  int? _genreFilter;
  bool _loading = true;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _refresh();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOnline());
  }

  Future<void> _fetchOnline() async {
    try {
      final api = context.read<ApiClient>();
      final repo = SongRepository(local: _lib, db: _db, api: api);
      final raw = await repo.fetchOnlineSongs().timeout(const Duration(seconds: 6));
      if (raw.isEmpty) return;
      final mapped = <Song>[];
      var i = 0;
      for (final e in raw) {
        if (e is! Map) continue;
        i++;
        mapped.add(Song(
          id: (e['id'] as num?)?.toInt() ?? (910000 + i),
          title: '${e['title'] ?? 'Bài online $i'}',
          artist: '${(e['artist'] is Map ? e['artist']['name'] : e['artist']) ?? 'Unknown Artist'}',
          album: '${(e['album'] is Map ? e['album']['title'] : e['album']) ?? ''}',
          data: '${e['streamUrl'] ?? e['url'] ?? ''}',
          durationMs: (e['durationMs'] as num?)?.toInt() ?? 0,
          artUri: e['coverUrl'] as String?,
          isOnline: true,
          genreId: (e['genreId'] as num?)?.toInt() ?? ((910000 + i) % 6) + 1,
          format: 'mp3',
        ));
      }
      final valid = mapped.where((s) => s.data.isNotEmpty).toList();
      if (valid.isEmpty) return;
      await _db.upsertSongsCache(valid);
      if (mounted) setState(() => _onlineSongs = valid);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _status = 'Đang quét thư viện...';
    });
    await _db.seedGenresIfEmpty();
    final songs = await _lib.loadDeviceSongs();
    final favs = await _db.getFavoriteIds();
    final genres = await _db.getGenres();
    await _db.upsertSongsCache([...songs, ...LibraryService.sampleTracks]);
    setState(() {
      _deviceSongs = songs;
      _favIds = favs;
      _genres = genres;
      _loading = false;
      _status = songs.isEmpty
          ? 'Chưa thấy nhạc trên máy — thử "Chọn file" hoặc nghe nhạc mẫu online.'
          : 'Tìm thấy ${songs.length} bài trên thiết bị';
    });
  }

  List<Song> get _all =>
      [..._picked, ..._deviceSongs, ..._onlineSongs, ...LibraryService.sampleTracks];

  List<Song> get _localOnly => [..._picked, ..._deviceSongs];

  List<Song> get _filtered {
    final base = _localOnly;
    if (_genreFilter == null) return [...base, ..._onlineSongs, ...LibraryService.sampleTracks];
    return _all.where((s) => s.genreId == _genreFilter).toList();
  }

  List<Song> get _filteredLocal {
    if (_genreFilter == null) return _localOnly;
    return _localOnly.where((s) => s.genreId == _genreFilter).toList();
  }

  Map<String, List<Song>> get _byArtist {
    final m = <String, List<Song>>{};
    for (final s in _all) {
      m.putIfAbsent(s.artist, () => []).add(s);
    }
    return m;
  }

  Map<String, List<Song>> get _byAlbum {
    final m = <String, List<Song>>{};
    for (final s in _all) {
      m.putIfAbsent(s.album, () => []).add(s);
    }
    return m;
  }

  Future<void> _pickFiles() async {
    final songs = await _lib.pickAudioFiles();
    if (songs.isNotEmpty) {
      await _db.upsertSongsCache(songs);
      setState(() => _picked = [...songs, ..._picked]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã thêm ${songs.length} bài vào thư viện')));
      }
    }
  }

  Future<void> _toggleFav(Song s) async {
    final fav = !_favIds.contains(s.id);
    await _db.toggleFavorite(s, fav);
    await _db.enqueueSync('TOGGLE_FAVORITE',
        {'songId': s.id, 'fav': fav ? 1 : 0, 'payload': s.title});
    if (!mounted) return;
    setState(() {
      if (fav) {
        _favIds.add(s.id);
      } else {
        _favIds.remove(s.id);
      }
    });
  }

  void _openDetail(Song s) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongDetailScreen(
          song: s,
          isFavorite: _favIds.contains(s.id),
          onToggleFavorite: () => _toggleFav(s),
        ),
      ),
    );
    if (result == 'downloaded' || result == 'deleted') _refresh();
  }

  Future<void> _deleteLocalFile(Song s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa khỏi thiết bị?'),
        content: Text('Xóa "${s.title}" để giải phóng bộ nhớ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DownloadService(db: _db).deleteDownload(s);
      if (!s.isOnline) {
        try {
          final f = File(s.data);
          if (await f.exists()) {
            final parent = f.parent.path;
            if (parent.contains('files') || parent.contains('app_') || parent.contains('Picked')) {
              await f.delete();
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    setState(() {
      _picked.removeWhere((e) => e.id == s.id);
      _deviceSongs.removeWhere((e) => e.id == s.id);
    });
    await _db.upsertSongsCache([s.copyWith(isDownloaded: false)]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bản tải để giải phóng bộ nhớ')));
    }
    _refresh();
  }

  void _playList(List<Song> list, int i) {
    context.read<PlayerController>().setQueue(list, startAt: i);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: dark
              ? AppTheme.headerGradient
              : const LinearGradient(
                  colors: [Color(0xFFEDE9FE), Color(0xFFF6F3FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                  index: _nav,
                  children: [
                    _homeTab(),
                    _libraryTab(),
                    _playlistEntry(),
                    _meTab(),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlayerScreen())),
          ),
          NavigationBar(
            selectedIndex: _nav,
            onDestinationSelected: (i) {
              if (i == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PlaylistsScreen(allSongs: _all)),
                ).then((_) => _refresh());
                return;
              }
              setState(() => _nav = i);
            },
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Khám phá'),
              NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: 'Thư viện'),
              NavigationDestination(
                  icon: Icon(Icons.queue_music_outlined),
                  selectedIcon: Icon(Icons.queue_music),
                  label: 'Playlist'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Cá nhân'),
            ],
          ),
        ],
      ),
      floatingActionButton: _nav == 1
          ? FloatingActionButton.extended(
              onPressed: _pickFiles,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Chọn file'),
            )
          : null,
    );
  }

  Widget _homeTab() {
    final trending = [..._all].take(6).toList();
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header()),
        SliverToBoxAdapter(child: _searchBar()),
        SliverToBoxAdapter(child: _genreChips()),
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Thịnh hành',
            subtitle: 'Bảng xếp hạng và gợi ý dành cho bạn',
            onSeeAll: () => setState(() => _nav = 1),
          ),
        ),
        SliverToBoxAdapter(child: _trendingList(trending)),
        SliverToBoxAdapter(
          child: const SectionHeader(
            title: 'Mới phát hành',
            subtitle: 'Khám phá theo chủ đề',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 196,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final s = _filtered[i % _filtered.length];
                return _songCard(s, i);
              },
              childCount: _filtered.isEmpty ? 0 : 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hour = DateTime.now().hour;
    final greet = hour < 11
        ? 'Chào buổi sáng'
        : hour < 14
            ? 'Chào buổi trưa'
            : hour < 18
                ? 'Chào buổi chiều'
                : 'Chào buổi tối';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          const GradientArt(size: 48, radius: 16, icon: Icons.graphic_eq_rounded, iconSize: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WAVEBOX',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        fontSize: 12,
                        color: Color(0xFFA78BFA))),
                Text('$greet, nghe gì nào?',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Tài khoản',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ).then((_) => _refresh());
            },
          ),
          IconButton(
            icon: Icon(widget.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            tooltip: 'Đổi giao diện sáng/tối',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Quét lại thư viện',
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SearchScreen(songs: _all)),
        ),
        child: const IgnorePointer(
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Bài hát, nghệ sĩ, album...',
              suffixIcon: Icon(Icons.mic_outlined),
            ),
          ),
        ),
      ),
    );
  }

  Widget _genreChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _chip('Tất cả', _genreFilter == null, () {
            setState(() => _genreFilter = null);
          }),
          for (final g in _genres)
            _chip(g.name, _genreFilter == g.id, () {
              setState(() => _genreFilter = g.id);
            }),
          _chip('Video MP4', false, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const VideoScreen()));
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _trendingList(List<Song> songs) {
    if (songs.isEmpty) {
      return EmptyState(icon: Icons.music_off_outlined, title: 'Chưa có nhạc', subtitle: _status);
    }
    return SizedBox(
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _songCard(songs[i], i, width: 156),
      ),
    );
  }

  Widget _songCard(Song s, int i, {double width = double.infinity}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fav = _favIds.contains(s.id);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _playList(_filtered.isEmpty ? _all : _filtered,
          i % (_filtered.isEmpty ? _all.length : _filtered.length)),
      child: Container(
        width: width == double.infinity ? null : width,
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.softCard(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              decoration: AppTheme.gradientBox(radius: 14),
              child: Stack(
                children: [
                  const Center(
                      child: Icon(Icons.music_note_rounded, color: Colors.white, size: 40)),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(999)),
                      child: Text('#${i + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: InkWell(
                      onTap: () => _toggleFav(s),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                        child: Icon(
                            fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: fav ? Colors.pinkAccent : Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(s.title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${s.artist} • ${s.album}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    color: dark ? Colors.white.withOpacity(0.55) : Colors.black54)),
            const SizedBox(height: 4),
            SourcePill(isOnline: s.isOnline, isDownloaded: s.isDownloaded),
          ],
        ),
      ),
    );
  }

  Widget _libraryTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const TabBar(isScrollable: true, tabs: [
            Tab(text: 'Bài hát máy'),
            Tab(text: 'Đã tải'),
            Tab(text: 'Nghệ sĩ'),
            Tab(text: 'Album'),
          ]),
          Expanded(
            child: TabBarView(
              children: [
                _songListView(_filteredLocal, showDeleteLocal: true),
                _downloadedTab(),
                _groupList(_byArtist, 'nghệ sĩ', isArtist: true),
                _groupList(_byAlbum, 'album', isArtist: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _downloadedTab() {
    return FutureBuilder(
      future: _db.getDownloadedSongs(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.download_outlined,
            title: 'Chưa có bản tải nào',
            subtitle: 'Mở chi tiết bài hát rồi chọn Tải về máy để nghe offline.',
          );
        }
        return _songListView(items, showDeleteLocal: true);
      },
    );
  }

  Widget _songListView(List<Song> list, {bool showDeleteLocal = false}) {
    if (list.isEmpty) {
      return EmptyState(icon: Icons.music_note_outlined, title: 'Chưa có bài hát', subtitle: _status);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final s = list[i];
        return SongTile(
          song: s,
          index: i,
          isFav: _favIds.contains(s.id),
          onPlay: () => _playList(list, i),
          onToggleFav: () => _toggleFav(s),
          onDetail: () => _openDetail(s),
          onDelete: () => _deleteLocalFile(s),
          showDelete: showDeleteLocal,
        );
      },
    );
  }

  Widget _groupList(Map<String, List<Song>> groups, String label, {bool isArtist = false}) {
    if (groups.isEmpty) {
      return EmptyState(icon: Icons.album_outlined, title: 'Chưa có $label');
    }
    final keys = groups.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: keys.length,
      itemBuilder: (_, i) {
        final k = keys[i];
        final songs = groups[k]!;
        return MenuCard(
          icon: isArtist ? Icons.mic_outlined : Icons.album_outlined,
          title: k,
          subtitle: '${songs.length} bài',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => isArtist
                    ? ArtistDetailScreen(artist: k, songs: songs)
                    : AlbumDetailScreen(album: k, songs: songs),
              ),
            );
          },
        );
      },
    );
  }

  Widget _playlistEntry() => const SizedBox.shrink();

  Widget _meTab() {
    final auth = context.watch<AuthViewModel>();
    final online = context.watch<ConnectivityService>().isOnline;
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      children: [
        GradientHeaderCard(
          icon: Icons.person_rounded,
          title: auth.isLoggedIn
              ? (auth.displayName ?? auth.email ?? 'Người dùng')
              : 'Khách nghe nhạc',
          subtitle: auth.isLoggedIn
              ? '${auth.email ?? ''} • ${online ? 'Đang online' : 'Đang offline'}'
              : 'Đăng nhập để đồng bộ playlist và yêu thích',
          trailing: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              (auth.displayName?.isNotEmpty == true
                      ? auth.displayName![0]
                      : (auth.email?.isNotEmpty == true ? auth.email![0] : '?'))
                  .toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ),
        ),
        if (!auth.isLoggedIn)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ).then((_) => _refresh());
              },
              icon: const Icon(Icons.login_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Đăng nhập / Đăng ký'),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final c = TextEditingController(text: auth.displayName ?? '');
                      final name = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cập nhật hồ sơ'),
                          content: TextField(
                              controller: c,
                              decoration: const InputDecoration(labelText: 'Tên hiển thị')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                            FilledButton(
                                onPressed: () => Navigator.pop(context, c.text.trim()),
                                child: const Text('Lưu')),
                          ],
                        ),
                      );
                      if (name != null && name.isNotEmpty) {
                        await auth.updateProfile(name);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã cập nhật hồ sơ')));
                        }
                        _refresh();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Sửa hồ sơ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã đăng xuất')));
                      }
                      _refresh();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Đăng xuất'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        if (auth.isLoggedIn) ...[
          MenuCard(
            icon: Icons.cloud_sync_outlined,
            title: 'Đồng bộ ngay',
            subtitle: 'Đẩy playlist, yêu thích và lịch sử đang chờ',
            trailing: const Icon(Icons.sync_rounded, size: 20),
            onTap: () async {
              final n = await context.read<SyncService>().syncNow();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Đã đồng bộ $n thao tác')));
              }
              _refresh();
            },
          ),
          MenuCard(
            icon: Icons.cloud_download_outlined,
            title: 'Khôi phục từ đám mây',
            subtitle: 'Tải lại dữ liệu khi đổi máy',
            onTap: () async {
              final ok = await context.read<SyncService>().restoreFromCloud();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'Đã khôi phục dữ liệu cá nhân'
                        : 'Không khôi phục được, kiểm tra mạng')));
              }
              _refresh();
            },
          ),
        ],
        MenuCard(
          icon: Icons.playlist_play_rounded,
          title: 'Playlist của tôi',
          subtitle: 'Tạo, sửa và sắp xếp playlist',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlaylistsScreen(allSongs: _all)),
          ).then((_) => _refresh()),
        ),
        FutureBuilder(
          future: _db.getHistoryRows(),
          builder: (context, snap) {
            final rows = snap.data ?? [];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: AppTheme.softCard(context),
              child: ExpansionTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.history_rounded, color: Color(0xFFA78BFA)),
                ),
                title: const Text('Nghe gần đây',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('${rows.length} bài',
                    style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                  tooltip: 'Xóa toàn bộ lịch sử',
                  onPressed: () async {
                    await _db.clearHistory();
                    setState(() {});
                  },
                ),
                children: [
                  for (var i = 0; i < rows.length && i < 10; i++)
                    Builder(builder: (_) {
                      final m = rows[i];
                      final s = Song(
                        id: (m['songId'] as num).toInt(),
                        title: '${m['songTitle'] ?? 'Unknown'}',
                        artist: '${m['songArtist'] ?? 'Unknown Artist'}',
                        album: '${m['songAlbum'] ?? ''}',
                        data: '${m['songData'] ?? ''}',
                        durationMs: (m['songDuration'] as num?)?.toInt() ?? 0,
                      );
                      return Dismissible(
                        key: ValueKey('his_${m['id']}_$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                            color: Colors.redAccent,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_rounded, color: Colors.white)),
                        onDismissed: (_) async {
                          await _db.deleteHistoryItem((m['id'] as num).toInt());
                          setState(() {});
                        },
                        child: ListTile(
                          dense: true,
                          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(s.artist, maxLines: 1),
                          onTap: () => _playList([s], 0),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
        FutureBuilder(
          future: _db.getFavorites(),
          builder: (context, snap) {
            final items = snap.data ?? [];
            return MenuCard(
              icon: Icons.favorite_rounded,
              iconColor: Colors.pinkAccent,
              title: 'Bài hát yêu thích',
              subtitle: '${items.length} bài',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ).then((_) => _refresh()),
            );
          },
        ),
        FutureBuilder(
          future: _db.getDownloads(),
          builder: (context, snap) {
            final items = snap.data ?? [];
            return MenuCard(
              icon: Icons.download_done_rounded,
              iconColor: Colors.green,
              title: 'Nhạc đã tải',
              subtitle: '${items.length} bản tải offline',
              onTap: () async {
                final songs = await _db.getDownloadedSongs();
                if (!context.mounted) return;
                if (songs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chưa có bản tải nào')));
                  return;
                }
                _playList(songs, 0);
              },
            );
          },
        ),
      ],
    );
  }
}
