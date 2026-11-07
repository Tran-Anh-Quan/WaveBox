import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/network/connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'data/app_database.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/sync/data/sync_service.dart';
import 'player/player_controller.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nhom17.music_app.channel.audio',
    androidNotificationChannelName: 'Phat nhac',
    androidNotificationOngoing: true,
  );
  final player = PlayerController();
  await player.initSession();
  await player.loadPrefs();
  runApp(MusicApp(player: player));
}

class MusicApp extends StatefulWidget {
  final PlayerController? player;
  const MusicApp({super.key, this.player});
  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  bool _dark = true;
  late final PlayerController _player;
  late final ApiClient _api;
  late final AuthViewModel _auth;
  late final ConnectivityService _connectivity;
  late final SyncService _sync;

  @override
  void initState() {
    super.initState();
    _player = widget.player ?? PlayerController();
    // Đổi baseUrl cho đúng Backend Spring Boot của bạn (UC 8.x).
    // Android emulator: 10.0.2.2 ; máy thật: IP LAN, ví dụ http://192.168.1.10:8080
    _api = ApiClient(baseUrl: 'http://10.0.2.2:8080');
    _connectivity = ConnectivityService();
    _auth = AuthViewModel(repo: AuthRepository(api: _api));
    _auth.loadSaved();
    _sync = SyncService(db: AppDatabase(), api: _api, connectivity: _connectivity);
    _sync.startAutoSync();
  }

  @override
  void dispose() {
    _sync.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _player),
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider.value(value: _connectivity),
        Provider.value(value: _api),
        Provider.value(value: _sync),
      ],
      child: MaterialApp(
        title: 'Wavebox — Nghe nhạc Online + Offline',
        debugShowCheckedModeBanner: false,
        themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: HomeScreen(
          dark: _dark,
          onToggleTheme: () => setState(() => _dark = !_dark),
        ),
      ),
    );
  }
}
