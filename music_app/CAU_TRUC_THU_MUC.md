# Giải thích cấu trúc thư mục dự án NhacOffline N05

Tài liệu này giải thích từng thư mục/tệp trong khung project đã build,
đối chiếu trực tiếp với bảng **CÔNG NGHỆ SỬ DỤNG.docx**.

Công nghệ chốt: **Android + Flutter + Dart + MVVM + Feature-based kết hợp Layer-based**,
Backend **Java + Spring Boot**, giao tiếp **RESTful API + JSON**,
CSDL online **PostgreSQL**, CSDL cục bộ **SQLite + sqflite**,
xác thực **Spring Security + JWT**, đăng nhập **Email/password + Google Sign-In**.

---

## 1. Cây thư mục hiện tại

```
music_app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── network/
│   │   │   ├── api_client.dart            # RESTful API + JSON + JWT
│   │   │   └── connectivity_service.dart  # connectivity_plus
│   │   └── utils/
│   │       └── formatters.dart            # Hàm dùng chung
│   ├── models/
│   │   ├── song.dart                      # Model bài hát
│   │   └── playlist.dart                  # Model playlist
│   ├── data/
│   │   └── app_database.dart              # SQLite + Pending Sync Queue
│   ├── services/
│   │   └── library_service.dart           # on_audio_query + MediaStore + file_picker
│   ├── player/
│   │   └── player_controller.dart         # just_audio + just_audio_background
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/auth_repository.dart
│   │   │   ├── view/login_screen.dart
│   │   │   └── viewmodel/auth_viewmodel.dart
│   │   ├── library/
│   │   │   └── data/song_repository.dart
│   │   ├── player/
│   │   │   └── data/audio_handler.dart    # audio_service + MediaSession
│   │   └── sync/
│   │       └── data/sync_service.dart     # RESTful API + Pending Sync Queue + Retry
│   ├── screens/
│   │   ├── home_screen.dart               # Tabs Bài hát/Nghệ sĩ/Album/Cá nhân
│   │   ├── player_screen.dart             # Màn hình phát + Sleep Timer
│   │   ├── playlists_screen.dart          # CRUD playlist
│   │   ├── search_screen.dart             # Tìm kiếm real-time
│   │   └── video_screen.dart              # Phát video MP4
│   └── widgets/
│       └── mini_player.dart               # Mini Player
├── android/app/src/main/AndroidManifest.xml  # Quyền + Foreground Service
├── test/widget_test.dart                  # Flutter Test
├── pubspec.yaml                           # Khai báo thư viện Flutter
└── CAU_TRUC_THU_MUC.md                    # File giải thích này
```

Phần Backend **Java + Spring Boot + PostgreSQL** nằm ngoài app Flutter.
Khi nhóm làm Backend thì tạo thêm thư mục ngang hàng, ví dụ `backend/` với
`controller/`, `service/`, `repository/`, `entity/`, `security/` (Spring Security + JWT).

---

## 2. Giải thích từng phần

### `lib/main.dart` — Điểm khởi động app
- Khởi tạo `JustAudioBackground` để phát nhạc nền và hiện notification.
- Tạo `PlayerController`, nạp cài đặt shuffle/repeat, gắn `Provider`.
- Dựng `MaterialApp` với giao diện sáng/tối.
- Vai trò trong bảng công nghệ: **Framework Flutter + Ngôn ngữ Dart**.

### `lib/core/` — Lớp dùng chung toàn app (Layer-based)
- `core/network/api_client.dart`
  - Client gọi **RESTful API** của Backend Spring Boot.
  - Trao đổi dữ liệu **JSON** bằng package `http`.
  - Gắn **JWT** vào header `Authorization: Bearer <token>`.
- `core/network/connectivity_service.dart`
  - Dùng `connectivity_plus` để biết máy đang online hay offline.
  - Khi offline thì ghi vào hàng đợi, khi online thì đồng bộ.
- `core/utils/formatters.dart`
  - Hàm định dạng thời lượng `mm:ss` dùng chung cho Mini Player và màn hình phát.

### `lib/models/` — Model dữ liệu (tầng Model của MVVM)
- `models/song.dart`: id, title, artist, album, đường dẫn file/URL, thời lượng, cờ `isOnline`.
- `models/playlist.dart`: id, tên playlist, thời gian tạo.
- Hai model này được SQLite, Repository, ViewModel và màn hình dùng chung.

### `lib/data/app_database.dart` — CSDL cục bộ SQLite
- Dùng `sqflite` trên Android và `sqflite_common_ffi` khi chạy desktop.
- Các bảng:
  - `playlists`, `playlist_songs`: playlist cá nhân.
  - `favorites`: bài hát yêu thích.
  - `history`: nghe gần đây, giữ tối đa 100 bài.
  - `pending_sync`: **Pending Sync Queue**, lưu thao tác chưa đẩy lên server,
    gồm `op`, `status` (pending/synced/failed), `retries` để retry.
- Đúng hạng mục **CSDL cục bộ SQLite + sqflite** và **Hàng đợi đồng bộ**.

### `lib/services/library_service.dart` — Quét nhạc thiết bị
- `on_audio_query` truy vấn **Android MediaStore**, lọc MP3, FLAC, M4A/WAV.
- Đọc metadata tên bài, nghệ sĩ, album, thời lượng.
- `file_picker` cho người dùng chọn file thủ công khi demo.
- `permission_handler` + `AndroidManifest.xml` xin quyền đọc nhạc.
- Đúng các hạng mục **Quét nhạc cục bộ**, **API MediaStore**,
  **Định dạng MP3/FLAC/AAC-M4A**, **Quản lý quyền**.

### `lib/player/player_controller.dart` — Engine phát nhạc hiện tại
- Dùng `just_audio` để phát, tạm dừng, chuyển bài, tua nhạc.
- Quản lý hàng đợi, Shuffle, Repeat Off/All/One.
- Hẹn giờ ngủ Sleep Timer 15/30/60/90 phút.
- Lưu lịch sử nghe vào SQLite, tự bỏ qua file hỏng rồi chuyển bài.
- Đây là bản offline đang chạy ổn định trong khung project.

### `lib/features/` — Tổ chức Feature-based kết hợp MVVM
Đây là phần thể hiện rõ kiến trúc **MVVM + Feature-based**:

- `features/auth/`
  - `data/auth_repository.dart`: gọi `/api/auth/login` và `/api/auth/google`,
    nhận JWT từ Backend **Spring Security**.
  - `viewmodel/auth_viewmodel.dart`: giữ token, trạng thái loading/lỗi,
    lưu JWT vào SharedPreferences, không chứa code giao diện.
  - `view/login_screen.dart`: form **Email/password + Google Sign-In**,
    chỉ hiển thị và gọi ViewModel.
- `features/library/data/song_repository.dart`
  - Tầng Data của thư viện nhạc.
  - Nguồn offline: MediaStore + SQLite; nguồn online: `GET /api/songs`.
  - Ghi thay đổi offline vào Pending Sync Queue.
- `features/player/data/audio_handler.dart`
  - Hiện thực đúng bảng công nghệ: **audio_service kết hợp just_audio**,
    tích hợp **Android MediaSession + Foreground Service**,
    điều khiển trên notification và màn hình khóa.
- `features/sync/data/sync_service.dart`
  - Hiện thực **RESTful API + Pending Sync Queue + Retry + trạng thái đồng bộ**.
  - Có đồng bộ tự động định kỳ và đồng bộ thủ công `syncNow()`.

### `lib/screens/` và `lib/widgets/` — View của MVVM
- `screens/home_screen.dart`: 4 tab Bài hát, Nghệ sĩ, Album, Cá nhân.
- `screens/player_screen.dart`: ảnh bìa, SeekBar, Shuffle/Repeat, Sleep Timer, hàng đợi.
- `screens/playlists_screen.dart`: thêm, sửa tên, xóa playlist, thêm/gỡ bài.
- `screens/search_screen.dart`: tìm kiếm real-time theo tên bài/nghệ sĩ.
- `screens/video_screen.dart`: phát video MP4 bằng `video_player`.
- `widgets/mini_player.dart`: thanh phát thu nhỏ dùng chung.
- Các màn hình chỉ hiển thị và gọi ViewModel/Controller, không gọi HTTP trực tiếp,
  đúng nguyên tắc **MVVM**.

### `android/app/src/main/AndroidManifest.xml`
- Khai báo `READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE`, `POST_NOTIFICATIONS`,
  `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`.
- Hỗ trợ Android API 26 tới 34 theo bảng công nghệ.

### `test/widget_test.dart`
- **Flutter Integration Test / Widget Test**: kiểm tra model `Song`
  và màn hình chính khởi động được.
- Chạy bằng `flutter test`.

### `pubspec.yaml`
- Nơi khai báo toàn bộ thư viện Flutter tương ứng bảng công nghệ:
  `just_audio`, `just_audio_background`, `audio_service`, `on_audio_query`,
  `file_picker`, `video_player`, `sqflite`, `permission_handler`,
  `connectivity_plus`, `http`, `google_sign_in`, `provider`,
  `shared_preferences`, `audio_session`.

### Công cụ ngoài mã nguồn
- **IDE Android Studio**: mở thư mục `music_app/` để chạy và build APK.
- **Git + GitHub**: quản lý phiên bản, thư mục `.gitignore` đã có sẵn.
- **Postman**: kiểm thử các API Backend như `/api/auth/login`, `/api/songs`.
- **GitHub Projects**: theo dõi và phân công công việc cho nhóm.

---

## 3. Luồng dữ liệu tóm tắt

1. App quét nhạc bằng MediaStore rồi hiển thị qua View.
2. Người phát nhạc qua `just_audio`; bản chuẩn dùng `audio_service` + MediaSession.
3. Playlist, yêu thích, lịch sử lưu ngay vào SQLite.
4. Nếu có mạng: gọi RESTful API JSON kèm JWT lên Spring Boot + PostgreSQL.
5. Nếu mất mạng: ghi vào `pending_sync`, khi có mạng `SyncService` retry
   và chuyển trạng thái sang synced hoặc failed.
6. Đăng nhập Email hoặc Google đều đổi lấy JWT, Backend xác minh Google token.
