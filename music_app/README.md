# NhacOffline N05 — Ứng dụng nghe nhạc ngoại tuyến (Flutter)

Đồ án CNPM N05 — Nhóm 17 — ĐH Công Nghệ Đông Á.
Ứng dụng nghe nhạc **ngoại tuyến (Offline Music Player)** chạy trên Android (API 26–34),
xây dựng bằng **Flutter + Dart** từ một codebase chung (theo Chương I & III của đề tài).

## Công nghệ sử dụng (đúng đề tài)
- **Flutter 3.41 / Dart 3.11**, kiến trúc MVVM tách lớp: `models / data / services / player / screens / widgets`
- Phát âm thanh: `just_audio` + `just_audio_background` (Foreground Service + Media Notification, phát chạy ngầm, xử lý audio-focus)
- Quét thư viện thiết bị: `on_audio_query` (MediaStore/ContentResolver, mp3/flac/wav/m4a/ogg + metadata ID3)
- Chọn file thủ công: `file_picker` (fallback khi máy không có nhạc / chạy demo trên Windows/Web)
- Phát video MP4: `video_player`
- Lưu trữ cục bộ bền vững: `sqflite` (+ `sqflite_common_ffi` cho desktop) — Playlist, Yêu thích, Lịch sử nghe (Recently Played)
- Cài đặt nhẹ: `shared_preferences` (shuffle/repeat, sáng/tối)
- Quyền runtime Android: `permission_handler` (`READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE`, `POST_NOTIFICATIONS`)
- State: `provider`

## Chức năng đã build (đối chiếu mục tiêu Chương I)
1. **Quét & phân loại thư viện**: Tất cả bài hát / Nghệ sĩ / Album (+ nhạc mẫu online để demo, tab Cá nhân).
2. **Audio Player Core**: Play/Pause/Next/Previous/SeekBar; Shuffle; Repeat Off/All/One; Mini Player + màn hình phát + Media Notification.
3. **Playlist & Yêu thích**: thêm/sửa/xóa playlist, thêm/gỡ bài (vuốt để xóa), thả tim Favorites, tự động lưu Recently Played (tối đa 100).
4. **Tìm kiếm real-time** theo tên bài/nghệ sĩ; **Sleep Timer** 15/30/60/90 phút; giao diện sáng/tối; phát video MP4.

## Cấu trúc mã nguồn
```
lib/main.dart                  -> khởi tạo JustAudioBackground, Provider, MaterialApp
lib/models/song.dart, playlist.dart
lib/data/app_database.dart     -> SQLite: playlists, playlist_songs, favorites, history
lib/services/library_service.dart -> quét MediaStore + pick file + nhạc mẫu demo
lib/player/player_controller.dart -> engine phát nhạc (ChangeNotifier)
lib/screens/home_screen.dart   -> tabs Bài hát/Nghệ sĩ/Album/Cá nhân
lib/screens/player_screen.dart -> màn hình phát + hàng đợi + sleep timer
lib/screens/playlists_screen.dart, search_screen.dart, video_screen.dart
lib/widgets/mini_player.dart
android/app/src/main/AndroidManifest.xml -> quyền + foreground service (API 26-34)
```

## Cách chạy
```bash
cd music_app
flutter pub get
flutter run            # chạy trên máy Android/emulator (khuyến nghị để đủ quét MediaStore)
flutter run -d chrome  # chạy demo trên Web (dùng nhạc mẫu + chọn file)
flutter test           # kiểm thử đơn vị/widget
flutter build apk --debug  # đóng gói APK (cần Android SDK + chấp nhận licenses)
flutter build web      # bản web demo
```

## Lưu ý nghiệm thu
- Trên Android thật: cấp quyền Âm thanh/Thông báo khi app hỏi; nút **Chọn file** để thêm mp3/flac/wav/m4a; nút **quét lại** để đồng bộ MediaStore.
- File hỏng/thiếu metadata: app tự bỏ qua, báo lỗi và chuyển bài tiếp theo (đúng yêu cầu chịu lỗi).
- Dữ liệu Playlist/Favorites/History lưu SQLite nên còn lại sau khi tắt app/khởi động lại máy.
