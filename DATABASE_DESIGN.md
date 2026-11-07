# Thiết kế Cơ sở dữ liệu — App Nghe Nhạc Flutter (Online + Offline)

> Bao phủ 10 nhóm Use Case: 1.0 Thư viện cục bộ, 2.0 Tìm kiếm, 3.0/4.0 Phát + Điều khiển,
> 5.0 Playlist, 6.0 Yêu thích/Lịch sử, 7.0 Khám phá + Tải, 8.0 Tài khoản, 9.0 Đồng bộ Firebase, 10.0 Hẹn giờ.

Kiến trúc dữ liệu 3 tầng (khớp `CÔNG NGHỆ SỬ DỤNG.docx` + code hiện tại):

```
[PostgreSQL — Backend Spring Boot]  <--REST + JWT-->  [Flutter App]
        ^                                                    |
        | (seed catalog)                                     | sqflite (SQLite) = nguồn sự thật khi offline
[Firebase Auth + Firestore]  <--sync playlists/favs/history--+
```

---

## 1. Nguyên tắc thiết kế

1. **Offline-first:** mọi thao tác 5.0/6.0 ghi ngay vào SQLite, đồng thời đẩy 1 bản ghi vào `pending_sync` (UC 9.1–9.3). Có mạng → `SyncService.syncNow()` retry tối đa 5 lần.
2. **Snapshot bài hát:** `favorites`, `history`, `playlist_songs` đều lưu snapshot `songTitle/Artist/Album/Data/Duration` để vẫn hiển thị được khi file gốc bị xóa (UC 1.3, 5.5, 6.3).
3. **Catalog online chuẩn hóa:** `artists – albums – genres – songs – song_genres` (UC 7.1–7.4, 2.x). App cache lại vào `songs_cache` để tìm kiếm offline vẫn ra kết quả.
4. **Một user nhiều thiết bị:** mọi bảng cá nhân có `ownerId + updatedAt`; Firestore dùng `updatedAt` để last-write-wins khi khôi phục (UC 9.4).
5. **Sleep Timer & settings không đồng bộ:** chỉ lưu local (`settings` + SharedPreferences) (UC 10.x).

---

## 2. ERD logic (gộp)

```
users(1)───< playlists(1)───< playlist_songs >───songs_cache
users(1)───< favorites >───songs_cache
users(1)───< history >───songs_cache
users(1)───< downloads >───songs_cache

artists(1)───< albums(1)───< songs_cache
genres(1)───< song_genres >───songs_cache
songs_cache(1)───< downloads
```

---

## 3. SQLite cục bộ — `music_app.db` v3 (sqflite)

> File cài đặt: `lib/data/app_database.dart` (đã nâng từ v2 → v3, giữ toàn bộ dữ liệu cũ).

### 3.1 `artists` — UC 2.2, 7.3
| Cột | Kiểu | Ràng buộc | Ghi chú |
|---|---|---|---|
| id | INTEGER PK | | trùng `artistId` server để dễ sync |
| name | TEXT | UNIQUE NOT NULL | tên ca sĩ/ban nhạc |
| coverUrl | TEXT | | ảnh đại diện |
| bio | TEXT | | tiểu sử ngắn (UC 7.3) |

### 3.2 `albums` — UC 2.3, 7.2
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK | |
| title | TEXT NOT NULL | |
| artistId | INTEGER FK→artists | |
| artistName | TEXT | snapshot hiển thị nhanh |
| coverUrl | TEXT | |
| releaseYear | INTEGER | |

### 3.3 `genres` — UC 2.4, 7.4
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK | |
| name | TEXT UNIQUE NOT NULL | Pop, Ballad, Indie, EDM… |
| coverUrl | TEXT | |

### 3.4 `songs_cache` — hợp nhất nhạc online + metadata local (UC 1.2, 1.3, 2.x, 7.1)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK | id server hoặc MediaStore id |
| title | TEXT NOT NULL | FTS index (UC 2.1) |
| artist | TEXT | snapshot (UC 1.3) |
| artistId | INTEGER FK | |
| album | TEXT | |
| albumId | INTEGER FK | |
| genreId | INTEGER FK | lọc thể loại (UC 2.4) |
| data | TEXT NOT NULL | URL stream **hoặc** đường dẫn file |
| durationMs | INTEGER DEFAULT 0 | |
| artUri | TEXT | artwork local / coverUrl online |
| fileSize | INTEGER DEFAULT 0 | dung lượng byte (UC 1.3) |
| format | TEXT | mp3/wav/m4a/flac (UC 1.1) |
| isOnline | INTEGER 0/1 | 1 = streaming (UC 3.1) |
| isDownloaded | INTEGER 0/1 | 1 = đã tải về (UC 1.2, 7.5) |
| playCount | INTEGER DEFAULT 0 | gợi ý trending (UC 7.1) |
| updatedAt | INTEGER | millis, dùng so sánh sync |

Index: `idx_songs_title(title)`, `idx_songs_artist(artist)`, `idx_songs_album(album)`, `idx_songs_genre(genreId)`.

### 3.5 `downloads` — UC 1.4, 7.5
| Cột | Kiểu | Ghi chú |
|---|---|---|
| songId | INTEGER PK FK | |
| filePath | TEXT NOT NULL | đường dẫn lưu trữ (UC 1.3) |
| fileSize | INTEGER | |
| format | TEXT | |
| status | TEXT DEFAULT 'done' | done/downloading/failed |
| downloadedAt | INTEGER | |

Xóa bản tải (UC 1.4) = xóa file vật lý + xóa row này + set `songs_cache.isDownloaded=0`.

### 3.6 `playlists` — UC 5.x, 9.1
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK AUTOINC | id local |
| uuid | TEXT UNIQUE | id server/Firestore, null khi chưa sync |
| name | TEXT NOT NULL | (UC 5.1, 5.3) |
| description | TEXT DEFAULT '' | |
| coverUrl | TEXT | bìa tự động = artwork 4 bài đầu |
| ownerId | TEXT | uid, null khi chưa đăng nhập |
| createdAt / updatedAt | INTEGER | sort + conflict resolve |
| isSynced | INTEGER 0/1 | 0 = cần đẩy lên cloud |

### 3.7 `playlist_songs` — UC 5.5
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK AUTOINC | giữ thứ tự thêm vào |
| playlistId | INTEGER FK CASCADE | |
| songId | INTEGER NOT NULL | |
| songTitle/Artist/Album/Data/Duration | TEXT/INTEGER | snapshot |
| addedAt | INTEGER | sắp xếp |
| UNIQUE(playlistId, songId) | | chống trùng |

### 3.8 `favorites` — UC 6.1–6.3, 9.2
| Cột | Kiểu | Ghi chú |
|---|---|---|
| songId | INTEGER PK | |
| songTitle/Artist/Album/Data/Duration | snapshot | |
| ownerId | TEXT | |
| likedAt | INTEGER | sort mới nhất |
| isSynced | INTEGER 0/1 | |

### 3.9 `history` — UC 6.4, 9.3 (giữ tối đa 100)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | INTEGER PK AUTOINC | |
| songId | INTEGER NOT NULL + INDEX | |
| snapshot… | TEXT | như trên |
| ownerId | TEXT | |
| playedAt | INTEGER NOT NULL + INDEX | sort DESC |
| Xóa lịch sử = `DELETE FROM history` (kèm nút "Xóa" trên UI) |

### 3.10 `users` — UC 8.x (cache profile để hiển thị offline)
| Cột | Kiểu | Ghi chú |
|---|---|---|
| id | TEXT PK | uid Firebase / id server |
| email | TEXT UNIQUE NOT NULL | |
| displayName | TEXT | (UC 8.3) |
| photoUrl | TEXT | avatar |
| lastSyncAt | INTEGER | mốc khôi phục (UC 9.4) |

### 3.11 `settings` — UC 4.x, 10.x (key-value, không sync)
| key | value ví dụ |
|---|---|
| shuffle | 0/1 (UC 4.5) |
| repeat | off/all/one (UC 4.6) |
| volume / muted | 0.0–1.0 (UC 4.4) |
| sleep_deadline | millis epoch hoặc null (UC 10.x) |
| last_queue | JSON queue + index (khôi phục sau reboot) |

### 3.12 `pending_sync` — UC 9.x (giữ nguyên, mở rộng `op`)
```
op ∈ {CREATE_PLAYLIST, RENAME_PLAYLIST, DELETE_PLAYLIST,
      ADD_TO_PLAYLIST, REMOVE_FROM_PLAYLIST,
      TOGGLE_FAVORITE, PUSH_HISTORY, CLEAR_HISTORY,
      UPDATE_PROFILE}
status ∈ {pending, synced, failed}, retries ≤ 5
```

---

## 4. PostgreSQL — Backend Spring Boot (catalog + multi-user)

```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY, uuid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL, password_hash TEXT,
  display_name TEXT, photo_url TEXT,
  provider TEXT DEFAULT 'email',          -- email | google
  created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE artists (
  id BIGSERIAL PRIMARY KEY, name TEXT UNIQUE NOT NULL,
  cover_url TEXT, bio TEXT
);
CREATE TABLE albums (
  id BIGSERIAL PRIMARY KEY, title TEXT NOT NULL,
  artist_id BIGINT REFERENCES artists(id) ON DELETE SET NULL,
  cover_url TEXT, release_year INT
);
CREATE TABLE genres (
  id BIGSERIAL PRIMARY KEY, name TEXT UNIQUE NOT NULL, cover_url TEXT
);
CREATE TABLE songs (
  id BIGSERIAL PRIMARY KEY, title TEXT NOT NULL,
  artist_id BIGINT REFERENCES artists(id), album_id BIGINT REFERENCES albums(id),
  stream_url TEXT NOT NULL, cover_url TEXT,
  duration_ms INT DEFAULT 0, file_size BIGINT DEFAULT 0, format TEXT DEFAULT 'mp3',
  play_count BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE song_genres (
  song_id BIGINT REFERENCES songs(id) ON DELETE CASCADE,
  genre_id BIGINT REFERENCES genres(id) ON DELETE CASCADE,
  PRIMARY KEY (song_id, genre_id)
);
CREATE TABLE playlists (
  id BIGSERIAL PRIMARY KEY, uuid TEXT UNIQUE NOT NULL,
  owner_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL, description TEXT DEFAULT '',
  cover_url TEXT, created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE playlist_songs (
  id BIGSERIAL PRIMARY KEY,
  playlist_id BIGINT REFERENCES playlists(id) ON DELETE CASCADE,
  song_id BIGINT REFERENCES songs(id) ON DELETE CASCADE,
  added_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (playlist_id, song_id)
);
CREATE TABLE favorites (
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  song_id BIGINT REFERENCES songs(id) ON DELETE CASCADE,
  liked_at TIMESTAMPTZ DEFAULT now(), PRIMARY KEY (user_id, song_id)
);
CREATE TABLE listening_history (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  song_id BIGINT REFERENCES songs(id) ON DELETE SET NULL,
  played_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_songs_title_trgm ON songs USING gin (title gin_trgm_ops);
CREATE INDEX idx_history_user_played ON listening_history (user_id, played_at DESC);
```

REST gợi ý (JWT `Authorization: Bearer`):
`POST /api/auth/register|login|google`, `GET /api/songs?search=&genre=&artistId=&albumId=`,
`GET /api/artists|albums|genres`, `CRUD /api/playlists`, `POST /api/favorites`, `GET/POST /api/history`.

---

## 5. Firestore — Đồng bộ cá nhân (UC 9.x)

```
users/{uid} : { email, displayName, photoUrl, lastSyncAt }
  playlists/{playlistUuid} : { name, description, coverUrl, updatedAt, songIds[] }
  favorites/{songId}       : { title, artist, album, data, durationMs, likedAt }
  history/{autoId}         : { songId, title, artist, playedAt }
```

Luồng 9.4 khôi phục: đăng nhập → `lastSyncAt` local < cloud → pull toàn bộ 3 collection → upsert SQLite → set `isSynced=1`.

---

## 6. Map UC → Bảng (traceability)

| UC | Bảng/cơ chế chính |
|---|---|
| 1.1 Quét máy | MediaStore (runtime) + `songs_cache` (cache) + `genres` lọc định dạng |
| 1.2 List local/đã tải | `songs_cache WHERE isDownloaded=1` JOIN `downloads` |
| 1.3 Chi tiết file | `songs_cache.fileSize/format/data` + `downloads.filePath` |
| 1.4 Xóa bản tải | xóa file + `downloads` + update `songs_cache.isDownloaded` |
| 2.1–2.3 Tìm kiếm | index `title/artist/album` trên `songs_cache` (+ `songs` server dùng trigram) |
| 2.4 Lọc thể loại | `genres` + `song_genres` / `songs_cache.genreId` |
| 3.x Phát nhạc | runtime `PlayerController.queue`; `downloads.filePath` (offline) / `stream_url` (online) |
| 4.x Điều khiển | `settings(shuffle/repeat/volume)` + notification MediaSession |
| 5.x Playlist | `playlists` + `playlist_songs` + `pending_sync` |
| 6.1–6.3 Thích | `favorites` + `pending_sync(TOGGLE_FAVORITE)` |
| 6.4 Lịch sử | `history` (cap 100) + `pending_sync(PUSH_HISTORY/CLEAR_HISTORY)` |
| 7.1–7.4 Khám phá | `songs/artists/albums/genres` server → cache `songs_cache` |
| 7.5 Download | `downloads` + `songs_cache.isDownloaded=1` |
| 8.x Tài khoản | `users` (local cache) + Spring Security JWT + Google idToken |
| 9.x Đồng bộ | `pending_sync` + Firestore 3 collection + `isSynced/updatedAt` |
| 10.x Hẹn giờ | `settings(sleep_deadline)` + `Timer` trong `PlayerController` (không sync) |

---

## 7. Migration v2 → v3

* `onCreate(v3)`: tạo đủ 12 bảng trên.
* `onUpgrade(1→3 / 2→3)`: `CREATE TABLE IF NOT EXISTS` cho `artists, albums, genres, songs_cache, downloads, users, settings`; `ALTER TABLE playlists ADD COLUMN uuid/description/coverUrl/ownerId/updatedAt/isSynced`; backfill `updatedAt=createdAt`.
* Không mất playlist/favorite/history cũ.
