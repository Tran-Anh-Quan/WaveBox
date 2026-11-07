import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/song.dart';

/// Bộ component dùng chung — nguồn sự thật duy nhất cho design toàn app.
class GradientArt extends StatelessWidget {
  final double size;
  final double radius;
  final IconData icon;
  final double iconSize;
  const GradientArt(
      {super.key,
      required this.size,
      this.radius = 14,
      this.icon = Icons.music_note_rounded,
      this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppTheme.gradientBox(radius: radius),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

class SourcePill extends StatelessWidget {
  final bool isOnline;
  final bool isDownloaded;
  const SourcePill(
      {super.key, required this.isOnline, this.isDownloaded = false});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(0.09)
                : Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
                color: dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isOnline ? Icons.cloud_outlined : Icons.phone_android_rounded,
                  size: 12,
                  color: dark ? Colors.white70 : Colors.black54),
              const SizedBox(width: 4),
              Text(isOnline ? 'Online' : 'Máy',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white70 : Colors.black54)),
            ],
          ),
        ),
        if (isDownloaded)
          Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.download_done_rounded,
                size: 12, color: Colors.greenAccent),
          ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onSeeAll;
  const SectionHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.actionLabel,
      this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: TextStyle(
                            fontSize: 12,
                            color: dark
                                ? Colors.white.withOpacity(0.55)
                                : Colors.black54)),
                  ),
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel ?? 'Xem tất cả'),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon,
                  size: 34,
                  color: dark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: dark
                            ? Colors.white.withOpacity(0.55)
                            : Colors.black54)),
              ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SongTile extends StatelessWidget {
  final Song song;
  final int index;
  final bool isFav;
  final VoidCallback onPlay;
  final VoidCallback onToggleFav;
  final VoidCallback onDetail;
  final VoidCallback? onDelete;
  final bool showDelete;

  const SongTile({
    super.key,
    required this.song,
    required this.index,
    required this.isFav,
    required this.onPlay,
    required this.onToggleFav,
    required this.onDetail,
    this.onDelete,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: AppTheme.softCard(context, radius: AppTheme.rLg),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        leading: Stack(
          children: [
            GradientArt(size: 50, radius: 14, iconSize: 24),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999)),
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        title: Text(song.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${song.artist} • ${song.album}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      color: dark
                          ? Colors.white.withOpacity(0.55)
                          : Colors.black54)),
              const SizedBox(height: 4),
              SourcePill(
                  isOnline: song.isOnline,
                  isDownloaded: song.isDownloaded),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded),
              color: isFav ? Colors.pinkAccent : (dark ? Colors.white54 : Colors.black45),
              tooltip: isFav ? 'Bỏ thích' : 'Thích',
              onPressed: onToggleFav,
            ),
            IconButton(
              icon: Icon(Icons.more_vert_rounded,
                  color: dark ? Colors.white54 : Colors.black45),
              tooltip: 'Chi tiết',
              onPressed: onDetail,
            ),
            if (showDelete && !song.isOnline && onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: dark ? Colors.white54 : Colors.black45),
                tooltip: 'Xóa khỏi máy',
                onPressed: onDelete,
              ),
          ],
        ),
        onTap: onPlay,
        onLongPress: onDetail,
      ),
    );
  }
}

class GradientHeaderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final EdgeInsets margin;
  const GradientHeaderCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.trailing,
      this.margin = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.gradientBox(radius: AppTheme.rXl),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const MenuCard(
      {super.key,
      required this.icon,
      this.iconColor,
      required this.title,
      required this.subtitle,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: AppTheme.softCard(context),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF7C3AED)).withOpacity(0.14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFFA78BFA)),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.55)
                    : Colors.black54)),
        trailing: trailing ??
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black26),
        onTap: onTap,
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const DetailRow({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: dark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black54))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}
