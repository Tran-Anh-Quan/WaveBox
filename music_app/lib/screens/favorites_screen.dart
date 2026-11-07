import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_database.dart';
import '../models/song.dart';
import '../player/player_controller.dart';
import '../widgets/ui_kit.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});
  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final AppDatabase _db = AppDatabase();
  List<Song> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _items = await _db.getFavorites();
    if (mounted) setState(() {});
  }

  Future<void> _unfav(Song s) async {
    await _db.toggleFavorite(s, false);
    await _db.enqueueSync(
        'TOGGLE_FAVORITE', {'songId': s.id, 'fav': 0, 'payload': s.title});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yêu thích${_items.isEmpty ? '' : ' (${_items.length})'}')),
      body: _items.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Chưa có bài yêu thích',
              subtitle: 'Nhấn biểu tượng tim ở bất kỳ bài hát nào để lưu lại.',
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final s = _items[i];
                return Dismissible(
                  key: ValueKey('fav_${s.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(20)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.heart_broken_rounded, color: Colors.white)),
                  onDismissed: (_) => _unfav(s),
                  child: SongTile(
                    song: s,
                    index: i,
                    isFav: true,
                    onPlay: () {
                      context.read<PlayerController>().setQueue(_items, startAt: i);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    },
                    onToggleFav: () => _unfav(s),
                    onDetail: () {},
                  ),
                );
              },
            ),
    );
  }
}
