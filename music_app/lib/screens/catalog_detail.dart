import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/song.dart';
import '../player/player_controller.dart';
import '../widgets/ui_kit.dart';
import 'player_screen.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String album;
  final List<Song> songs;
  const AlbumDetailScreen({super.key, required this.album, required this.songs});

  @override
  Widget build(BuildContext context) {
    final first = songs.isNotEmpty ? songs.first : null;
    return Scaffold(
      appBar: AppBar(title: Text(album, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GradientHeaderCard(
            icon: Icons.album_rounded,
            title: album,
            subtitle:
                '${first?.artist ?? ''}${first?.artist?.isNotEmpty == true ? '  •  ' : ''}${songs.length} bài',
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 46),
              tooltip: songs.isEmpty ? 'Trống' : 'Phát album',
              onPressed: songs.isEmpty
                  ? null
                  : () {
                      context.read<PlayerController>().setQueue(songs, startAt: 0);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    },
            ),
          ),
          if (songs.isEmpty)
            const EmptyState(icon: Icons.album_outlined, title: 'Album trống')
          else
            for (var i = 0; i < songs.length; i++)
              SongTile(
                song: songs[i],
                index: i,
                isFav: false,
                onPlay: () {
                  context.read<PlayerController>().setQueue(songs, startAt: i);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()));
                },
                onToggleFav: () {},
                onDetail: () {},
              ),
        ],
      ),
    );
  }
}

class ArtistDetailScreen extends StatelessWidget {
  final String artist;
  final List<Song> songs;
  const ArtistDetailScreen({super.key, required this.artist, required this.songs});

  @override
  Widget build(BuildContext context) {
    final albums = <String>{for (final s in songs) s.album}.length;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(artist, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.gradientBox(radius: AppTheme.rXl),
            child: Row(
              children: [
                const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.mic_rounded, color: Colors.white, size: 32)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(artist,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text('$albums album  •  ${songs.length} bài',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 46),
                  tooltip: songs.isEmpty ? 'Trống' : 'Phát tuyển tập',
                  onPressed: songs.isEmpty
                      ? null
                      : () {
                          context.read<PlayerController>().setQueue(songs, startAt: 0);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const PlayerScreen()));
                        },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text('Tác phẩm tiêu biểu',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: dark ? Colors.white : Colors.black87)),
          ),
          if (songs.isEmpty)
            const EmptyState(icon: Icons.mic_outlined, title: 'Chưa có tác phẩm')
          else
            for (var i = 0; i < songs.length; i++)
              SongTile(
                song: songs[i],
                index: i,
                isFav: false,
                onPlay: () {
                  context.read<PlayerController>().setQueue(songs, startAt: i);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PlayerScreen()));
                },
                onToggleFav: () {},
                onDetail: () {},
              ),
        ],
      ),
    );
  }
}
