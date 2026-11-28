import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import '../models/song.dart';
import '../services/audio_cache_service.dart';

enum PlayRepeat { off, all, one }

/// Core audio engine: Play/Pause/Next/Previous/Seek + Shuffle/Repeat,
/// background playback, audio-focus & noisy-event handling via just_audio.
class PlayerController extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final AppDatabase _db = AppDatabase();

  List<Song> queue = [];
  int currentIndex = -1;
  bool shuffle = false;
  PlayRepeat repeat = PlayRepeat.off;
  List<int> _shuffleOrder = [];
  int _shufflePos = 0;
  Timer? _sleepTimer;
  DateTime? sleepUntil;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool playing = false;
  bool loading = false;
  String? error;
  double volume = 1.0;
  bool muted = false;

  /// Vị trí phát hiện tại, cập nhật liên tục.
  ///
  /// Tách riêng khỏi [notifyListeners] vì position thay đổi ~5 lần/giây. Nếu
  /// đưa nó vào thông báo chung, toàn bộ widget đang `watch` controller sẽ
  /// rebuild liên tục → giật hình. Widget thanh tiến độ chỉ cần lắng nghe
  /// `ValueNotifier` này.
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  /// Thời lượng bài hiện tại, cũng được tách riêng vì lý do tương tự.
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  PlayerController() {
    _posSub = _player.positionStream.listen((p) {
      position = p;
      // Chỉ thông báo cho thanh tiến độ, không rebuild cả cây widget.
      positionNotifier.value = p;
    });
    _durSub = _player.durationStream.listen((d) {
      final next = d ?? Duration.zero;
      if (next == duration) return;
      duration = next;
      durationNotifier.value = next;
      notifyListeners();
    });
    _stateSub = _player.playerStateStream.listen((s) {
      playing = s.playing;
      if (s.processingState == ProcessingState.completed) {
        _onCompleted();
      }
      notifyListeners();
    });
  }

  Song? get current =>
      (currentIndex >= 0 && currentIndex < queue.length) ? queue[currentIndex] : null;

  Future<void> initSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (_) {}
  }

  Future<void> loadPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      shuffle = p.getBool('shuffle') ?? false;
      repeat = PlayRepeat.values[p.getInt('repeat') ?? 0];
      volume = p.getDouble('volume') ?? 1.0;
      muted = p.getBool('muted') ?? false;
      await _player.setVolume(muted ? 0.0 : volume);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _savePrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('shuffle', shuffle);
      await p.setInt('repeat', repeat.index);
      await p.setDouble('volume', volume);
      await p.setBool('muted', muted);
    } catch (_) {}
  }

  /// Lưu cài đặt sau khi ngừng thao tác (debounce).
  ///
  /// Slider volume phát ra hàng chục sự kiện mỗi lần kéo. Nếu ghi
  /// SharedPreferences ngay mỗi lần thì mỗi sự kiện đều là một lần ghi
  /// đĩa → kéo slider bị nghẽn và vòng lặp UI bị chậm.
  Timer? _prefsTimer;

  void _scheduleSavePrefs() {
    _prefsTimer?.cancel();
    _prefsTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_savePrefs());
    });
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    if (volume > 0) muted = false;
    await _player.setVolume(muted ? 0.0 : volume);
    _scheduleSavePrefs();
    notifyListeners();
  }

  Future<void> toggleMute() async {
    muted = !muted;
    await _player.setVolume(muted ? 0.0 : volume);
    _scheduleSavePrefs();
    notifyListeners();
  }

  MediaItem _toMediaItem(Song s) => MediaItem(
        id: s.data,
        title: s.title,
        artist: s.artist,
        album: s.album,
        duration: s.durationMs > 0 ? Duration(milliseconds: s.durationMs) : null,
      );

  Future<void> setQueue(List<Song> songs, {int startAt = 0}) async {
    queue = List.of(songs);
    _rebuildShuffle();
    currentIndex = startAt.clamp(0, queue.isEmpty ? 0 : queue.length - 1);
    if (queue.isEmpty) return;
    await _playAt(currentIndex);
  }

  void _rebuildShuffle() {
    _shuffleOrder = List.generate(queue.length, (i) => i)..shuffle();
    _shufflePos = 0;
  }

  Future<void> _playAt(int index) async {
    if (index < 0 || index >= queue.length) return;
    currentIndex = index;
    loading = true;
    error = null;
    notifyListeners();
    final s = queue[index];
    try {
      final source = await _buildSource(s);
      await _player.setAudioSource(source);
      await _player.play();
      unawaited(_db.pushHistory(s));
      // Tải trước bài kế tiếp để lần chuyển bài sau không phải chờ mạng.
      unawaited(_prefetchNext());
    } catch (e) {
      error = 'Không phát được "${s.title}". Chuyển bài tiếp theo.';
      notifyListeners();
      // skip corrupted/missing file automatically
      Future.delayed(const Duration(milliseconds: 600), next);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Dựng nguồn phát cho một bài.
  ///
  /// Với nhạc online: nếu bản tải đã nằm trong cache thì phát thẳng file
  /// cục bộ (không buffer qua mạng → khởi động tức thì). Nếu chưa có thì
  /// phát từ URL và tải bản cache chạy nền.
  Future<AudioSource> _buildSource(Song s) async {
    final tag = _toMediaItem(s);
    if (!s.isOnline) {
      return AudioSource.uri(Uri.file(s.data), tag: tag);
    }
    final cached = await AudioCacheService.instance.cachedFile(s.data);
    if (cached != null) {
      return AudioSource.uri(Uri.file(cached.path), tag: tag);
    }
    unawaited(AudioCacheService.instance.prefetch(s.data));
    return AudioSource.uri(Uri.parse(s.data), tag: tag);
  }

  /// Tải trước bài sẽ phát kế tiếp (bài online) để chuyển bài không bị đứng.
  Future<void> _prefetchNext() async {
    if (queue.isEmpty) return;
    final nextIndex = shuffle && _shuffleOrder.isNotEmpty
        ? _shuffleOrder[(_shufflePos + 1) % _shuffleOrder.length]
        : (currentIndex + 1) % queue.length;
    if (nextIndex < 0 || nextIndex >= queue.length) return;
    final next = queue[nextIndex];
    if (!next.isOnline) return;
    await AudioCacheService.instance.prefetch(next.data);
  }

  Future<void> playSong(Song s) async {
    final i = queue.indexWhere((e) => e.data == s.data && e.id == s.id);
    if (i >= 0) {
      await _playAt(i);
    } else {
      queue = [...queue, s];
      await _playAt(queue.length - 1);
    }
  }

  Future<void> toggle() async {
    if (playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.idle && current != null) {
        await _playAt(currentIndex);
      } else {
        await _player.play();
      }
    }
  }

  Future<void> next() async {
    if (queue.isEmpty) return;
    if (shuffle) {
      _shufflePos = (_shufflePos + 1) % _shuffleOrder.length;
      await _playAt(_shuffleOrder[_shufflePos]);
    } else {
      await _playAt((currentIndex + 1) % queue.length);
    }
  }

  Future<void> previous() async {
    if (queue.isEmpty) return;
    if (position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (shuffle) {
      _shufflePos = (_shufflePos - 1 + _shuffleOrder.length) % _shuffleOrder.length;
      await _playAt(_shuffleOrder[_shufflePos]);
    } else {
      await _playAt((currentIndex - 1 + queue.length) % queue.length);
    }
  }

  Future<void> seek(Duration d) => _player.seek(d);

  void _onCompleted() {
    if (repeat == PlayRepeat.one) {
      _playAt(currentIndex);
    } else if (repeat == PlayRepeat.all) {
      next();
    } else {
      if (shuffle || currentIndex < queue.length - 1) {
        next();
      }
    }
  }

  Future<void> toggleShuffle() async {
    shuffle = !shuffle;
    if (shuffle) _rebuildShuffle();
    await _savePrefs();
    notifyListeners();
  }

  Future<void> cycleRepeat() async {
    repeat = PlayRepeat.values[(repeat.index + 1) % PlayRepeat.values.length];
    await _player.setLoopMode(
        repeat == PlayRepeat.one ? LoopMode.one : LoopMode.off);
    await _savePrefs();
    notifyListeners();
  }

  void setSleepTimer(Duration? d) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepUntil = null;
    if (d != null) {
      sleepUntil = DateTime.now().add(d);
      _sleepTimer = Timer(d, () async {
        await _player.pause();
        sleepUntil = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _sleepTimer?.cancel();
    _prefsTimer?.cancel();
    positionNotifier.dispose();
    durationNotifier.dispose();
    _player.dispose();
    super.dispose();
  }
}

