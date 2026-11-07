import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../player/player_controller.dart';
import '../widgets/mini_player.dart';
import '../widgets/ui_kit.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 30), _tick);
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    Future.delayed(const Duration(seconds: 30), _tick);
  }

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<PlayerController>();
    final s = pc.current;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đang phát')),
        body: const EmptyState(
          icon: Icons.music_off_outlined,
          title: 'Chưa có bài nào',
          subtitle: 'Hãy chọn một bài hát để bắt đầu phát.',
        ),
      );
    }
    final total = pc.duration.inMilliseconds;
    final pos = pc.position.inMilliseconds.clamp(0, total == 0 ? 0 : total);
    final remain = pc.sleepUntil == null
        ? null
        : pc.sleepUntil!.difference(DateTime.now());
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: dark ? AppTheme.playerGradient : const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFF6F3FF)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 26)),
                    const Expanded(
                      child: Column(
                        children: [
                          Text('ĐANG PHÁT',
                              style: TextStyle(fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('Wavebox Player',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(pc.muted || pc.volume == 0
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded),
                      tooltip: pc.muted ? 'Bật tiếng' : 'Tắt tiếng',
                      onPressed: pc.toggleMute,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Hero(
                  tag: 'art_${s.id}',
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: AppTheme.gradientBox(radius: 28),
                    child: Stack(
                      children: [
                        const Center(
                            child: Icon(Icons.music_note_rounded, color: Colors.white, size: 110)),
                        if (pc.loading)
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(28)),
                            child: const Center(
                                child: CircularProgressIndicator(color: Colors.white)),
                          ),
                        Positioned(
                          left: 14,
                          top: 14,
                          child: SourcePill(isOnline: s.isOnline, isDownloaded: s.isDownloaded),
                        ),
                        Positioned(
                          right: 14,
                          top: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(999)),
                            child: Text(
                                s.format?.toUpperCase() ?? (s.isOnline ? 'STREAM' : 'LOCAL'),
                                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(s.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25)),
                const SizedBox(height: 4),
                Text('${s.artist} • ${s.album}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: dark ? Colors.white60 : Colors.black54, fontSize: 14)),
                if (s.fileSize > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        '${(s.fileSize / 1048576).toStringAsFixed(1)} MB',
                        style: TextStyle(
                            fontSize: 11, color: dark ? Colors.white38 : Colors.black38)),
                  ),
                if (pc.error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(pc.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                  ),
                const SizedBox(height: 10),
                Slider(
                  value: total == 0 ? 0 : pos.toDouble(),
                  max: (total == 0 ? 1 : total).toDouble(),
                  onChanged: (v) => pc.seek(Duration(milliseconds: v.toInt())),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fmt(pc.position),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(fmt(pc.duration),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: AppTheme.softCard(context, radius: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, size: 20),
                      Expanded(
                        child: Slider(
                          value: pc.muted ? 0 : pc.volume,
                          onChanged: (v) => pc.setVolume(v),
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _roundBtn(
                      context,
                      icon: Icons.shuffle_rounded,
                      active: pc.shuffle,
                      tooltip: 'Phát ngẫu nhiên',
                      onTap: pc.toggleShuffle,
                    ),
                    IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 42),
                        tooltip: 'Bài trước',
                        onPressed: pc.previous),
                    Container(
                      decoration: AppTheme.gradientBox(radius: 999),
                      child: IconButton(
                        icon: Icon(
                            pc.loading
                                ? Icons.hourglass_bottom_rounded
                                : (pc.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            color: Colors.white,
                            size: 42),
                        tooltip: pc.playing ? 'Tạm dừng' : 'Phát',
                        onPressed: pc.toggle,
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 42),
                        tooltip: 'Bài tiếp',
                        onPressed: pc.next),
                    _roundBtn(
                      context,
                      icon: pc.repeat == PlayRepeat.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      active: pc.repeat != PlayRepeat.off,
                      tooltip: 'Chế độ lặp',
                      onTap: pc.cycleRepeat,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _sleepDialog(context, pc),
                      icon: const Icon(Icons.bedtime_outlined, size: 18),
                      label: Text(remain == null
                          ? 'Hẹn giờ ngủ'
                          : 'Còn ${remain.inMinutes + 1} phút'),
                    ),
                    if (pc.sleepUntil != null)
                      TextButton(
                          onPressed: () => pc.setSleepTimer(null),
                          child: const Text('Hủy hẹn giờ')),
                  ],
                ),
                if (remain != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Tự dừng lúc ${_fmtTime(pc.sleepUntil!)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: dark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Danh sách chờ  •  ${pc.queue.length} bài',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pc.queue.length,
                  itemBuilder: (_, i) {
                    final q = pc.queue[i];
                    final cur = i == pc.currentIndex;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: cur
                          ? BoxDecoration(
                              gradient: AppTheme.brandGradient,
                              borderRadius: BorderRadius.circular(16),
                            )
                          : AppTheme.softCard(context, radius: 16),
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        leading: Text('${i + 1}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: cur ? Colors.white : null)),
                        title: Text(q.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: cur ? Colors.white : null)),
                        subtitle: Text(q.artist,
                            maxLines: 1,
                            style: TextStyle(
                                fontSize: 12,
                                color: cur
                                    ? Colors.white70
                                    : (dark
                                        ? Colors.white54
                                        : Colors.black54))),
                        trailing: cur
                            ? const Icon(Icons.equalizer_rounded, color: Colors.white)
                            : null,
                        onTap: () => pc.setQueue(pc.queue, startAt: i),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundBtn(BuildContext context,
      {required IconData icon, required bool active, required String tooltip, required VoidCallback onTap}) {
    return Container(
      decoration: active
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
              shape: BoxShape.circle)
          : null,
      child: IconButton(
        icon: Icon(icon,
            color: active
                ? Theme.of(context).colorScheme.primary
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54)),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _sleepDialog(BuildContext context, PlayerController pc) {
    final custom = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hẹn giờ tắt nhạc'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn nhanh', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in [15, 30, 45, 60])
                  ChoiceChip(
                    label: Text('$m phút'),
                    selected: false,
                    onSelected: (_) {
                      pc.setSleepTimer(Duration(minutes: m));
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Tùy chỉnh', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: custom,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'Nhập số phút, ví dụ 90',
                  prefixIcon: Icon(Icons.timer_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          FilledButton(
            onPressed: () {
              final m = int.tryParse(custom.text.trim());
              if (m != null && m > 0) {
                pc.setSleepTimer(Duration(minutes: m));
                Navigator.pop(context);
              }
            },
            child: const Text('Bắt đầu'),
          ),
        ],
      ),
    );
  }
}
