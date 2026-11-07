import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../data/app_database.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../player/player_controller.dart';
import '../widgets/ui_kit.dart';
import 'player_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  final List<Song> allSongs;
  const PlaylistsScreen({super.key, required this.allSongs});
  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final AppDatabase _db = AppDatabase();
  List<Playlist> _lists = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _lists = await _db.getPlaylists();
    if (mounted) setState(() {});
  }

  Future<void> _create() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Playlist mới'),
        content: TextField(
            controller: c,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Ví dụ: Nhạc chill buổi tối')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, c.text.trim()),
              child: const Text('Tạo')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final id = await _db.insertPlaylist(name);
      await _db.enqueueSync('CREATE_PLAYLIST', {'playlistId': id, 'payload': name});
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Playlist của tôi${_lists.isEmpty ? '' : ' (${_lists.length})'}')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Playlist mới')),
      body: _lists.isEmpty
          ? EmptyState(
              icon: Icons.queue_music_rounded,
              title: 'Chưa có playlist nào',
              subtitle: 'Tạo playlist đầu tiên để gom nhạc theo tâm trạng.',
              actionLabel: 'Tạo playlist',
              onAction: _create,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 96),
              itemCount: _lists.length,
              itemBuilder: (_, i) {
                final p = _lists[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: AppTheme.softCard(context),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    leading: const GradientArt(size: 52, radius: 15, icon: Icons.queue_music_rounded, iconSize: 26),
                    title: Text(p.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                          '${_fmtDate(p.createdAt)}${p.isSynced ? '' : '  •  Chờ đồng bộ'}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.55)
                                  : Colors.black54)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Đổi tên',
                          onPressed: () => _rename(p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20),
                          tooltip: 'Xóa',
                          onPressed: () => _confirmDelete(p),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailScreen(playlist: p, allSongs: widget.allSongs),
                      ),
                    ).then((_) => _load()),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _rename(Playlist p) async {
    final c = TextEditingController(text: p.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đổi tên playlist'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'Tên mới')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Lưu')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && p.id != null) {
      await _db.renamePlaylist(p.id!, name);
      await _db.enqueueSync('RENAME_PLAYLIST', {'playlistId': p.id, 'payload': name});
      _load();
    }
  }

  Future<void> _confirmDelete(Playlist p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa playlist?'),
        content: Text('Xóa "${p.name}" khỏi thư viện? Bài hát gốc vẫn giữ nguyên.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true && p.id != null) {
      await _db.deletePlaylist(p.id!);
      await _db.enqueueSync('DELETE_PLAYLIST', {'playlistId': p.id});
      _load();
    }
  }

  String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day}/${d.month}/${d.year}';
  }
}

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;
  final List<Song> allSongs;
  const PlaylistDetailScreen({super.key, required this.playlist, required this.allSongs});
  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final AppDatabase _db = AppDatabase();
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _songs = await _db.getPlaylistSongs(widget.playlist.id ?? -1);
    if (mounted) setState(() {});
  }

  Future<void> _addSongs() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, ctrl) {
          if (widget.allSongs.isEmpty) {
            return const EmptyState(icon: Icons.music_off_outlined, title: 'Chưa có bài hát nào');
          }
          return ListView.builder(
            controller: ctrl,
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: widget.allSongs.length,
            itemBuilder: (_, i) {
              final s = widget.allSongs[i];
              final added = _songs.any((e) => e.id == s.id);
              return ListTile(
                leading: GradientArt(size: 44, radius: 12, iconSize: 20),
                title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(s.artist, maxLines: 1),
                trailing: added
                    ? const Icon(Icons.check_circle_rounded, color: Colors.greenAccent)
                    : const Icon(Icons.add_circle_outline_rounded),
                onTap: added
                    ? null
                    : () async {
                        await _db.addToPlaylist(widget.playlist.id ?? -1, s);
                        await _db.enqueueSync('ADD_TO_PLAYLIST',
                            {'playlistId': widget.playlist.id, 'songId': s.id});
                        _load();
                        if (mounted) Navigator.pop(context);
                      },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSongs,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm bài'),
      ),
      body: Column(
        children: [
          GradientHeaderCard(
            icon: Icons.queue_music_rounded,
            title: widget.playlist.name,
            subtitle: '${_songs.length} bài hát',
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 46),
              tooltip: _songs.isEmpty ? 'Playlist trống' : 'Phát playlist',
              onPressed: _songs.isEmpty
                  ? null
                  : () {
                      context.read<PlayerController>().setQueue(_songs, startAt: 0);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    },
            ),
          ),
          Expanded(
            child: _songs.isEmpty
                ? EmptyState(
                    icon: Icons.music_note_outlined,
                    title: 'Playlist trống',
                    subtitle: 'Thêm bài hát yêu thích vào playlist này.',
                    actionLabel: 'Thêm bài',
                    onAction: _addSongs,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: _songs.length,
                    itemBuilder: (_, i) {
                      final s = _songs[i];
                      return Dismissible(
                        key: ValueKey('${s.id}_$i'),
                        background: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_rounded, color: Colors.white)),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) async {
                          await _db.removeFromPlaylist(widget.playlist.id ?? -1, s.id);
                          await _db.enqueueSync('REMOVE_FROM_PLAYLIST',
                              {'playlistId': widget.playlist.id, 'songId': s.id});
                          _load();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: AppTheme.softCard(context),
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            leading: Text('${i + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(s.artist, maxLines: 1),
                            trailing: const Icon(Icons.drag_handle_rounded, size: 18),
                            onTap: () {
                              context.read<PlayerController>().setQueue(_songs, startAt: i);
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const PlayerScreen()));
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
