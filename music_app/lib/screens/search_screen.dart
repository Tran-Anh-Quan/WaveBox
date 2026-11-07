import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_database.dart';
import '../models/catalog.dart';
import '../models/song.dart';
import '../player/player_controller.dart';
import '../services/download_service.dart';
import '../widgets/ui_kit.dart';
import 'player_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Song> songs;
  const SearchScreen({super.key, required this.songs});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String q = '';
  int? genreId;
  List<Genre> genres = [];
  List<Song> cacheResult = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    AppDatabase().getGenres().then((g) {
      if (mounted) setState(() => genres = g);
    });
  }

  List<Song> get _inMemory {
    final k = q.trim().toLowerCase();
    return widget.songs
        .where((s) =>
            (k.isEmpty ||
                s.title.toLowerCase().contains(k) ||
                s.artist.toLowerCase().contains(k) ||
                s.album.toLowerCase().contains(k)) &&
            (genreId == null || s.genreId == genreId))
        .toList();
  }

  Future<void> _searchCache() async {
    final r = await AppDatabase().searchCache(q, genreId: genreId);
    if (mounted) setState(() => cacheResult = r);
  }

  List<Song> _byTab(int tab) {
    final src = _inMemory;
    final k = q.trim().toLowerCase();
    switch (tab) {
      case 1:
        return src.where((s) => s.artist.toLowerCase().contains(k)).toList();
      case 2:
        return src.where((s) => s.album.toLowerCase().contains(k)).toList();
      case 3:
        return cacheResult;
      default:
        return src.where((s) => s.title.toLowerCase().contains(k) || k.isEmpty).toList();
    }
  }

  static const _tabLabels = ['Bài hát', 'Nghệ sĩ', 'Album', 'Đã lưu'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [for (final t in _tabLabels) Tab(text: t)],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Tên bài hát, nghệ sĩ, album...',
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          setState(() => q = '');
                          _searchCache();
                        },
                      ),
              ),
              onChanged: (v) {
                setState(() => q = v);
                _searchCache();
              },
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Tất cả thể loại'),
                    selected: genreId == null,
                    onSelected: (_) {
                      setState(() => genreId = null);
                      _searchCache();
                    },
                  ),
                ),
                for (final g in genres)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(g.name),
                      selected: genreId == g.id,
                      onSelected: (_) {
                        setState(() => genreId = g.id);
                        _searchCache();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [for (var t = 0; t < 4; t++) _resultList(_byTab(t), t)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultList(List<Song> res, int tab) {
    if (q.trim().isEmpty && tab != 3) {
      return const EmptyState(
        icon: Icons.search_rounded,
        title: 'Tìm nhạc bạn thích',
        subtitle: 'Nhập tên bài hát, nghệ sĩ hoặc album ở khung phía trên.',
      );
    }
    if (res.isEmpty) {
      return EmptyState(
        icon: Icons.sentiment_dissatisfied_outlined,
        title: 'Không tìm thấy kết quả',
        subtitle: 'Thử từ khóa khác hoặc bỏ lọc thể loại.',
        actionLabel: 'Xóa lọc',
        onAction: () {
          setState(() => genreId = null);
          _searchCache();
        },
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: res.length,
      itemBuilder: (_, i) {
        final s = res[i];
        return SongTile(
          song: s,
          index: i,
          isFav: false,
          onPlay: () {
            context.read<PlayerController>().setQueue(res, startAt: i);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
          },
          onToggleFav: () {},
          onDetail: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SongDetailScreen(song: s)));
          },
        );
      },
    );
  }
}
