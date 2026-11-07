# WaveBox — Ứng dụng Nghe Nhạc Online + Offline (Flutter)

Đồ án Công nghệ phần mềm — Ứng dụng nghe nhạc **Online + Offline** xây dựng bằng **Flutter + Dart** với một codebase chung cho Android, Web, Windows.

> App Flutter nằm trong thư mục `music_app/`. File này là README tổng của toàn bộ repo.

## 1. Giới thiệu

**WaveBox** cho phép:

- Quét và phát nhạc **ngoại tuyến** trên thiết bị (MP3 / FLAC / WAV / M4A / OGG) qua MediaStore.
- Phát nhạc **trực tuyến** demo + phát video MP4.
- Quản lý Playlist, Yêu thích, Lịch sử nghe gần đây, lưu bền vững bằng SQLite.
- Đăng nhập Email / Google (qua Backend Spring Boot + JWT), đồng bộ playlist khi có mạng.
- Phát nhạc chạy ngầm với Media Notification, Sleep Timer, Shuffle / Repeat, giao diện sáng / tối.

## 2. Tính năng chính

1. **Thư viện nhạc**
   - Quét MediaStore bằng `on_audio_query`: bài hát / nghệ sĩ / album + metadata ID3.
   - Chọn file thủ công bằng `file_picker` khi demo trên Web / Windows.
   - Nhạc mẫu online để demo khi máy không có file nhạc.

2. **Phát nhạc**
   - Play / Pause / Next / Previous / SeekBar.
   - Shuffle, Repeat Off / All / One.
   - Mini Player + màn hình phát full + hàng đợi (queue).
   - Chạy ngầm với `just_audio_background` + `audio_service` (Foreground Service + MediaSession).
   - Tự bỏ qua file hỏng và chuyển bài tiếp theo.

3. **Playlist & Yêu thích**
   - Thêm / sửa / xóa playlist, thêm / gỡ bài (vuốt để xóa).
   - Thả tim Favorites.
   - Lịch sử nghe Recently Played, giữ tối đa 100 bài.
   - Tất cả lưu trong SQLite nên còn lại sau khi tắt app / khởi động lại máy.

4. **Tìm kiếm & Khám phá**
   - Tìm kiếm real-time theo tên bài / nghệ sĩ.
   - Phân loại theo Nghệ sĩ / Album, tab Cá nhân.

5. **Tiện ích**
   - Sleep Timer 15 / 30 / 60 / 90 phút.
   - Giao diện sáng / tối.
   - Phát video MP4 bằng `video_player`.
   - Kiểm tra mạng bằng `connectivity_plus`, hàng đợi đồng bộ `pending_sync` khi offline.

## 3. Công nghệ sử dụng

| Nhóm | Công nghệ |
|---|---|
| Framework / Ngôn ngữ | Flutter 3.41, Dart 3.11 |
| Kiến trúc | MVVM, Feature-based kết hợp Layer-based |
| Phát âm thanh | `just_audio`, `just_audio_background`, `audio_service`, `audio_session` |
| Quét nhạc máy | `on_audio_query` (MediaStore / ContentResolver) |
| Chọn file | `file_picker` |
| Video | `video_player` |
| CSDL cục bộ | `sqflite` + `sqflite_common_ffi` (desktop) |
| Cài đặt nhẹ | `shared_preferences` |
| Quyền runtime | `permission_handler` |
| State management | `provider`, `rxdart` |
| Mạng / Auth | `http`, `connectivity_plus`, `google_sign_in`, JWT (`Authorization: Bearer`) |
| Backend (ngoài Flutter) | Java + Spring Boot, PostgreSQL, Spring Security + JWT, Firestore sync |
| Test | `flutter_test`, `flutter_lints` |

Chi tiết đầy đủ xem trong `music_app/pubspec.yaml`.

## 4. Cấu trúc dự án

```
d:/app_music/
├── README.md                  # File này
├── DATABASE_DESIGN.md         # Thiết kế CSDL SQLite + PostgreSQL + Firestore
├── .gitignore
└── music_app/                 # App Flutter chính
    ├── lib/
    │   ├── main.dart                       # Khởi tạo JustAudioBackground + Provider
    │   ├── core/network/                   # api_client.dart, connectivity_service.dart
    │   ├── core/theme/                     # app_theme.dart (sáng/tối)
    │   ├── core/utils/                     # formatters.dart
    │   ├── models/                         # song.dart, playlist.dart, catalog.dart
    │   ├── data/                           # app_database.dart (SQLite v3)
    │   ├── services/                       # library_service.dart, download_service.dart
    │   ├── player/                         # player_controller.dart (engine phát nhạc)
    │   ├── features/auth/                  # data / viewmodel / view (login)
    │   ├── features/library/               # song_repository.dart
    │   ├── features/player/                # audio_handler.dart
    │   ├── features/sync/                  # sync_service.dart
    │   ├── screens/                        # home, player, playlists, search, video, favorites
    │   └── widgets/                        # mini_player.dart, ui_kit.dart
    ├── android/                            # AndroidManifest + quyền + Foreground Service
    ├── ios/ linux/ macos/ web/ windows/    # Các platform Flutter
    ├── test/widget_test.dart
    ├── pubspec.yaml
    ├── README.md                           # README chi tiết của app Flutter
    └── CAU_TRUC_THU_MUC.md                 # Giải thích từng thư mục / file
```

Giải thích chi tiết từng lớp xem `music_app/CAU_TRUC_THU_MUC.md`.

## 5. Cơ sở dữ liệu

Thiết kế đầy đủ trong `DATABASE_DESIGN.md`, tóm tắt:

- **SQLite cục bộ (`music_app.db` v3):** `songs_cache`, `artists`, `albums`, `genres`, `downloads`, `playlists`, `playlist_songs`, `favorites`, `history` (cap 100), `users`, `settings`, `pending_sync`.
- **PostgreSQL (Backend Spring Boot):** `users`, `artists`, `albums`, `genres`, `songs`, `song_genres`, `playlists`, `playlist_songs`, `favorites`, `listening_history`.
- **Firestore:** `users/{uid}/playlists`, `favorites`, `history` để đồng bộ đa thiết bị.
- Nguyên tắc: **Offline-first** — ghi SQLite trước, đẩy vào `pending_sync`, có mạng thì `SyncService.syncNow()` retry tối đa 5 lần.

## 6. Yêu cầu môi trường

- Flutter 3.41+ / Dart 3.11+
- Android SDK (API 26–34), đã chấp nhận licenses
- Android thật / emulator để quét MediaStore đầy đủ
- Chrome nếu muốn chạy demo Web

Kiểm tra:

```bash
flutter --version
flutter doctor
```

## 7. Cách chạy

```bash
cd music_app
flutter pub get

# Chạy trên Android / emulator (khuyến nghị để quét nhạc thật)
flutter run

# Chạy demo trên Web (dùng nhạc mẫu + chọn file)
flutter run -d chrome

# Chạy test
flutter test
```

Build:

```bash
flutter build apk --debug
flutter build web
```

## 8. Cấu hình Backend (nếu có)

Base URL đang cấu hình trong `music_app/lib/main.dart`:

```dart
_api = ApiClient(baseUrl: 'http://10.0.2.2:8080');
```

- Android emulator: giữ `http://10.0.2.2:8080`
- Máy thật: đổi thành IP LAN của Backend, ví dụ `http://192.168.1.10:8080`
- Test API bằng Postman: `/api/auth/login`, `/api/auth/google`, `/api/songs`, `/api/playlists`

## 9. Quyền Android

Khai báo trong `music_app/android/app/src/main/AndroidManifest.xml`:

- `READ_MEDIA_AUDIO` / `READ_EXTERNAL_STORAGE`
- `POST_NOTIFICATIONS`
- `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`

Khi chạy lần đầu trên Android thật, cấp quyền Âm thanh và Thông báo khi app hỏi. Dùng nút **Chọn file** để thêm mp3 / flac / wav / m4a, nút **quét lại** để đồng bộ MediaStore.

## 10. Tài liệu liên quan

- `music_app/README.md` — README chi tiết của app Flutter
- `music_app/CAU_TRUC_THU_MUC.md` — Giải thích kiến trúc MVVM + từng file
- `DATABASE_DESIGN.md` — ERD, schema SQLite / PostgreSQL / Firestore, map Use Case → bảng, migration v2 → v3

## 11. Nhóm phát triển

Đồ án CNPM N05 — Nhóm 17.

Mọi đóng góp qua Pull Request lên nhánh `main` của repo này.
