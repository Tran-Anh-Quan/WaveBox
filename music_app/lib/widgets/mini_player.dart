import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../player/player_controller.dart';
import 'ui_kit.dart';

String fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Mini player: card nổi, artwork gradient, progress mảnh.
class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;
  const MiniPlayer({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<PlayerController>();
    final s = pc.current;
    if (s == null) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final total = pc.duration.inMilliseconds;
    final pos = total == 0
        ? 0.0
        : pc.position.inMilliseconds.clamp(0, total).toDouble() /
            total.toDouble();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: AppTheme.softCard(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.rLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
                child: Row(
                  children: [
                    const GradientArt(size: 48, radius: 14, iconSize: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: Text(s.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: dark
                                            ? Colors.white.withOpacity(0.6)
                                            : Colors.black54)),
                              ),
                              const SizedBox(width: 6),
                              SourcePill(isOnline: s.isOnline),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: AppTheme.gradientBox(radius: 999),
                      child: IconButton(
                        icon: Icon(
                            pc.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white),
                        tooltip: pc.playing ? 'Tạm dừng' : 'Phát',
                        onPressed: pc.toggle,
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        tooltip: 'Bài tiếp theo',
                        onPressed: pc.next),
                  ],
                ),
              ),
              SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Container(
                        color: dark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.08)),
                    FractionallySizedBox(
                      widthFactor: pos.clamp(0.0, 1.0),
                      child: Container(
                        decoration: const BoxDecoration(
                            gradient: AppTheme.brandGradient),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
