# PHASE 4 — BACKEND MUSIC DATA & SYNCHRONIZATION API

## 🎯 Mục tiêu Phase 4

Xây dựng hệ thống dữ liệu âm nhạc và các API nghiệp vụ trên nền tảng Spring Boot, PostgreSQL, JWT và User Model đã hoàn thành ở Phase 1–3.

Phase 4 tập trung hoàn thiện:

```text
PHASE 1 — ARCHITECTURE & API CONTRACT
                 ↓
PHASE 2 — BACKEND CORE & POSTGRESQL
                 ↓
PHASE 3 — AUTHENTICATION & SECURITY
                 ↓
Create Music Database Schema
                 ↓
Implement Entity / DTO / Repository / Service
                 ↓
Implement Music Catalog API
                 ↓
Implement Search & Filter API
                 ↓
Implement Audio Streaming
                 ↓
Implement Playlist CRUD
                 ↓
Implement Favorites & History
                 ↓
Implement Batch Synchronization API
                 ↓
Backend Tests & Postman
                 ↓
PHASE 4 DONE
```

**Phạm vi requirement:**

```text
AQ01 — Music Database Schema
AQ02 — Entity / DTO / Service / Sample Data
AQ03 — Music Catalog API
AQ04 — Search & Filter API
AQ05 — Audio Streaming
AQ06 — Playlist CRUD
AQ07 — Favorites & History
AQ08 — Batch Synchronization
AQ09 — Backend Tests & Postman
```

Đầu ra Phase 4 là Backend Music Data hoàn chỉnh, có thể cung cấp Catalog, tìm kiếm, Streaming, quản lý Playlist, Favorites, History và đồng bộ dữ liệu người dùng qua REST API.

Phase 4 **được phép tạo và sửa code Backend**, tạo Flyway migration mới, triển khai API và viết kiểm thử.

Không triển khai giao diện Flutter hoặc tích hợp các Repository của Flutter trong Phase này.

---

## 1. NGUYÊN TẮC TRIỂN KHAI

### 1.1 — Previous Phases Source of Truth Rule

Trước khi code, đọc:

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/IMPLEMENTATION_ROADMAP.md
docs/REPORT/PHASE-2-BACKEND-CORE.md
docs/REPORT/PHASE-3-AUTH-SECURITY.md
```

Kiểm tra source hiện có:

```text
Spring Boot Application
User Entity / Repository / Service
PostgreSQL Configuration
Flyway Migrations
SecurityConfig
JWT Authentication Filter
User Authentication
Refresh Session
Global Exception Handler
```

Các quyết định đã chốt phải được giữ nguyên:

```text
Java: 17
Framework: Spring Boot
Database: PostgreSQL
ORM: Spring Data JPA
Migration: Flyway
Primary Key: UUID
Authentication: JWT
User Model: Single User
Roles: None
Ownership: Authenticated User ID
API Format: API_CONTRACT.md
```

Không tạo lại User Entity hoặc xây dựng lại cơ chế JWT của Phase 2–3.

### 1.2 — Single User & Ownership Rule

Tất cả dữ liệu cá nhân phải được quản lý theo User đã xác thực.

Mô hình:

```text
User
 |
 +-- Playlists
 |     |
 |     +-- Playlist Songs
 |
 +-- Favorites
 |
 +-- History
```

Quy tắc:

- Backend lấy `userId` từ JWT/SecurityContext.
- Không tin `userId` do Client gửi lên để xác định quyền sở hữu.
- User chỉ được xem, tạo, cập nhật và xóa dữ liệu thuộc tài khoản của mình.
- Không có role `ADMIN`, `USER` hoặc các role khác.
- Catalog là dữ liệu hệ thống, không phải dữ liệu riêng của từng tài khoản.
- Mọi thao tác Playlist, Favorites và History phải kiểm tra ownership.

### 1.3 — Database Migration Rule

Tất cả thay đổi schema phải thực hiện bằng Flyway migration mới.

```text
V1 — Existing Phase 2 migrations
V2 — Existing Phase 3 migrations
Vx — Music Catalog schema
Vx+1 — Playlist schema
Vx+2 — Favorites & History schema
Vx+3 — Sync operation schema (nếu cần)
```

Tên và version thực tế phải tiếp tục từ migration hiện có.

Không được:

```text
❌ Sửa migration đã được áp dụng
❌ Xóa Flyway history
❌ DROP DATABASE
❌ DROP TABLE để tạo lại
❌ TRUNCATE dữ liệu hiện có
❌ Xóa User hoặc Refresh Session
❌ Reset PostgreSQL để né lỗi migration
```

Nếu phát hiện lỗi schema, tạo migration sửa chữa mới theo hướng backward-compatible.

### 1.4 — Data Ownership & Storage Rule

Phân chia dữ liệu:

```text
POSTGRESQL
    ├── Users
    ├── Songs
    ├── Albums
    ├── Artists
    ├── Genres
    ├── Playlists
    ├── Playlist Songs
    ├── Favorites
    ├── History
    └── Sync Operation Records

MEDIA STORAGE
    ├── Audio Files
    └── Artwork Files (nếu được triển khai)

FLUTTER LOCAL STORAGE
    ├── SQLite
    ├── Cached Metadata
    ├── Downloaded Audio
    └── Pending Sync Queue
```

Không lưu file audio dạng binary trực tiếp trong PostgreSQL hoặc SQLite.

Database chỉ lưu metadata và định danh/vị trí lưu trữ của file.

Backend không được ghi đè hoặc xóa file download trên thiết bị người dùng.

### 1.5 — Sample Data Safety Rule

Dữ liệu mẫu chỉ được sử dụng cho môi trường development/test.

```text
DEV / TEST
    ├── Sample Songs
    ├── Sample Albums
    ├── Sample Artists
    ├── Sample Genres
    └── Test Audio Files (nếu có)

PRODUCTION
    └── Chỉ dữ liệu thực tế được cấp phép
```

Không tự động import bài hát hoặc file audio mẫu khi khởi động môi trường production.

Không sử dụng file nhạc có bản quyền khi chưa có quyền sử dụng, phát trực tuyến hoặc phân phối.

Không giả định mọi file có thể truy cập từ Internet đều được phép stream trong ứng dụng.

### 1.6 — Safe Modification Rule

Được phép:

```text
✅ Tạo Entity / DTO / Repository / Service mới
✅ Tạo Controller mới
✅ Tạo Flyway migration mới
✅ Mở rộng source hiện có
✅ Tạo Media Storage Service
✅ Tạo Batch Sync Service
✅ Tạo Postman Collection
✅ Viết Unit / Integration Tests
✅ Bổ sung Index và Constraint
✅ Tạo dữ liệu mẫu riêng cho development/test
```

Không được:

```text
❌ Xóa file hoặc thư mục hiện có
❌ Xóa class, method hoặc feature
❌ Tạo User Entity trùng lặp
❌ Viết lại Authentication
❌ Bỏ qua JWT Security
❌ Bỏ qua ownership verification
❌ Hardcode đường dẫn hoặc credentials production
❌ Lưu audio binary vào database
❌ Đưa sample data vào production mặc định
❌ Thay đổi Flutter source
❌ Tự ý thay đổi API Contract
❌ Commit / push khi chưa được yêu cầu
```

---

## 2. ĐIỀU KIỆN BẮT ĐẦU

Phase 4 được phép bắt đầu khi:

```text
PHASE 1 — Architecture & API Contract DONE
                    +
PHASE 2 — Backend Core & PostgreSQL DONE
                    +
PHASE 3 — Authentication & Security DONE
                    +
Spring Boot hoạt động
                    +
PostgreSQL kết nối thành công
                    +
Flyway hoạt động
                    +
JWT Authentication hoạt động
                    +
API_CONTRACT.md đã được chốt
```

Kiểm tra:

```bash
java -version
```

```bash
mvn test
```

Kiểm tra database và migration hiện tại:

```sql
SELECT *
FROM flyway_schema_history
ORDER BY installed_rank;
```

Nếu project dùng Gradle, sử dụng Gradle Wrapper tương ứng.

### Dependency cần ghi nhận

```text
[DEPENDENCY — MUSIC METADATA]
[DEPENDENCY — LICENSED AUDIO FILES]
[DEPENDENCY — MEDIA STORAGE CONFIGURATION]
[DEPENDENCY — STREAMING TEST FILES]
```

Nếu chưa có dữ liệu bài hát thực tế, có thể tiếp tục xây dựng schema, API và test bằng dữ liệu development hợp lệ.

Không tự tạo dữ liệu production để làm cho API có vẻ hoạt động đầy đủ.

---

## 3. PHẠM VI PHASE 4

### CHỈ LÀM

```text
AQ01 — Music Database Schema
AQ02 — Entity / DTO / Repository / Service
AQ03 — Music Catalog API
AQ04 — Search & Filter API
AQ05 — Audio Streaming API
AQ06 — Playlist CRUD API
AQ07 — Favorites & History API
AQ08 — Batch Synchronization API
AQ09 — Backend Tests & Postman

Music Metadata
Music Relationships
Media Storage Integration
Pagination
Search & Filter
User Ownership
Operation Idempotency
Conflict Handling
Incremental Synchronization
```

### KHÔNG ĐƯỢC LÀM

```text
Spring Boot Initialization
PostgreSQL Core Configuration
User Core Entity
JWT Implementation
Register / Login
Refresh Token
Google Sign-In
Flutter API Integration
Flutter Repository Refactor
Flutter SyncService Integration
Flutter Download UI
Player Background Service
Notification
Local Audio Playback
Sleep Timer
Full E2E Testing
```

Các nội dung trên thuộc Phase 1–3, Phase 5–8.

---

# 4. CÁC TASK THỰC HIỆN

## TASK 4.1 — MUSIC DATABASE SCHEMA (AQ01)

### 🎯 Mục tiêu

Thiết kế và triển khai cấu trúc PostgreSQL cho dữ liệu âm nhạc, Playlist, Favorites và History theo Excel, Use Case và API Contract.

### Cách làm

#### 1. Music Catalog Tables

Tạo các bảng:

```text
songs
albums
artists
genres
```

Mục đích:

| Table | Responsibility |
|---|---|
| songs | Lưu thông tin metadata bài hát |
| albums | Lưu thông tin album |
| artists | Lưu thông tin nghệ sĩ |
| genres | Lưu thể loại nhạc |

Các trường cần đối chiếu với Excel và Use Case.

Ví dụ các thông tin có thể cần:

**songs**

```text
id
title
album_id (nếu có)
genre_id (nếu có)
duration
audio_storage_key
artwork_url (nếu có)
mime_type
file_size
is_available
created_at
updated_at
```

**albums**

```text
id
title
artist_id (nếu quan hệ đơn)
release_date
artwork_url
created_at
updated_at
```

**artists**

```text
id
name
biography (nếu có)
avatar_url (nếu có)
created_at
updated_at
```

**genres**

```text
id
name
description (nếu có)
created_at
updated_at
```

Đây là các field tham khảo; schema cuối cùng phải tuân theo yêu cầu thực tế.

Nếu một bài hát hoặc album có nhiều nghệ sĩ, phải kiểm tra Use Case và thiết kế quan hệ nhiều-nhiều phù hợp. Chỉ tạo bảng liên kết như `song_artists` hoặc `album_artists` khi nghiệp vụ thực sự yêu cầu.

Không ép quan hệ một-nhiều chỉ để giảm số bảng.

#### 2. Playlist Tables

Tạo:

```text
playlists
playlist_songs
```

**playlists**

```text
id
user_id
name
description
cover_url (nếu có)
version (nếu sync yêu cầu)
created_at
updated_at
deleted_at (nếu dùng tombstone)
```

**playlist_songs**

```text
id hoặc khóa theo thiết kế
playlist_id
song_id
position
added_at
```

Yêu cầu:

- Playlist phải thuộc một User.
- `user_id` tham chiếu tới User đã có ở Phase 2.
- Playlist không được trộn dữ liệu giữa các tài khoản.
- Có thứ tự bài hát thông qua `position` nếu Use Case yêu cầu.
- Có ràng buộc khóa phù hợp để tránh bản ghi trùng.
- Xác định rõ một bài hát có được xuất hiện nhiều lần trong cùng Playlist hay không dựa trên Use Case.

#### 3. Favorites Table

Tạo:

```text
favorites
```

Cấu trúc tham khảo:

```text
id
user_id
song_id
created_at
```

Yêu cầu:

- Một User không được tạo Favorite trùng cho cùng một Song.
- Có unique constraint phù hợp trên User và Song.
- Favorite thuộc User đã xác thực.
- Có index phục vụ truy vấn danh sách yêu thích.

#### 4. History Table

Tạo:

```text
history
```

Cấu trúc tham khảo:

```text
id
user_id
song_id
event_id
played_at
created_at
```

Có thể bổ sung:

```text
playback_position
play_duration
```

nếu các Use Case hoặc đồng bộ yêu cầu.

History nên được thiết kế theo dạng sự kiện phát nhạc, không mặc định chỉ có một bản ghi cho mỗi User và Song.

Yêu cầu:

- Một Song có thể xuất hiện nhiều lần trong History của cùng User.
- Có thời điểm phát.
- Có định danh sự kiện để chống gửi trùng khi đồng bộ.
- Có index phục vụ truy vấn lịch sử mới nhất.
- Không sử dụng Unique(User ID, Song ID) nếu muốn giữ nhiều lượt nghe.

#### 5. UUID & Constraints

Tất cả các ID phải tuân thủ UUID Strategy của Phase 1.

Yêu cầu:

```text
Primary Key: UUID
Foreign Key: Enforced
Unique Constraint: Theo nghiệp vụ
Not Null: Theo contract
Index: Theo truy vấn thực tế
Timestamp: UTC
```

Phân biệt:

```text
CATALOG ID
    └── Backend quản lý

USER DATA ID
    └── Client hoặc Backend theo UUID Contract

SYNC OPERATION ID
    └── Client tạo để chống gửi trùng
```

Không sử dụng Auto Increment thay thế UUID đã chốt.

#### 6. Sync Metadata

Nếu Phase 1 xác định cần versioning hoặc tombstone để đồng bộ, bổ sung các trường hoặc cấu trúc liên quan:

```text
version
updated_at
deleted_at
```

Không tự thêm những trường sync không cần thiết vào tất cả bảng.

#### 7. Flyway Migration

Tạo migration mới trong:

```text
src/main/resources/db/migration/
```

Ví dụ:

```text
Vx__create_music_catalog_tables.sql
Vx+1__create_playlist_tables.sql
Vx+2__create_favorites_history_tables.sql
```

Số version thực tế phải tiếp nối migration hiện có.

### DONE

```text
[ ] songs table tồn tại
[ ] albums table tồn tại
[ ] artists table tồn tại
[ ] genres table tồn tại
[ ] playlists table tồn tại
[ ] playlist_songs table tồn tại
[ ] favorites table tồn tại
[ ] history table tồn tại
[ ] UUID Primary Key hoạt động
[ ] Foreign Key hoạt động
[ ] Unique Constraints đúng nghiệp vụ
[ ] Indexes được tạo
[ ] Migration chạy thành công
[ ] Không mất dữ liệu Phase 2–3
[ ] Hibernate validate thành công
```

---

## TASK 4.2 — ENTITY / DTO / REPOSITORY / SERVICE & SAMPLE DATA (AQ02)

### 🎯 Mục tiêu

Tạo lớp xử lý dữ liệu âm nhạc theo schema đã triển khai, bảo đảm phân tách Entity, DTO, Repository và Service.

### Cách làm

#### 1. Entity

Tạo hoặc hoàn thiện:

```text
features/music/
├── song/
│   └── entity/Song.java
├── album/
│   └── entity/Album.java
├── artist/
│   └── entity/Artist.java
├── genre/
│   └── entity/Genre.java
├── playlist/
│   ├── entity/Playlist.java
│   └── entity/PlaylistSong.java
├── favorite/
│   └── entity/Favorite.java
└── history/
    └── entity/History.java
```

Đường dẫn thực tế có thể khác nếu project đã có convention.

Yêu cầu:

- Mapping đúng PostgreSQL Schema.
- Không tự tạo bảng hoặc field khác migration.
- Không trả Entity trực tiếp cho Client.
- Không tạo lại User Entity.
- Quan hệ Entity phải tránh vòng lặp serialization.
- Tránh cấu hình cascade có thể vô tình xóa dữ liệu liên quan.
- Sử dụng transaction phù hợp.

#### 2. DTO

Tạo DTO theo API Contract:

```text
SongResponse
AlbumResponse
ArtistResponse
GenreResponse
PlaylistRequest
PlaylistResponse
FavoriteResponse
HistoryResponse
```

Có thể bổ sung request/response riêng cho từng thao tác.

Yêu cầu:

- Không trả dữ liệu nội bộ không cần thiết.
- Không trả đường dẫn vật lý của Media Storage.
- Không expose thông tin database.
- Không dùng Entity làm Request Body.
- Không nhận `userId` từ Client để quyết định ownership.

#### 3. Repository

Tạo Repository cho từng nhóm:

```text
SongRepository
AlbumRepository
ArtistRepository
GenreRepository
PlaylistRepository
PlaylistSongRepository
FavoriteRepository
HistoryRepository
```

Các truy vấn phải phục vụ đúng API:

```text
Find Songs
Find Albums
Find Artists
Find Genres
Find Playlist by Owner
Find Favorites by Owner
Find History by Owner
Search Catalog
```

Yêu cầu:

- Tránh truy vấn N+1.
- Có pagination.
- Có index phục vụ truy vấn.
- Không tải toàn bộ dữ liệu vào RAM chỉ để phân trang.
- Không cho Repository Playlist/Favorites/History truy vấn dữ liệu mà bỏ qua ownership.

#### 4. Service

Tạo Service theo nghiệp vụ:

```text
SongService
AlbumService
ArtistService
GenreService
PlaylistService
FavoriteService
HistoryService
```

Trách nhiệm:

- Kiểm tra dữ liệu đầu vào.
- Xử lý nghiệp vụ.
- Kiểm tra quyền sở hữu.
- Gọi Repository.
- Ánh xạ dữ liệu sang DTO.
- Quản lý transaction.
- Trả kết quả thống nhất.

#### 5. Sample Data

Tạo dữ liệu mẫu riêng:

```text
src/test/resources/
    └── music-test-data.sql

src/main/resources/
    └── db/
        └── seed/
            └── development/
```

Chỉ sử dụng seed script nếu được bật bởi profile development hoặc một tác vụ khởi tạo rõ ràng.

Quy tắc:

```text
DEV:
    Có thể nạp sample data

TEST:
    Sử dụng fixture / test data riêng

PRODUCTION:
    Không tự động nạp sample data
```

Nếu có file audio test, chỉ sử dụng file được cấp phép hoặc tự tạo hợp lệ.

Không tải nhạc bản quyền từ nguồn không được phép.

### DONE

```text
[ ] Entity mapping chính xác
[ ] DTO đầy đủ theo contract
[ ] Repository hoạt động
[ ] Service hoạt động
[ ] UUID và relationships đúng
[ ] Không truy cập chéo User
[ ] Không có truy vấn N+1 nghiêm trọng
[ ] Sample data chỉ được kích hoạt trong DEV/TEST
[ ] Production không tự động nạp sample data
```

---

## TASK 4.3 — MUSIC CATALOG API (AQ03)

### 🎯 Mục tiêu

Cung cấp API để Flutter có thể lấy danh sách và chi tiết các đối tượng âm nhạc.

### Cách làm

Triển khai theo API Contract.

Các nhóm API:

```text
SONGS
    ├── List Songs
    └── Song Detail

ALBUMS
    ├── List Albums
    └── Album Detail

ARTISTS
    ├── List Artists
    └── Artist Detail

GENRES
    ├── List Genres
    └── Genre Detail
```

Endpoint minh họa:

```text
GET /api/songs
GET /api/songs/{id}

GET /api/albums
GET /api/albums/{id}

GET /api/artists
GET /api/artists/{id}

GET /api/genres
GET /api/genres/{id}
```

Không tạo endpoint trùng nếu API Contract đã định nghĩa đường dẫn khác.

#### 1. Song Catalog

Trả các trường cần thiết:

```text
id
title
artist information
album information
genre information
duration
artwork
availability
```

Không trả đường dẫn vật lý của audio file.

#### 2. Album Catalog

Trả:

```text
id
title
artists
artwork
releaseDate (nếu có)
songCount
```

#### 3. Artist Catalog

Trả:

```text
id
name
biography (nếu có)
avatar
albums (nếu cần)
songs (nếu cần)
```

#### 4. Genre Catalog

Trả:

```text
id
name
description (nếu có)
```

#### 5. Pagination

Các API danh sách phải hỗ trợ phân trang theo contract.

Ví dụ:

```text
GET /api/songs?page=0&size=20
```

Yêu cầu:

- Có page và size hợp lệ.
- Có giới hạn page size tối đa.
- Có thông tin tổng số bản ghi nếu contract yêu cầu.
- Có sort hợp lệ.
- Không trả hàng nghìn bản ghi trong một response mặc định.

#### 6. Data Availability

Chỉ trả những bài hát được đánh dấu có thể truy cập hoặc được phép phát.

Không hiển thị file audio không tồn tại như một nội dung streaming khả dụng.

### DONE

```text
[ ] API Songs hoạt động
[ ] API Song Detail hoạt động
[ ] API Albums hoạt động
[ ] API Album Detail hoạt động
[ ] API Artists hoạt động
[ ] API Artist Detail hoạt động
[ ] API Genres hoạt động
[ ] API Genre Detail hoạt động
[ ] Pagination hoạt động
[ ] Response đúng API Contract
[ ] Không expose physical storage path
```

---

## TASK 4.4 — SEARCH & FILTER API (AQ04)

### 🎯 Mục tiêu

Cho phép tìm kiếm và lọc nội dung âm nhạc theo yêu cầu của WaveBox.

### Cách làm

Triển khai tìm kiếm:

```text
Search Songs
Search Albums
Search Artists
Search Genres (nếu requirement yêu cầu)
```

Các tiêu chí cần đối chiếu Excel:

```text
Song Title
Artist Name
Album Name
Genre
```

Ví dụ:

```text
GET /api/search?q=music
```

Hoặc endpoint Search đã được định nghĩa trong API Contract.

#### 1. Search Logic

Yêu cầu:

- Có xử lý chuỗi rỗng.
- Chuẩn hóa khoảng trắng.
- Xác định quy tắc tìm kiếm không phân biệt chữ hoa/chữ thường.
- Có xử lý ký tự đặc biệt an toàn.
- Không ghép SQL bằng chuỗi tùy tiện.
- Có giới hạn số kết quả.
- Có phân trang.

#### 2. Filter Logic

Các bộ lọc phải theo requirement thực tế, có thể gồm:

```text
Artist
Album
Genre
Availability
Duration Range
Release Date
```

Không tự thêm bộ lọc không có nhu cầu nghiệp vụ.

#### 3. Sort

Chỉ cho phép sort theo các trường đã xác định.

Ví dụ:

```text
title
createdAt
releaseDate
duration
```

Không cho Client truyền trực tiếp tên cột SQL.

#### 4. Database Performance

- Có index cho cột được tìm kiếm thường xuyên.
- Kiểm tra execution plan khi cần.
- Tránh full table scan trên dataset lớn nếu có phương án phù hợp.
- Chọn cơ chế search theo khả năng PostgreSQL và dữ liệu thực tế.
- Không triển khai Elasticsearch nếu chưa có yêu cầu và chưa được chốt kiến trúc.

### DONE

```text
[ ] Search Song hoạt động
[ ] Search Artist hoạt động
[ ] Search Album hoạt động
[ ] Filter hoạt động
[ ] Sort hoạt động
[ ] Pagination hoạt động
[ ] Empty Query được xử lý
[ ] Special Characters được xử lý
[ ] SQL Injection không xảy ra
[ ] Query Performance được kiểm tra
```

---

## TASK 4.5 — AUDIO STREAMING API (AQ05)

### 🎯 Mục tiêu

Xây dựng API phát audio từ Backend, hỗ trợ Flutter lấy dữ liệu âm thanh trực tuyến và không tải toàn bộ file vào bộ nhớ Server.

### Cách làm

#### 1. Media Storage Architecture

Tạo abstraction:

```text
MediaStorageService
       |
       +-- LocalMediaStorage
       |
       +-- ObjectStorage (nếu được triển khai)
```

Backend phải có khả năng đọc file từ Media Storage thông qua một interface thống nhất.

Database chỉ lưu:

```text
audio_storage_key
mime_type
file_size
availability
```

Không lưu:

```text
Audio Binary in PostgreSQL
Absolute Server Path in API Response
Hardcoded Local Path in Controller
```

Nếu dùng local filesystem trong development, đường dẫn phải cấu hình qua environment.

#### 2. Streaming API

Endpoint minh họa:

```text
GET /api/songs/{id}/stream
```

Endpoint thực tế phải theo API Contract.

Luồng:

```text
Flutter Request
       ↓
Backend Verify Authentication
       ↓
Find Song Metadata
       ↓
Check Availability
       ↓
Resolve Media Storage Key
       ↓
Open Audio Resource
       ↓
Read Range / Stream
       ↓
Return Audio Response
```

Quyền truy cập streaming phải đúng theo quyết định ở Phase 1 và API Contract.

Không mặc định tất cả bài hát đều cần đăng nhập hoặc tất cả đều công khai.

#### 3. HTTP Streaming Requirements

Bắt buộc hỗ trợ:

```text
Content-Type
Content-Length (khi biết)
Accept-Ranges: bytes
Range Request
206 Partial Content
Content-Range
416 Range Not Satisfiable
```

Khi Client gửi:

```text
Range: bytes=0-1023
```

Backend phải trả phần dữ liệu tương ứng nếu nguồn lưu trữ hỗ trợ Range.

Nếu file không có Range Request:

```text
200 OK
```

Nếu Range hợp lệ:

```text
206 Partial Content
```

Nếu Range không hợp lệ:

```text
416 Range Not Satisfiable
```

Cần xử lý đúng:

- File không tồn tại.
- Song ID không tồn tại.
- File không khả dụng.
- MIME type không hợp lệ.
- Range vượt kích thước file.
- Lỗi đọc Media Storage.
- Client ngắt kết nối.

#### 4. Memory & Performance

Không đọc toàn bộ audio file vào `byte[]` chỉ để trả response đối với file lớn.

Ưu tiên:

```text
Streaming Response
Resource Streaming
File Channel / Seek
Range-based Reading
```

Yêu cầu:

- Không giữ toàn bộ file trong RAM.
- Đóng stream đúng cách.
- Không để request bị treo khi Client ngắt kết nối.
- Có giới hạn kết nối và timeout phù hợp.
- Không expose physical file path.
- Không cho phép Path Traversal.

#### 5. Audio File Validation

Khi kiểm tra media:

- Xác định MIME type phù hợp.
- Không chỉ tin phần mở rộng file.
- Đối chiếu file tồn tại và metadata.
- Không cho phép truy cập file ngoài vùng Media Storage.
- Không trả nội dung file trái phép.

#### 6. Licensing & Production

Chỉ stream file:

```text
Owned / Licensed / Authorized / Public Domain
```

Không tự động sử dụng file nhạc mẫu hoặc lấy nhạc từ nguồn bên ngoài không được cấp quyền.

Không biến một URL bên ngoài thành nguồn stream của WaveBox nếu chưa có quyền hoặc chưa có yêu cầu kiến trúc.

### DONE

```text
[ ] MediaStorageService hoạt động
[ ] Song Metadata liên kết đúng Audio File
[ ] Streaming API hoạt động
[ ] Content-Type chính xác
[ ] Range Request hoạt động
[ ] 206 Partial Content đúng
[ ] 416 được xử lý
[ ] Không tải toàn bộ file lớn vào RAM
[ ] Không có Path Traversal
[ ] File không tồn tại được xử lý
[ ] Không expose physical path
[ ] Chỉ sử dụng audio được phép phát
```

---

## TASK 4.6 — PLAYLIST CRUD API (AQ06)

### 🎯 Mục tiêu

Cho phép User tạo, xem, cập nhật và xóa Playlist, đồng thời quản lý danh sách bài hát trong từng Playlist.

### Cách làm

API phải tuân theo API Contract.

Các thao tác nghiệp vụ:

```text
Create Playlist
Get My Playlists
Get Playlist Detail
Update Playlist
Delete Playlist
Add Song to Playlist
Remove Song from Playlist
Reorder Playlist Songs (nếu yêu cầu)
```

Endpoint minh họa:

```text
POST   /api/playlists
GET    /api/playlists
GET    /api/playlists/{id}
PATCH  /api/playlists/{id}
DELETE /api/playlists/{id}

POST   /api/playlists/{id}/songs
DELETE /api/playlists/{id}/songs/{songId}
```

Không thay đổi PUT/PATCH đã chốt ở Phase 1.

#### 1. Create Playlist

Luồng:

```text
Request
   ↓
Verify JWT
   ↓
Get Authenticated User ID
   ↓
Validate Playlist Data
   ↓
Create Playlist Entity
   ↓
Save PostgreSQL
   ↓
Return Playlist DTO
```

`userId` phải được lấy từ Authentication Context.

#### 2. Read Playlist

Khi lấy danh sách:

- Chỉ trả Playlist của User hiện tại.
- Có pagination nếu cần.
- Có thứ tự theo contract.

Khi lấy chi tiết:

- Kiểm tra Playlist tồn tại.
- Kiểm tra Playlist thuộc User hiện tại.
- Trả danh sách bài hát và đúng thứ tự.

#### 3. Update Playlist

Chỉ cho phép cập nhật các trường nghiệp vụ đã được định nghĩa.

Không cho Client sửa:

```text
id
userId
createdAt
internalVersion
```

trừ khi contract quy định rõ.

#### 4. Delete Playlist

- Kiểm tra ownership.
- Xóa hoặc đánh dấu xóa theo chiến lược sync đã chốt.
- Xử lý các bản ghi `playlist_songs`.
- Không ảnh hưởng Playlist của User khác.
- Không xóa Song Catalog khi xóa Playlist.

#### 5. Playlist Songs

Hỗ trợ theo Use Case:

```text
Add Song
Remove Song
Get Songs
Update Position
```

Phải kiểm tra Song có tồn tại và khả dụng theo nghiệp vụ.

Sử dụng transaction cho thao tác cần cập nhật nhiều bản ghi.

Không tự ý thêm chức năng chia sẻ Playlist công khai nếu requirement không yêu cầu.

### DONE

```text
[ ] Create Playlist hoạt động
[ ] List Playlist hoạt động
[ ] Get Playlist Detail hoạt động
[ ] Update Playlist hoạt động
[ ] Delete Playlist hoạt động
[ ] Add Song hoạt động
[ ] Remove Song hoạt động
[ ] Reorder hoạt động nếu được yêu cầu
[ ] User A không truy cập Playlist User B
[ ] Không xóa Song khi xóa Playlist
[ ] Dữ liệu quan hệ chính xác
```

---

## TASK 4.7 — FAVORITES & HISTORY API (AQ07)

### 🎯 Mục tiêu

Triển khai API quản lý danh sách bài hát yêu thích và lịch sử nghe nhạc của từng User.

### 4.7.1 — Favorites

Các thao tác:

```text
Add Favorite
Remove Favorite
Get My Favorites
Check Favorite Status (nếu yêu cầu)
```

Endpoint minh họa:

```text
POST   /api/favorites
GET    /api/favorites
DELETE /api/favorites/{songId}
```

Luồng:

```text
Request
   ↓
Verify JWT
   ↓
Get User ID
   ↓
Validate Song
   ↓
Check Existing Favorite
   ↓
Create / Remove Favorite
   ↓
Return Result
```

Yêu cầu:

- Favorite thuộc User hiện tại.
- Không tạo Favorite trùng.
- Có unique constraint ở database.
- Xử lý request lặp lại theo nguyên tắc idempotent nếu contract quy định.
- Không xóa Song Catalog khi bỏ Favorite.

### 4.7.2 — History

Các thao tác:

```text
Record Listening Event
Get Listening History
Remove History Item (nếu yêu cầu)
Clear History (nếu yêu cầu)
```

Endpoint minh họa:

```text
POST   /api/history
GET    /api/history
DELETE /api/history/{id}
```

Luồng:

```text
Playback Event
       ↓
Verify JWT
       ↓
Get User ID
       ↓
Validate Song
       ↓
Create History Event
       ↓
Save PostgreSQL
       ↓
Return Result
```

Yêu cầu:

- History thuộc User hiện tại.
- Mỗi sự kiện nghe có định danh riêng.
- Không ghi trùng cùng một sự kiện do retry.
- Cho phép cùng một Song xuất hiện nhiều lần trong lịch sử.
- Có pagination và sort theo thời gian.
- Không sử dụng timestamp Client làm căn cứ duy nhất để phân xử xung đột.
- Nếu request đến từ offline sync, phải giữ nguyên event identity theo Sync Contract.

Không tự xóa lịch sử cũ nếu requirement không yêu cầu.

### DONE

```text
[ ] Add Favorite hoạt động
[ ] Remove Favorite hoạt động
[ ] Get Favorites hoạt động
[ ] Favorite không bị trùng
[ ] Record History hoạt động
[ ] Get History hoạt động
[ ] Một Song có thể xuất hiện nhiều lần trong History
[ ] Event ID chống ghi trùng
[ ] Pagination hoạt động
[ ] User A không xem Favorites/History User B
```

---

## TASK 4.8 — BATCH SYNCHRONIZATION API (AQ08)

### 🎯 Mục tiêu

Xây dựng Backend API tiếp nhận và xử lý nhiều thao tác đồng bộ dữ liệu từ Flutter, bảo đảm không tạo bản ghi trùng và không làm trộn dữ liệu giữa các tài khoản.

Batch Sync Backend được triển khai ở Phase 4.

Việc tích hợp Queue, Connectivity và Sync UI phía Flutter thuộc Phase 7.

### 1. Sync Architecture

Luồng:

```text
Flutter
   |
   | Batch Operations
   ↓
Spring Boot Sync API
   |
   ↓
JWT Authentication
   |
   ↓
Get Authenticated User ID
   |
   ↓
Validate Batch
   |
   ↓
Check Operation ID
   |
   ↓
Process Operations
   |
   +---- Applied
   +---- Duplicate
   +---- Conflict
   +---- Rejected
   |
   ↓
Persist Database
   |
   ↓
Return Result Per Operation
   |
   ↓
Flutter Acknowledge Results
```

### 2. Batch Request Contract

Tuân thủ chính xác `docs/API_CONTRACT.md`.

Cấu trúc minh họa:

```json
{
  "batchId": "uuid",
  "operations": [
    {
      "operationId": "uuid",
      "entityType": "PLAYLIST",
      "entityId": "uuid",
      "action": "CREATE",
      "clientSequence": 1,
      "baseVersion": null,
      "occurredAt": "2026-11-13T10:00:00Z",
      "payload": {
        "name": "My Playlist"
      }
    }
  ]
}
```

Các operation dự kiến có thể bao gồm:

```text
PLAYLIST
    CREATE
    UPDATE
    DELETE
    ADD_SONG
    REMOVE_SONG

FAVORITE
    ADD
    REMOVE

HISTORY
    APPEND
```

Danh sách action chính thức phải khớp requirement và API Contract.

Không cho Client gửi operation để sửa trực tiếp Music Catalog nếu nghiệp vụ quy định Catalog chỉ do Backend quản lý.

### 3. Batch Operation Validation

Mỗi operation cần kiểm tra:

```text
operationId
entityType
entityId
action
clientSequence
baseVersion (nếu cần)
occurredAt
payload
```

Yêu cầu:

- `operationId` hợp lệ.
- `entityType` nằm trong danh sách cho phép.
- `action` phù hợp với entity.
- `payload` đúng schema.
- UUID hợp lệ.
- Song/Playlist tồn tại khi thao tác cần tham chiếu.
- User có quyền sở hữu dữ liệu.
- Kích thước batch và payload có giới hạn.
- Không cho operation tác động sang User khác.

Không tin `userId` từ payload. Owner luôn được xác định từ JWT.

### 4. Idempotency

Đây là yêu cầu bắt buộc.

Tạo bảng hoặc cơ chế lưu dấu operation đã xử lý, ví dụ:

```text
sync_operations
---------------
operation_id
user_id
entity_type
entity_id
action
status
result_payload
processed_at
```

Tên và schema cuối cùng theo Decision Log.

Quy tắc:

```text
Same operationId
       ↓
Already Processed?
       |
    +--+--+
    |     |
   YES    NO
    |     |
Return   Process
Previous Operation
Result
```

Yêu cầu:

- Cùng User và `operationId` không được tạo dữ liệu trùng.
- Retry operation đã thành công phải trả kết quả phù hợp.
- Không xử lý lại operation theo cách gây side effect lần thứ hai.
- Unique constraint ở database là lớp bảo vệ cuối cùng.
- Việc ghi operation result và thay đổi dữ liệu phải có transaction phù hợp.
- Operation của User A không được dùng để thao tác dữ liệu User B.

Nếu cùng `operationId` nhưng payload khác, phải phát hiện và trả conflict hoặc lỗi theo Contract.

### 5. Per-operation Result

Response minh họa:

```json
{
  "batchId": "uuid",
  "results": [
    {
      "operationId": "uuid",
      "status": "APPLIED",
      "serverVersion": 1,
      "serverUpdatedAt": "2026-11-13T10:00:01Z",
      "error": null
    },
    {
      "operationId": "uuid",
      "status": "DUPLICATE",
      "serverVersion": 1,
      "error": null
    }
  ]
}
```

Các trạng thái:

```text
APPLIED
DUPLICATE
CONFLICT
REJECTED
```

Mỗi operation phải có kết quả tương ứng.

Không trả một kết quả chung khiến Client không biết operation nào thành công và operation nào thất bại.

Nếu API Contract đã chốt xử lý theo kiểu atomic batch thay vì per-operation, phải giữ nguyên contract và điều chỉnh phần xử lý tương ứng; không tự đổi semantics.

### 6. Conflict Resolution

Sử dụng quyết định đã chốt trong Phase 1.

Ma trận đề xuất:

| Data | Conflict Rule |
|---|---|
| Playlist Metadata | Version / baseVersion |
| Playlist Songs | Xử lý theo operation và thứ tự |
| Favorites | Add/Remove idempotent, khóa User + Song |
| History | Append-only, chống trùng bằng event ID |
| Catalog | Backend là nguồn dữ liệu chính |

Yêu cầu:

- Không mặc định Last Write Wins cho mọi dữ liệu.
- Không tin đồng hồ Client tuyệt đối.
- Không cập nhật dữ liệu nếu version không thỏa điều kiện.
- Phải trả trạng thái conflict rõ ràng.
- Không âm thầm bỏ qua operation.

### 7. Incremental Pull / Restore

Nếu API Contract đã định nghĩa Pull Sync, triển khai khả năng lấy dữ liệu thay đổi từ Server.

Thông tin có thể gồm:

```text
cursor
since
lastSyncAt
serverVersion
nextCursor
hasMore
```

Phải ưu tiên cursor hoặc version ổn định nếu có thể, tránh chỉ dựa vào thời gian Client.

Đảm bảo:

- Phân trang khi dữ liệu lớn.
- Có thể tiếp tục từ cursor.
- Không bỏ sót bản ghi khi nhiều thay đổi cùng thời điểm.
- Xử lý tombstone cho dữ liệu đã xóa.
- Chỉ trả dữ liệu thuộc User hiện tại.
- Catalog được lấy qua Catalog API riêng, không đẩy toàn bộ Catalog vào Batch Sync cá nhân.

Không đồng bộ file audio binary qua Batch Sync.

Không tải file nhạc qua batch metadata. Audio Download là nghiệp vụ của Phase 6.

### 8. Retry & Failure Handling

Backend phải xử lý:

```text
Invalid Operation
Duplicate Operation
Ownership Violation
Resource Not Found
Version Conflict
Database Failure
Partial Batch Failure
```

Quy tắc:

- Operation lỗi không được đánh dấu thành công.
- Retry phải không tạo dữ liệu trùng.
- Không mất operation đã được ghi nhận nhưng chưa trả response.
- Có log theo `operationId` để truy vết.
- Không ghi refresh token hoặc dữ liệu nhạy cảm vào log.

### DONE

```text
[ ] Batch API hoạt động
[ ] Nhận nhiều operations
[ ] Validation từng operation
[ ] User ID lấy từ JWT
[ ] Ownership được kiểm tra
[ ] operationId đảm bảo idempotency
[ ] Retry không tạo dữ liệu trùng
[ ] APPLIED hoạt động
[ ] DUPLICATE hoạt động
[ ] CONFLICT hoạt động
[ ] REJECTED hoạt động
[ ] Result được trả riêng từng operation
[ ] Transaction phù hợp
[ ] Pull / Restore hoạt động nếu contract yêu cầu
[ ] Tombstone hoạt động nếu được thiết kế
[ ] Không đồng bộ audio binary
```

---

## TASK 4.9 — BACKEND TESTS & POSTMAN (AQ09)

### 🎯 Mục tiêu

Kiểm thử toàn bộ API Music Data và Batch Sync trên Backend thực tế.

### Cách làm

#### 1. Unit Tests

Kiểm tra:

```text
SongService
AlbumService
ArtistService
GenreService
PlaylistService
FavoriteService
HistoryService
MediaStorageService
SyncService
```

Tùy theo cấu trúc thực tế, không bắt buộc tách class nếu nghiệp vụ đã được tổ chức hợp lý.

#### 2. Integration Tests

Sử dụng PostgreSQL thực tế hoặc Testcontainers nếu môi trường hỗ trợ.

Kiểm tra:

```text
Flyway Music Migrations
Entity Mapping
Repository Queries
Foreign Keys
Unique Constraints
Catalog API
Search API
Playlist CRUD
Favorites API
History API
Batch Sync API
```

Không chỉ dựa vào H2 để xác nhận toàn bộ hành vi PostgreSQL.

#### 3. Streaming Tests

Chuẩn bị audio fixture hợp lệ trong môi trường test.

Kiểm tra:

```text
Existing Audio File
Missing Audio File
Wrong Song ID
Content-Type
Content-Length
Range Request
206 Partial Content
416 Range Not Satisfiable
Invalid Storage Key
Path Traversal Attempt
Client Disconnect (nếu kiểm thử được)
```

Không cần đưa audio fixture vào production.

#### 4. Ownership Security Tests

Tạo:

```text
User A
User B
```

Kiểm thử:

```text
User A → Playlist A: ALLOWED
User A → Playlist B: DENIED

User A → Favorites A: ALLOWED
User A → Favorites B: DENIED

User A → History A: ALLOWED
User A → History B: DENIED

User A → Batch Operation for User B: DENIED
```

Kiểm tra cả trường hợp Client cố gửi `userId` của người khác trong payload.

#### 5. Sync Tests

Kịch bản:

```text
1. Gửi batch hợp lệ
2. Xác nhận operation thành công
3. Gửi lại cùng operationId
4. Xác nhận không tạo dữ liệu trùng
5. Gửi operation conflict
6. Xác nhận trạng thái conflict
7. Gửi operation không hợp lệ
8. Xác nhận bị rejected
9. Kiểm tra dữ liệu PostgreSQL
```

#### 6. Postman Collection

Tạo:

```text
postman/
├── WaveBox-Music-Data.postman_collection.json
└── WaveBox-Music-Local.postman_environment.json.example
```

Các nhóm:

```text
CATALOG
    List Songs
    Song Detail
    List Albums
    Album Detail
    List Artists
    Artist Detail
    List Genres
    Genre Detail

SEARCH
    Search Songs
    Search Artists
    Search Albums
    Filter Catalog

STREAMING
    Stream Song
    Range Request
    Invalid Song
    Invalid Range

PLAYLIST
    Create
    List
    Detail
    Update
    Delete
    Add Song
    Remove Song

FAVORITES
    Add
    List
    Remove
    Duplicate Add

HISTORY
    Record
    List
    Duplicate Event
    Pagination

SYNC
    Submit Batch
    Duplicate Operation
    Conflict Operation
    Invalid Operation
    Ownership Violation
    Pull Changes
```

Sử dụng token từ môi trường Postman hoặc collection Phase 3.

Không hardcode token hoặc credentials vào Collection.

### DONE

```text
[ ] Unit Tests PASS
[ ] PostgreSQL Integration Tests PASS
[ ] Catalog Tests PASS
[ ] Search Tests PASS
[ ] Streaming Tests PASS
[ ] Playlist Tests PASS
[ ] Favorites Tests PASS
[ ] History Tests PASS
[ ] Batch Sync Tests PASS
[ ] Two-User Ownership Tests PASS
[ ] Postman Collection đầy đủ
[ ] Không lộ credentials
```

---

## TASK 4.10 — DOCUMENTATION & PHASE 4 REPORT

### 🎯 Mục tiêu

Hoàn thiện tài liệu để Phase 5 và Phase 7 có thể sử dụng Backend APIs mà không cần tự suy luận request/response.

Tạo:

```text
docs/REPORT/PHASE-4-MUSIC-DATA.md
```

Postman:

```text
postman/WaveBox-Music-Data.postman_collection.json
postman/WaveBox-Music-Local.postman_environment.json.example
```

Cập nhật nếu cần:

```text
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
```

Chỉ cập nhật Contract khi có thay đổi được thống nhất và phải ghi nhận tác động đến Flutter.

Báo cáo tối thiểu:

```markdown
# PHASE 4 — BACKEND MUSIC DATA REPORT

## 1. Environment
- Java
- Spring Boot
- PostgreSQL
- Flyway

## 2. Database Schema
- Songs
- Albums
- Artists
- Genres
- Playlists
- Playlist Songs
- Favorites
- History
- Sync Operations (nếu có)

## 3. Entity / DTO / Repository / Service

## 4. Music Catalog API

## 5. Search & Filter API

## 6. Audio Streaming
- Storage Backend
- Range Support
- MIME Type
- Streaming Test Results

## 7. Playlist CRUD

## 8. Favorites & History

## 9. Batch Synchronization
- Request / Response
- Idempotency
- Conflict Handling
- Pull / Restore

## 10. Postman Collection

## 11. Test Results

## 12. Known Issues & Dependencies

## 13. Phase 4 Acceptance
- Completed Tasks
- Pending Tasks
- Final Status
```

### DONE

```text
[ ] Phase 4 Report tồn tại
[ ] Postman Collection có đầy đủ
[ ] API Contract được đồng bộ
[ ] Decision Log được cập nhật
[ ] Database Schema được mô tả
[ ] Media Storage được mô tả
[ ] Batch Sync được mô tả
[ ] Test Results có bằng chứng
```

---

# 5. PHASE 4 FINAL REVIEW

## 🎯 Mục tiêu

Kiểm tra toàn bộ AQ01–AQ09 trước khi bàn giao Backend cho Phase 5 và Phase 7.

### DONE Checklist

```text
[ ] TASK 4.1 — Music Database Schema
[ ] songs table
[ ] albums table
[ ] artists table
[ ] genres table
[ ] playlists table
[ ] playlist_songs table
[ ] favorites table
[ ] history table
[ ] UUID / Foreign Key / Unique Constraint
[ ] Migration chạy thành công

[ ] TASK 4.2 — Entity / DTO / Repository / Service
[ ] Entity mapping chính xác
[ ] DTO đúng API Contract
[ ] Repository hoạt động
[ ] Service hoạt động
[ ] Sample Data chỉ chạy trong DEV/TEST

[ ] TASK 4.3 — Catalog API
[ ] Songs API
[ ] Albums API
[ ] Artists API
[ ] Genres API
[ ] Pagination

[ ] TASK 4.4 — Search & Filter
[ ] Search hoạt động
[ ] Filter hoạt động
[ ] Sort hoạt động
[ ] Query an toàn
[ ] Performance được kiểm tra

[ ] TASK 4.5 — Audio Streaming
[ ] Media Storage Service
[ ] Streaming API
[ ] Range Request
[ ] 206 Partial Content
[ ] 416 Range Not Satisfiable
[ ] Không expose physical path
[ ] File hợp lệ và được phép phát

[ ] TASK 4.6 — Playlist CRUD
[ ] Create
[ ] Read
[ ] Update
[ ] Delete
[ ] Add Song
[ ] Remove Song
[ ] Ownership Verification

[ ] TASK 4.7 — Favorites & History
[ ] Add / Remove Favorites
[ ] Get Favorites
[ ] Record History
[ ] Get History
[ ] Idempotency
[ ] Ownership Verification

[ ] TASK 4.8 — Batch Sync
[ ] Batch Request Validation
[ ] Per-operation Result
[ ] Idempotency
[ ] Duplicate Handling
[ ] Conflict Handling
[ ] Ownership Verification
[ ] Retry Safety
[ ] Pull / Restore nếu contract yêu cầu

[ ] TASK 4.9 — Tests & Postman
[ ] Unit Tests PASS
[ ] Integration Tests PASS
[ ] Streaming Tests PASS
[ ] Ownership Tests PASS
[ ] Batch Sync Tests PASS
[ ] Postman Collection đầy đủ

[ ] TASK 4.10 — Documentation
[ ] Phase 4 Report
[ ] API Contract đồng bộ
[ ] Decision Log cập nhật

[ ] Không sửa Flutter source
[ ] Không làm hỏng Phase 1–3
[ ] Không xóa dữ liệu hiện có
[ ] Git status đã được kiểm tra
```

---

# 6. ĐIỀU KIỆN PHASE 4 DONE

Chỉ được đánh dấu hoàn thành khi có bằng chứng:

**1. Database**

```text
Music Schema: PASS
Flyway Migration: PASS
Entity Mapping: PASS
Foreign Keys: PASS
Unique Constraints: PASS
```

**2. Catalog & Search**

```text
Songs API: PASS
Albums API: PASS
Artists API: PASS
Genres API: PASS
Search: PASS
Filter: PASS
Pagination: PASS
```

**3. Streaming**

```text
Audio File Exists: PASS
Streaming API: PASS
Content-Type: PASS
Range Request: PASS
206 Partial Content: PASS
Invalid Range: 416
Media Storage Security: PASS
```

**4. User Data**

```text
Playlist CRUD: PASS
Favorites: PASS
History: PASS
Ownership Verification: PASS
Cross-user Access: DENIED
```

**5. Batch Synchronization**

```text
Batch Request: PASS
Multiple Operations: PASS
Idempotency: PASS
Duplicate Detection: PASS
Conflict Handling: PASS
Per-operation Results: PASS
Ownership Verification: PASS
```

**6. Documentation & Tests**

```text
Backend Tests: PASS
Postman Collection: READY
API Contract: CONSISTENT
Phase 4 Report: COMPLETE
```

Nếu một phần chưa triển khai hoặc thiếu dữ liệu:

```text
[PASS]
[FAILED]
[NOT TESTED]
[BLOCKED]
```

Không đánh dấu Streaming PASS nếu chỉ trả được response thành công nhưng không phát được file hợp lệ.

Không đánh dấu Batch Sync PASS nếu chỉ nhận được JSON mà chưa kiểm chứng dữ liệu thực tế trong PostgreSQL.

Không đánh dấu Ownership PASS nếu chưa thử truy cập chéo giữa ít nhất hai User.

---

# 7. STOP RULE

Sau khi hoàn thành Phase 4:

**DỪNG.**

Không tự chuyển sang tích hợp Flutter.

Không tự triển khai:

```text
Flutter Auth Integration
Flutter ApiClient Changes
Login / Register Screens
Profile Screen
Google Sign-In UI
Search Online UI
Album / Artist / Genre Screens
Player Background Service
Download Service
Offline Sync Integration
SQLite Repository Refactor
```

Các phần này thuộc Phase 5–7.

Chỉ khi người dùng xác nhận:

```text
PHASE 4 DONE
```

mới chuyển sang:

```text
PHASE 5 — FLUTTER AUTHENTICATION & API INTEGRATION
```

---

# 8. TỔNG KẾT CẤU TRÚC PHASE 4

```text
PHASE 4 — BACKEND MUSIC DATA
│
├── TASK 4.1
│   └── Music Database Schema (AQ01)
│
├── TASK 4.2
│   └── Entity / DTO / Repository / Service
│       & Sample Data (AQ02)
│
├── TASK 4.3
│   └── Music Catalog API (AQ03)
│
├── TASK 4.4
│   └── Search & Filter API (AQ04)
│
├── TASK 4.5
│   └── Audio Streaming API (AQ05)
│
├── TASK 4.6
│   └── Playlist CRUD API (AQ06)
│
├── TASK 4.7
│   └── Favorites & History API (AQ07)
│
├── TASK 4.8
│   └── Batch Synchronization API (AQ08)
│
├── TASK 4.9
│   └── Backend Tests & Postman (AQ09)
│
├── TASK 4.10
│   └── Documentation & Report
│
└── TASK 4.11
    └── Final Review & Stop
```

---

# 9. THỨ TỰ THỰC THI

```text
READ PHASE 1–3 DOCUMENTS
           ↓
AUDIT EXISTING BACKEND
           ↓
CREATE MUSIC DATABASE MIGRATIONS
           ↓
IMPLEMENT ENTITY / DTO / REPOSITORY
           ↓
IMPLEMENT SERVICE
           ↓
IMPLEMENT CATALOG API
           ↓
IMPLEMENT SEARCH & FILTER
           ↓
IMPLEMENT MEDIA STORAGE
           ↓
IMPLEMENT AUDIO STREAMING
           ↓
IMPLEMENT PLAYLIST CRUD
           ↓
IMPLEMENT FAVORITES & HISTORY
           ↓
IMPLEMENT BATCH SYNC
           ↓
RUN UNIT & INTEGRATION TESTS
           ↓
CREATE POSTMAN COLLECTION
           ↓
WRITE PHASE 4 REPORT
           ↓
FINAL REVIEW
           ↓
PHASE 4 DONE
           ↓
STOP
```

---

## NGUYÊN TẮC QUAN TRỌNG NHẤT

Phase 4 là giai đoạn xây dựng **Backend quản lý dữ liệu âm nhạc và dữ liệu cá nhân của User**.

Phải bảo đảm:

- Catalog do Backend quản lý.
- Playlist, Favorites và History thuộc đúng User.
- Audio được lưu trong Media Storage, không lưu binary trong PostgreSQL.
- Streaming hoạt động đúng với HTTP Range.
- Batch Sync có idempotency, xử lý conflict và không mất dữ liệu.
- Dữ liệu mẫu được tách biệt hoàn toàn khỏi production.

**Backend phải hoàn thành và kiểm thử được API trước khi Flutter tích hợp.** Phase 5 sẽ sử dụng Authentication API; Phase 7 sẽ tích hợp Music API, Batch Sync và cơ chế Offline-first vào ứng dụng Flutter.