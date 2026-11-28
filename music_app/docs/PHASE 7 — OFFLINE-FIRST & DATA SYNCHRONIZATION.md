# PHASE 7 — OFFLINE-FIRST & DATA SYNCHRONIZATION

## 🎯 Mục tiêu Phase 7

Hoàn thiện kiến trúc Offline-first cho ứng dụng Flutter WaveBox, bảo đảm người dùng vẫn có thể sử dụng các chức năng chính khi không có Internet và dữ liệu được đồng bộ an toàn với Spring Boot Backend khi kết nối trở lại.

Phase 7 tập trung chuẩn hóa Local Repository, ánh xạ dữ liệu Local–Cloud, quản lý Pending Sync Queue, xử lý Batch Synchronization, khôi phục dữ liệu sau đăng nhập và tích hợp trạng thái Download vào giao diện.

Phase 7 phải kế thừa các thành phần đã có trong Phase 1–6, đặc biệt:

```text id="0q7qzd"
Flutter SQLite
SongRepository
LocalRepository (nếu đã có)
SyncService
pending_sync
ConnectivityService
ApiClient
PlaylistRepository
Download Service
Authentication State
Spring Boot Batch Sync API
PostgreSQL
```

Luồng thực hiện:

```text id="fbxvzn"
PHASE 1–6 — ARCHITECTURE & IMPLEMENTATION
                   ↓
AUDIT LOCAL DATA & EXISTING SYNC
                   ↓
MAP LOCAL DATABASE ↔ BACKEND DATA
                   ↓
STANDARDIZE LOCAL REPOSITORIES
                   ↓
REPLACE SOUNDHELIX WITH REAL API
                   ↓
IMPLEMENT CONNECTIVITY & SYNC TRIGGER
                   ↓
VERIFY ATOMIC ENQUEUE SYNC
                   ↓
INTEGRATE BATCH SYNC API
                   ↓
IMPLEMENT PULL & CLOUD RESTORE
                   ↓
INTEGRATE DOWNLOAD UI
                   ↓
INTEGRATE ACCOUNT ENTRY & PLAYLIST
                   ↓
ONLINE / OFFLINE TESTS
                   ↓
PHASE 7 DONE
```

**Phạm vi requirement:**

```text id="x4a3no"
QA01 — SongRepository Mapping
QA02 — Replace SoundHelix with API
QA03 — Standardize LocalRepository
QA04 — Connectivity & Sync Trigger
QA05 — Verify enqueueSync
QA06 — Batch Synchronization
QA07 — Pull & Restore Data
QA08 — Download UI Integration
QA09 — Online / Offline Tests
QA10 — AccountEntry & PlaylistRepository
```

Đầu ra Phase 7 là ứng dụng Offline-first có thể lưu và sử dụng dữ liệu local khi mất mạng, tự đồng bộ các thao tác đang chờ khi kết nối trở lại, khôi phục dữ liệu cá nhân từ Backend và không làm trộn dữ liệu giữa các tài khoản.

Phase 7 **được phép tạo và sửa source Flutter**, bổ sung migration SQLite khi thực sự cần thiết và tích hợp các API đã có ở Phase 4.

Không triển khai lại Spring Boot Batch Sync API hoặc Download Service đã hoàn thành ở các phase trước.

---

## 1. NGUYÊN TẮC TRIỂN KHAI

### 1.1 — Previous Phases Source of Truth Rule

Trước khi code, đọc:

```text id="6srd0c"
docs/REPORT/PHASE-1-ARCHITECTURE.md
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/IMPLEMENTATION_ROADMAP.md

docs/REPORT/PHASE-4-MUSIC-DATA.md
docs/REPORT/PHASE-5-FLUTTER-AUTH-API.md
docs/REPORT/PHASE-6-PLAYER-DOWNLOAD.md
```

Kiểm tra source hiện tại:

```text id="8fzi4v"
SongRepository
LocalRepository
PlaylistRepository
SyncService
ConnectivityService
AppDatabase
pending_sync
ApiClient
AuthRepository
AuthViewModel
AccountEntry
Download Service
Download Metadata
```

Đặc biệt, trong quá trình khảo sát Flutter trước đây đã từng ghi nhận:

- `AppDatabase` sử dụng SQLite, có cấu trúc khoảng 12 bảng ở thời điểm khảo sát.
- `SyncService` có hàng đợi `pending_sync`.
- Sync Service từng có cơ chế kiểm tra và đồng bộ định kỳ khoảng 2 phút.
- Cơ chế retry từng được ghi nhận giới hạn tối đa 5 lần.
- `restoreFromCloud` từng xử lý Playlist, Favorites và History.
- `ApiClient` giao tiếp với REST API.
- `SongRepository` kết hợp dữ liệu local và remote.

Đây là thông tin từ lần khảo sát source trước, không được mặc định code hiện tại vẫn giữ nguyên. Phải kiểm tra và xác minh lại trước khi sửa.

Các quyết định về UUID, Batch Sync, Conflict Resolution, Data Ownership và Storage Architecture phải tuân thủ Phase 1 và `API_CONTRACT.md`.

### 1.2 — Offline-first Rule

Ứng dụng phải ưu tiên sử dụng dữ liệu local đối với những chức năng đã được xác định hỗ trợ offline.

Nguyên tắc:

```text id="j4fiio"
USER ACTION
     ↓
SAVE LOCAL DATABASE
     ↓
UPDATE UI IMMEDIATELY
     ↓
CREATE PENDING OPERATION
     ↓
CHECK CONNECTIVITY
     |
  +--+--+
  |     |
ONLINE OFFLINE
  |     |
SYNC  KEEP LOCAL
  |     |
ACKNOWLEDGE
  |
UPDATE SYNC STATUS
```

Yêu cầu:

- Không bắt người dùng chờ Backend khi thực hiện thao tác local được phép.
- Không yêu cầu Internet để xem dữ liệu đã lưu local.
- Không mất thao tác khi ứng dụng bị đóng.
- Không xóa Pending Operation khi chưa có xác nhận từ Server.
- Không tạo dữ liệu trùng khi Retry.
- UI phải phản ánh chính xác trạng thái Local và Sync.

Không phải mọi dữ liệu đều phải hỗ trợ offline. Chức năng nào cần Internet phải được thể hiện rõ trong UI và Requirement.

### 1.3 — Data Ownership Rule

Phân biệt rõ nguồn dữ liệu:

```text id="0p4c8r"
BACKEND-OWNED DATA
    ├── Music Catalog
    ├── Songs
    ├── Albums
    ├── Artists
    └── Genres

USER-OWNED DATA
    ├── Playlists
    ├── Favorites
    └── History

DEVICE-OWNED DATA
    ├── Imported Local Music
    ├── Downloaded Audio Files
    ├── Local Cache
    └── Local Playback Metadata

SYNC-OWNED DATA
    └── Pending Operations
```

Quy tắc:

- Music Catalog có Backend là nguồn dữ liệu chính.
- Dữ liệu cá nhân được phân vùng theo tài khoản.
- Local database lưu dữ liệu phục vụ Offline-first.
- Downloaded Audio File thuộc thiết bị.
- Pending Operation chỉ được xóa sau khi được xác nhận đồng bộ.
- Không upload file audio binary qua Batch Sync.
- Không dùng dữ liệu Local của một User để ghi đè dữ liệu User khác.

### 1.4 — Single Cloud Source Rule

Kiến trúc Cloud chính phải thống nhất:

```text id="48hfxw"
Flutter
   ↓
Spring Boot REST API
   ↓
PostgreSQL
```

Tài liệu Chương IV trước đây có nhắc đến Firebase Cloud Firestore, trong khi source từng được khảo sát có REST API, `SyncService` và `pending_sync`.

Bắt buộc kiểm tra và tuân thủ quyết định cuối cùng trong:

```text id="ma2flp"
docs/architecture/DECISION_LOG.md
```

Không tự ý triển khai:

```text id="8a0ckj"
Spring Boot REST Sync
       +
Firebase Firestore Sync
```

như hai nguồn Cloud độc lập cho cùng Playlist, Favorites hoặc History.

Nếu Phase 1 đã xác định Spring Boot + PostgreSQL là Cloud Source of Truth, Phase 7 phải sử dụng kiến trúc này.

Nếu phát hiện source còn Firebase:

- Xác định chức năng đang sử dụng.
- Kiểm tra dữ liệu hiện tại.
- Ghi nhận phần nào cần giữ để tương thích.
- Đưa ra phương án chuyển đổi an toàn.
- Không xóa Firebase code hoặc cấu hình khi chưa xác minh dependency và dữ liệu đang được sử dụng.

### 1.5 — Atomic Local Operation Rule

Mỗi thao tác thay đổi dữ liệu cần đồng bộ phải bảo đảm hai việc:

```text id="kymk9q"
UPDATE LOCAL DATA
        +
INSERT PENDING OPERATION
```

Hai thao tác phải được thực hiện trong cùng một SQLite transaction khi có thể.

Ví dụ:

```text id="2w0dxk"
Create Playlist
      ↓
BEGIN TRANSACTION
      |
      +---- Insert Playlist
      |
      +---- Insert Pending Operation
      |
      +---- COMMIT
```

Nếu một trong hai thao tác thất bại:

```text id="y48hnc"
ROLLBACK
```

Không được tạo Playlist local nhưng mất Pending Operation, hoặc tạo Pending Operation trong khi thay đổi dữ liệu local đã bị rollback.

### 1.6 — Idempotency & Conflict Rule

Mọi thao tác đồng bộ phải tuân thủ `operationId` và Batch Sync Contract đã chốt ở Phase 1 và Phase 4.

```text id="9v4cdh"
Same operationId
       ↓
Backend Already Processed?
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

- Retry không tạo dữ liệu trùng.
- Operation đã xác nhận không được gửi lại như thao tác mới.
- Operation thất bại phải được giữ lại để xử lý.
- Operation cùng một Entity phải tuân thủ thứ tự phù hợp.
- Conflict phải được phân biệt với Network Error.
- Không mặc định Last Write Wins cho tất cả dữ liệu.
- Sử dụng quy tắc xử lý Playlist, Favorites và History đã chốt.

Không tự đổi JSON hoặc cấu trúc Batch Request của Backend.

### 1.7 — Preserve Existing Data Rule

Không được:

```text id="mwczjo"
❌ Xóa SQLite Database
❌ DROP TABLE
❌ TRUNCATE
❌ Reset local data
❌ Xóa pending_sync để đồng bộ lại từ đầu
❌ Xóa Playlist hiện có
❌ Xóa Favorites hoặc History
❌ Xóa Download Metadata hàng loạt
❌ Xóa file nhạc đã tải
❌ Xóa nhạc người dùng nhập từ thiết bị
❌ Xóa Account hoặc User Session ngoài nghiệp vụ
```

Nếu cần thay đổi SQLite Schema:

- Đọc phiên bản database hiện tại.
- Tạo migration tăng version.
- Giữ nguyên dữ liệu hiện có.
- Có kiểm thử nâng cấp từ version cũ.
- Không thay thế database bằng một database mới rỗng.

### 1.8 — Safe Modification Rule

Được phép:

```text id="xgnqci"
✅ Mở rộng SongRepository
✅ Chuẩn hóa LocalRepository
✅ Mở rộng PlaylistRepository
✅ Mở rộng SyncService
✅ Sửa ConnectivityService
✅ Bổ sung SQLite Migration
✅ Tích hợp Batch Sync
✅ Tích hợp Pull / Restore
✅ Thêm Sync State UI
✅ Tích hợp Download UI
✅ Thêm Offline / Online Tests
```

Không được:

```text id="az7qwp"
❌ Xóa source code hiện có
❌ Xóa class hoặc method
❌ Rewrite SQLite khi không cần thiết
❌ Thay đổi API Contract tùy tiện
❌ Viết lại Backend Batch Sync
❌ Viết lại Download Service của Phase 6
❌ Thay đổi Player Architecture
❌ Xóa audio_handler.dart
❌ Tự tạo Firebase Sync song song
❌ Merge dữ liệu Guest và User không có chính sách
❌ Hardcode API Endpoint
❌ Commit / push khi chưa được yêu cầu
```

---

## 2. ĐIỀU KIỆN BẮT ĐẦU

Phase 7 được phép bắt đầu khi:

```text id="1d2v5x"
PHASE 1 — ARCHITECTURE DONE
              +
PHASE 4 — MUSIC DATA & BATCH SYNC API DONE
              +
PHASE 5 — FLUTTER API INTEGRATION DONE
              +
PHASE 6 — PLAYER & DOWNLOAD DONE
              +
SQLite hoạt động
              +
ApiClient hoạt động
              +
Authentication hoạt động
              +
Batch Sync API có thể kiểm thử
```

Kiểm tra Flutter:

```bash id="l0cw1z"
flutter --version
```

```bash id="skf7b4"
flutter pub get
```

```bash id="8grz0t"
flutter analyze
```

Kiểm tra:

```text id="l8q9f8"
SQLite Database
SongRepository
PlaylistRepository
SyncService
ConnectivityService
Pending Sync Queue
Download Metadata
```

Kiểm tra Backend:

```text id="3pnb08"
Health Check
JWT Authentication
Batch Sync API
Pull / Restore API (nếu có)
Music Catalog API
```

Kiểm tra Git:

```bash id="b1z41l"
git status --short
```

### Dependency cần ghi nhận

```text id="7m3xdo"
[DEPENDENCY — PHASE 4 BATCH SYNC API]
[DEPENDENCY — PULL / RESTORE API]
[DEPENDENCY — SQLITE MIGRATION]
[DEPENDENCY — CONNECTIVITY CONFIGURATION]
[DEPENDENCY — DATA OWNERSHIP POLICY]
```

Nếu Pull API chưa tồn tại ở Backend, ghi nhận `BLOCKED — BACKEND PULL API DEPENDENCY`. Không tự giả lập thành công bằng cách đọc dữ liệu từ một nguồn Cloud khác.

---

## 3. PHẠM VI PHASE 7

### CHỈ LÀM

```text id="th2dvy"
QA01 — SongRepository Mapping
QA02 — Replace SoundHelix with API
QA03 — Standardize LocalRepository
QA04 — Connectivity & Sync Trigger
QA05 — Verify enqueueSync
QA06 — Batch Sync
QA07 — Pull & Restore Data
QA08 — Download UI Integration
QA09 — Online / Offline Tests
QA10 — AccountEntry & PlaylistRepository
```

### KHÔNG ĐƯỢC LÀM

```text id="1wc7cm"
JWT Implementation
Backend Authentication
Backend Music Schema Redesign
Backend Batch Sync Rewrite
Player Engine Rewrite
Background Audio Rewrite
Download Service Rewrite
New Music Catalog API
Full Flutter UI Redesign
Production Data Reset
Firebase Sync Implementation nếu không được quyết định
```

Các thành phần này đã thuộc Phase 1–6 hoặc nằm ngoài kiến trúc đã chốt.

---

# 4. CÁC TASK THỰC HIỆN

## TASK 7.1 — SONGREPOSITORY MAPPING (QA01)

### 🎯 Mục tiêu

Chuẩn hóa cách SongRepository ánh xạ dữ liệu từ SQLite, Backend Music Catalog và file audio local, tránh cùng một bài hát bị tạo thành nhiều bản ghi không liên quan.

### Cách làm

#### 1. Audit Existing SongRepository

Đọc:

```text id="8r0jjo"
SongRepository
AppDatabase
Song Entity / Model
Song DTO
Search Repository
Download Metadata
Playback Source Resolver
```

Xác định:

```text id="kg7cf5"
Local Song ID
Backend Song ID
File Path
Audio Source
Artwork
Metadata
Download Status
Sync Status
```

#### 2. Data Mapping

Xây dựng mapping:

```text id="g7ppkk"
BACKEND SONG
     ↓
Song DTO
     ↓
Song Model
     ↓
Local SQLite Entity
     ↓
SongRepository
     ↓
Player / Search / Download
```

Các field cần thống nhất theo Backend Contract, có thể gồm:

```text id="bf33un"
id
title
artistId / artistName
albumId / albumName
genreId / genreName
duration
artworkUrl
audioSource
```

Các thông tin local riêng:

```text id="hdzvas"
localFilePath
downloadStatus
localSourceType
lastAccessedAt
```

Không ghi đè metadata local riêng bằng response Backend.

#### 3. Identifier Mapping

Phân biệt:

```text id="vgx3vl"
Backend Song UUID
Local Database ID
Local File Path
```

Nếu Local Music có ID riêng, cần duy trì mapping ổn định giữa Local Record và Backend Song ID.

Không sử dụng:

- Song Title.
- Artist Name.
- File Name.
- Array Index.

làm khóa định danh thay thế UUID.

Không tự gộp hai bài hát chỉ vì chúng có tên giống nhau.

#### 4. Source Resolution

SongRepository phải biết một bài hát thuộc nguồn:

```text id="nyk2ql"
LOCAL_ORIGINAL
BACKEND_CATALOG
DOWNLOADED
REMOTE_STREAM
```

Một bài hát có thể có cả metadata Backend và file local, nhưng phải giữ quan hệ rõ ràng.

#### 5. Backward Compatibility

Nếu SQLite hiện có dữ liệu:

- Giữ nguyên dữ liệu cũ.
- Mapping ID cũ sang cấu trúc mới khi cần.
- Không tạo duplicate Song khi nhập metadata từ Backend.
- Không làm hỏng Playlist, Favorites, History hoặc Download Metadata đang tham chiếu Song.

### DONE

```text id="wrrjpt"
[ ] SongRepository được audit
[ ] Backend Song Mapping hoạt động
[ ] Local Song Mapping hoạt động
[ ] ID Mapping ổn định
[ ] Metadata không bị ghi đè sai
[ ] Download Metadata được giữ
[ ] Playlist / Favorites / History không mất liên kết
[ ] Không tạo Song trùng khi refresh Catalog
```

---

## TASK 7.2 — REPLACE SOUNDHELIX WITH REAL MUSIC API (QA02)

### 🎯 Mục tiêu

Thay nguồn nhạc demo SoundHelix bằng dữ liệu và nguồn audio thực tế từ Backend đã triển khai ở Phase 4.

### Cách làm

#### 1. Audit SoundHelix

Tìm toàn bộ source sử dụng:

```text id="za3w3w"
SoundHelix
Hardcoded Audio URL
Demo Song
Placeholder Song
Test Streaming URL
Static Music List
```

Xác định:

```text id="3g4mte"
File Path
Method
Widget
Repository
Audio Source
Current Usage
```

Không xóa ngay toàn bộ URL hoặc source cũ trước khi xác định tất cả nơi đang sử dụng.

#### 2. Replace Catalog Data

Luồng:

```text id="vv0dy3"
Flutter
   ↓
SongRepository
   ↓
Music Catalog API
   ↓
Spring Boot
   ↓
PostgreSQL
   ↓
Real Song Metadata
```

Sử dụng API đã có:

```text id="8yegst"
GET /api/songs
GET /api/songs/{id}
```

Endpoint thực tế phải theo `API_CONTRACT.md`.

Yêu cầu:

- Không hardcode danh sách bài hát giả.
- Không tạo Song Model giả để che lỗi API.
- Mapping đúng Song UUID.
- Hiển thị Loading, Empty và Error State.
- Có phân trang nếu Backend hỗ trợ.

#### 3. Replace Audio Source

Nếu API Contract hỗ trợ Streaming:

```text id="wq28vv"
Song Metadata
      ↓
Song ID
      ↓
Backend Streaming API
      ↓
just_audio
      ↓
Playback
```

Không tự ghép URL Streaming từ Song ID nếu API Contract quy định endpoint khác.

Không thay cơ chế Player đã chốt ở Phase 6.

#### 4. Source Availability

Xử lý:

```text id="k11d30"
Song Available
Song Unavailable
Audio File Missing
Backend Offline
Network Timeout
Unauthorized
```

Không stream file từ nguồn không được cấp quyền.

Không sử dụng lại SoundHelix như nguồn dự phòng ngầm khi Backend thất bại, trừ khi đó là nguồn được phép và đã được xác định rõ trong sản phẩm.

Nếu SoundHelix vẫn được dùng cho test, phải tách hoàn toàn khỏi production flow.

#### 5. Preserve Offline Playback

Khi đã có file local hợp lệ:

- Không phụ thuộc SoundHelix.
- Không bắt buộc gọi Backend để phát.
- Không xóa file tải về khi thay đổi Catalog.
- Giữ được mapping giữa Catalog và Local Audio.

### DONE

```text id="c6r2n3"
[ ] Đã xác định toàn bộ SoundHelix references
[ ] Catalog lấy từ Backend
[ ] Audio Source sử dụng Backend Streaming hoặc nguồn được phép
[ ] Song ID Mapping đúng
[ ] Không còn SoundHelix trong production flow
[ ] Không sử dụng URL demo thay API thực tế
[ ] Offline Playback không bị ảnh hưởng
```

---

## TASK 7.3 — STANDARDIZE LOCALREPOSITORY (QA03)

### 🎯 Mục tiêu

Chuẩn hóa tầng lưu trữ local để các chức năng Library, Playlist, Favorites, History và Sync dùng chung cách truy cập dữ liệu, tránh xử lý SQLite trực tiếp rải rác trong Widget.

### Cách làm

#### 1. Audit Local Data Access

Tìm các thành phần đang truy cập trực tiếp SQLite:

```text id="n4d2wq"
SongRepository
PlaylistRepository
Favorites Repository
History Repository
Download Repository
SyncService
AppDatabase
```

Kiểm tra:

- Widget có gọi SQLite trực tiếp không?
- Có nhiều cách thao tác một bảng không?
- Có duplicate CRUD logic không?
- Có Repository trả dữ liệu không thống nhất không?
- Có thao tác local nào không ghi Pending Operation?
- Có thao tác ghi local nào không sử dụng transaction không?

#### 2. Repository Structure

Mục tiêu:

```text id="xwdufr"
UI / ViewModel
      ↓
Repository
      ↓
Local Data Source
      |
      +---- SQLite
      |
      +---- Local Files
```

Đối với dữ liệu cần đồng bộ:

```text id="5vgy6p"
Repository
    ↓
Local Transaction
    |
    +---- Update Entity
    |
    +---- Enqueue Sync Operation
```

Có thể dùng các interface và implementation hiện có.

Không tạo nhiều lớp chỉ để thay đổi tên gọi nếu Repository hiện tại đã đáp ứng đúng trách nhiệm.

#### 3. LocalRepository Responsibilities

Chuẩn hóa các thao tác:

```text id="t4i9gv"
Insert
Update
Delete
Find By ID
Get List
Search Local
Watch Changes (nếu cần)
Transaction
```

Đối với dữ liệu người dùng:

```text id="hov7cn"
Playlist
Favorites
History
```

Repository phải xử lý đúng User Context và không trộn dữ liệu.

#### 4. Database Migration

Nếu cần thay đổi schema SQLite:

- Tăng database version.
- Tạo migration tăng version.
- Chuyển đổi dữ liệu hiện có.
- Giữ các Foreign Key và quan hệ.
- Kiểm tra các bản ghi Pending Sync.
- Không reset database.

#### 5. UI Independence

Các màn hình không được:

- Tạo SQL trực tiếp.
- Ghi trực tiếp vào bảng Pending Sync.
- Tự gọi SQLite và Backend song song theo cách không kiểm soát.
- Tự quyết định conflict resolution.

UI chỉ gọi Repository và nhận trạng thái.

### DONE

```text id="zrc4du"
[ ] Local Data Access được chuẩn hóa
[ ] Không có SQLite CRUD rải rác trong Widget
[ ] Repository phân tách đúng trách nhiệm
[ ] Transaction hoạt động
[ ] User Data có phân vùng
[ ] Migration bảo toàn dữ liệu
[ ] Không tạo duplicate Repository
[ ] Player / Download vẫn sử dụng được Local Data
```

---

## TASK 7.4 — CONNECTIVITY & AUTOMATIC SYNC TRIGGER (QA04)

### 🎯 Mục tiêu

Theo dõi trạng thái kết nối và kích hoạt Sync khi có điều kiện phù hợp, không để nhiều Sync chạy đồng thời hoặc gây hao pin.

### Cách làm

#### 1. Connectivity Service

Kiểm tra hoặc mở rộng:

```text id="q6am8z"
ConnectivityService
```

Theo dõi:

```text id="d11dvn"
Online
Offline
Network Changed
App Resumed
App Paused
```

Lưu ý: Connectivity API chỉ cho biết trạng thái kết nối mạng ở mức thiết bị, không đảm bảo Backend truy cập được.

Phải phân biệt:

```text id="5b4xn6"
NETWORK AVAILABLE
       ≠
BACKEND REACHABLE
```

Khi cần, kiểm tra Backend thông qua Health Check hoặc request phù hợp.

Không gọi liên tục Health Check chỉ để cập nhật UI.

#### 2. Sync Trigger Conditions

Kích hoạt Sync khi:

```text id="h1k0bh"
Network Restored
User Login Success
App Resumed
Pending Queue Exists
Manual Sync Requested
Periodic Trigger (nếu được chốt)
```

Không tự động đồng bộ nếu:

- Chưa xác thực User và operation yêu cầu tài khoản.
- Backend không truy cập được.
- Đang có một Sync Worker xử lý.
- Chưa có Pending Operation.
- User đang logout hoặc chuyển tài khoản.

#### 3. Sync Worker Lock

Phải chỉ có một tiến trình Sync cho cùng User tại một thời điểm.

Luồng:

```text id="et0fg6"
Sync Trigger
     ↓
Check Authentication
     ↓
Check Connectivity
     ↓
Check Backend Reachable
     ↓
Check Pending Queue
     ↓
Sync Already Running?
     |
  +--+--+
  |     |
 YES    NO
  |     |
Skip   Start Worker
          ↓
        Process
```

Các trigger khác khi worker đang chạy phải chờ hoặc được gộp, không tạo request trùng.

#### 4. Background & Lifecycle

Trong Phase 7:

- Đồng bộ ngay trong foreground khi có mạng.
- Khi App Resume, kiểm tra và xử lý Pending Queue.
- Có thể sử dụng periodic background sync nếu hệ điều hành và requirement cho phép.
- Không giả định timer Dart tiếp tục hoạt động khi ứng dụng đã bị hệ điều hành dừng.
- Không yêu cầu đồng bộ nền liên tục nếu không cần thiết.

Nếu cần background scheduling trên Android, chọn cơ chế tương thích với giới hạn hệ điều hành. Việc đồng bộ không được phụ thuộc duy nhất vào một timer trong Widget hoặc một vòng lặp chạy liên tục.

#### 5. Retry Policy

Kiểm tra chính sách retry hiện có.

Trong source khảo sát trước đây, SyncService từng có cấu hình retry tối đa 5 lần và kiểm tra theo chu kỳ khoảng 2 phút. Phải đánh giá lại thông số này, không mặc định giữ nguyên.

Quy tắc:

- Retry lỗi mạng và lỗi tạm thời.
- Không retry vô hạn.
- Không retry lỗi validation hoặc lỗi ownership như thể đó là lỗi mạng.
- Có backoff khi liên tục thất bại.
- Không Retry thao tác đã được Server xác nhận thành công.
- Không xóa Pending Operation khi request timeout mà chưa biết kết quả.
- Có cách xử lý trường hợp Server đã xử lý nhưng response bị mất thông qua idempotency.

### DONE

```text id="xtz7wh"
[ ] Connectivity Status hoạt động
[ ] Backend Reachability được xác định
[ ] Network Restored trigger Sync
[ ] Login Success trigger Sync
[ ] App Resume trigger Sync
[ ] Manual Sync hoạt động
[ ] Không có hai Sync Worker cùng chạy
[ ] Retry có giới hạn
[ ] Backoff hoạt động
[ ] Không xóa Pending khi chưa xác nhận
[ ] Không phụ thuộc Timer Widget
```

---

## TASK 7.5 — VERIFY enqueueSync & PENDING QUEUE (QA05)

### 🎯 Mục tiêu

Kiểm tra mọi thao tác local cần đồng bộ đều tạo Pending Operation chính xác, tránh mất thao tác khi người dùng offline.

Đây là một trong những task quan trọng nhất của Phase 7.

### Cách làm

#### 1. Audit enqueueSync

Tìm toàn bộ vị trí:

```text id="a0f0fu"
enqueueSync
pending_sync
SyncService
PlaylistRepository
Favorites Repository
History Repository
```

Ghi nhận:

```text id="7mew3a"
Caller
Entity Type
Action
Payload
Operation ID
Transaction
Queue Status
```

#### 2. Operations That Require Sync

Đối chiếu với API Contract:

```text id="90cb33"
PLAYLIST
    CREATE
    UPDATE
    DELETE
    ADD_SONG
    REMOVE_SONG
    REORDER (nếu có)

FAVORITE
    ADD
    REMOVE

HISTORY
    APPEND
```

Không đưa các thao tác chỉ mang tính UI hoặc dữ liệu local-only vào Cloud Sync.

Không đưa file audio binary vào Pending Queue.

#### 3. Pending Operation Structure

Mỗi operation cần đủ thông tin theo Batch Sync Contract:

```text id="l0byei"
operationId
entityType
entityId
action
clientSequence
baseVersion (nếu có)
occurredAt
payload
status
retryCount
lastError
createdAt
```

Các trường cụ thể phải tuân theo schema đã chốt, không tự thay đổi contract.

Các trạng thái local có thể gồm:

```text id="k2zfeg"
PENDING
IN_PROGRESS
SYNCED
RETRYABLE_ERROR
CONFLICT
PERMANENT_ERROR
```

Nếu database hiện tại dùng tên trạng thái khác, ưu tiên tương thích thay vì tạo enum mới không cần thiết.

#### 4. Atomic Enqueue

Ví dụ tạo Playlist offline:

```text id="wh6l8m"
User Creates Playlist
         ↓
BEGIN SQLITE TRANSACTION
         |
         +---- Save Playlist
         |
         +---- Create Operation UUID
         |
         +---- Insert Pending Sync
         |
         +---- COMMIT
         ↓
Update UI Immediately
```

Nếu transaction thất bại:

```text id="n7c3gd"
ROLLBACK
```

Không có trường hợp Playlist local tồn tại nhưng không có thao tác cần đồng bộ.

#### 5. Operation Ordering

Các thao tác trên cùng một Playlist cần được gửi theo thứ tự phù hợp.

Ví dụ:

```text id="9h83cn"
CREATE PLAYLIST
      ↓
ADD SONG
      ↓
UPDATE PLAYLIST
      ↓
REMOVE SONG
      ↓
DELETE PLAYLIST
```

Không gửi thao tác DELETE trước CREATE nếu các operation phụ thuộc nhau.

Nếu một operation trước đó thất bại, phải xác định operation sau có được gửi tiếp hay phải chờ.

Không xử lý queue bằng cách sắp xếp ngẫu nhiên theo timestamp.

#### 6. Queue Preservation

Pending Operation phải được giữ qua:

- Đóng ứng dụng.
- Khởi động lại thiết bị.
- Mất kết nối.
- Timeout.
- Server lỗi.
- Refresh Token hết hạn.
- Chuyển trạng thái Offline.

Không tự xóa Queue để làm sạch lỗi.

#### 7. Enqueue Test

Kịch bản:

```text id="i7j4e2"
1. Tắt Internet
2. Tạo Playlist
3. Kiểm tra SQLite
4. Kiểm tra pending_sync
5. Đóng ứng dụng
6. Mở lại ứng dụng
7. Kiểm tra Playlist còn tồn tại
8. Kiểm tra Pending Operation còn tồn tại
```

### DONE

```text id="wfoa5r"
[ ] Tất cả thao tác cần Sync đã được audit
[ ] enqueueSync được gọi đúng vị trí
[ ] operationId duy nhất
[ ] Payload đúng Contract
[ ] Local Transaction hoạt động
[ ] Queue không bị mất khi App đóng
[ ] Queue không bị mất khi mất mạng
[ ] Operation Ordering đúng
[ ] Không enqueue Audio Binary
[ ] Không enqueue dữ liệu Local-only
```

---

## TASK 7.6 — BATCH SYNCHRONIZATION INTEGRATION (QA06)

### 🎯 Mục tiêu

Tích hợp Pending Queue của Flutter với Batch Sync API đã hoàn thành ở Phase 4.

Không viết lại Batch Processing phía Backend.

### 1. Sync Architecture

Luồng:

```text id="ih9xod"
SQLite Pending Queue
         ↓
Load Pending Operations
         ↓
Validate Current User
         ↓
Build Batch Request
         ↓
ApiClient
         ↓
POST Batch Sync API
         ↓
Spring Boot
         ↓
PostgreSQL
         ↓
Per-operation Results
         ↓
Flutter Updates Queue Status
```

### 2. Batch Request

Sử dụng đúng schema `docs/API_CONTRACT.md`.

Không tự sửa:

```text id="v5t2tp"
batchId
operationId
entityType
entityId
action
clientSequence
baseVersion
occurredAt
payload
```

Các trường chỉ là minh họa theo contract đã chốt.

### 3. Batch Size

Không gửi toàn bộ Pending Queue trong một request nếu dữ liệu lớn.

Cần:

- Giới hạn số operation mỗi batch.
- Giới hạn kích thước payload.
- Chia batch khi cần.
- Giữ thứ tự các operation có phụ thuộc.
- Không tách các thao tác phụ thuộc theo cách gây lỗi nghiệp vụ.
- Không gửi operation của nhiều User trong cùng một batch.

### 4. Result Handling

Xử lý riêng:

```text id="ed98v4"
APPLIED
DUPLICATE
CONFLICT
REJECTED
```

Quy tắc:

| Server Result | Client Action |
|---|---|
| APPLIED | Đánh dấu Synced |
| DUPLICATE | Đánh dấu Synced sau khi xác nhận đúng operation |
| CONFLICT | Giữ trạng thái Conflict để xử lý |
| REJECTED | Ghi lỗi và không tự xóa operation |

Nếu response không đầy đủ hoặc thiếu kết quả cho operation:

- Không mặc định operation đó đã thành công.
- Giữ operation để xác minh hoặc Retry an toàn.
- Sử dụng `operationId` để tránh tạo trùng.

### 5. Acknowledge Rule

Chỉ cập nhật `SYNCED` khi nhận được kết quả xác nhận phù hợp.

Không xóa Pending Operation trước khi nhận response.

Đối với operation đã được xác nhận, có thể giữ lại lịch sử ngắn hạn nếu cần debug hoặc audit, theo chính sách lưu trữ đã thống nhất.

### 6. Network Failure During Batch

Tình huống:

```text id="j7lfzr"
Client Sends Batch
       ↓
Backend Processes
       ↓
Network Disconnects
       ↓
Client Does Not Receive Result
       ↓
Operation Remains Pending
       ↓
Client Retries Same operationId
       ↓
Backend Returns Previous Result
```

Đây là lý do phải giữ nguyên `operationId` khi retry.

Không tạo UUID mới cho cùng một thao tác chỉ vì request trước bị timeout.

### 7. User Isolation

Mỗi Batch chỉ được xử lý dưới User đang đăng nhập hiện tại.

Trước khi gửi:

- Kiểm tra Auth State.
- Lấy token đúng User.
- Chỉ lấy operations thuộc User hiện tại hoặc operations Guest đã được xử lý theo chính sách được duyệt.
- Không gửi dữ liệu User A bằng token User B.
- Không gộp hai User vào cùng một queue.

### DONE

```text id="qc5vuv"
[ ] Batch Request đúng API Contract
[ ] Batch Size được giới hạn
[ ] Operations được xử lý đúng thứ tự
[ ] APPLIED xử lý đúng
[ ] DUPLICATE xử lý đúng
[ ] CONFLICT được giữ lại
[ ] REJECTED được giữ lại
[ ] Acknowledge đúng từng operation
[ ] Timeout không làm mất Pending
[ ] Retry giữ nguyên operationId
[ ] Không trộn dữ liệu tài khoản
[ ] Không gửi Audio Binary
```

---

## TASK 7.7 — PULL & RESTORE CLOUD DATA (QA07)

### 🎯 Mục tiêu

Khôi phục dữ liệu cá nhân từ Backend xuống SQLite sau đăng nhập và lấy các thay đổi mới từ Cloud khi người dùng tiếp tục sử dụng ứng dụng.

### 1. Restore Scope

Dữ liệu cần đối chiếu:

```text id="f02v0n"
PLAYLISTS
PLAYLIST SONGS
FAVORITES
HISTORY
```

Song Metadata thuộc Music Catalog và được lấy qua API Catalog riêng.

Không tải toàn bộ Catalog vào Restore cá nhân nếu không có requirement.

Download Audio File không được khôi phục bằng Batch Metadata. File audio phải được tải riêng qua Download Service khi cần.

### 2. Restore Flow

```text id="rm2t7j"
User Login Success
       ↓
Get Authenticated User ID
       ↓
Check Local Data Ownership
       ↓
Pull Cloud Data
       ↓
Validate Response
       ↓
Merge with Local Database
       ↓
Preserve Pending Operations
       ↓
Update Sync Cursor
       ↓
Display Restored Data
```

### 3. Initial Restore

Khi tài khoản chưa có dữ liệu local:

```text id="h4dyxo"
Login
  ↓
GET Cloud User Data
  ↓
Create Local Records
  ↓
Save SQLite
  ↓
Complete Restore
```

Yêu cầu:

- Khôi phục đúng User.
- Không tạo record trùng.
- Giữ UUID từ Backend.
- Giữ quan hệ Playlist và Playlist Songs.
- Lưu dữ liệu trong SQLite transaction phù hợp.
- Chỉ hoàn tất Restore khi các phần dữ liệu cần thiết đã được lưu thành công.

### 4. Incremental Pull

Nếu Backend có hỗ trợ cursor hoặc version, ưu tiên sử dụng.

Thông tin có thể gồm:

```text id="o38xun"
cursor
nextCursor
hasMore
serverVersion
```

Quy tắc:

- Không chỉ dựa vào đồng hồ thiết bị.
- Không bỏ sót thay đổi do nhiều bản ghi có cùng timestamp.
- Có thể tiếp tục Pull theo cursor.
- Có xử lý phân trang.
- Chỉ cập nhật cursor sau khi dữ liệu tương ứng đã lưu thành công.
- Nếu Pull thất bại, không cập nhật cursor khiến dữ liệu bị bỏ qua.

Nếu Contract hiện tại dùng `since` hoặc `lastSyncAt`, phải sử dụng đúng Contract và ghi nhận những giới hạn của timestamp-based synchronization.

### 5. Conflict with Local Pending Operations

Khi Cloud Data khác Local Data:

```text id="w0wf5a"
Cloud Changes
      +
Local Pending Operations
      ↓
Check Entity ID
      ↓
Check Version / Base Version
      ↓
Apply Conflict Policy
      ↓
Merge / Preserve / Mark Conflict
```

Nguyên tắc:

- Không ghi đè Local Change chưa được xác nhận.
- Không xóa Pending Operation khi Pull Cloud Data.
- Không để Cloud Restore làm mất thao tác offline.
- Không áp dụng Last Write Wins cho mọi entity.
- Sử dụng Conflict Resolution Matrix đã chốt ở Phase 1.

### 6. Tombstone & Delete Restore

Đối với dữ liệu bị xóa trên Cloud:

- Phải nhận diện trạng thái xóa hoặc tombstone theo contract.
- Xóa hoặc đánh dấu dữ liệu local đúng quy tắc.
- Không khôi phục lại record đã bị xóa chỉ vì bản local cũ còn tồn tại.
- Không xóa file audio local chỉ vì Playlist hoặc metadata bị xóa.
- Không xóa dữ liệu đang có Pending Operation chưa được xử lý.

### 7. User Account Isolation

Khi đổi User:

```text id="a6gjpt"
User A Logout
      ↓
Clear Auth Session A
      ↓
User B Login
      ↓
Load User B Local Namespace
      ↓
Pull User B Cloud Data
```

Bắt buộc:

- Phân vùng dữ liệu local theo User ID.
- User B không nhìn thấy Playlist, Favorites hoặc History riêng của User A.
- Không sử dụng chung một tập dữ liệu người dùng đã đăng nhập.
- Khi Guest sử dụng ứng dụng, không tự động đưa dữ liệu Guest vào tài khoản User.

### 8. Guest-to-Account Migration

Chỉ cho phép chuyển dữ liệu Guest sang tài khoản khi có chính sách rõ ràng trong Phase 1.

Nếu chưa có chính sách:

```text id="f02qs0"
Guest Data
    ↓
Remain Local
```

Không tự động upload hoặc gộp Playlist Guest vào tài khoản vừa đăng nhập.

Nếu requirement yêu cầu chuyển đổi:

- Xác định chính xác dữ liệu được phép chuyển.
- Xác định UUID cần giữ hoặc mapping.
- Kiểm tra trùng.
- Yêu cầu xác nhận người dùng nếu phù hợp.
- Sử dụng Batch Sync và idempotency.
- Không chuyển file audio binary.

### DONE

```text id="4mzlhh"
[ ] Initial Restore hoạt động
[ ] Pull dữ liệu cá nhân hoạt động
[ ] Playlist được khôi phục đúng
[ ] Favorites được khôi phục đúng
[ ] History được khôi phục đúng
[ ] UUID được giữ
[ ] Không tạo dữ liệu trùng
[ ] Incremental Pull hoạt động nếu contract yêu cầu
[ ] Conflict không ghi đè Pending Local
[ ] Tombstone được xử lý
[ ] User Isolation hoạt động
[ ] Guest Data không bị merge trái chính sách
[ ] Downloaded Audio không bị xóa
```

---

## TASK 7.8 — DOWNLOAD UI INTEGRATION (QA08)

### 🎯 Mục tiêu

Tích hợp trạng thái Download và file local đã được triển khai trong Phase 6 vào các màn hình và Repository của ứng dụng.

Phase 7 chỉ tích hợp và chuẩn hóa trạng thái hiển thị, không viết lại Download Service.

### Cách làm

#### 1. Audit Download Service

Đọc:

```text id="8q3zsn"
Download Service
Download Repository
Download Metadata
Download State
SongRepository
Player
Song Detail
Playlist Screen
Download UI
```

Xác định:

```text id="2kmc5j"
Song ID
Download Status
Local File Path
File Size
Downloaded At
Progress
Download Error
Audio Source
```

#### 2. UI Integration

Các màn hình liên quan cần hiển thị trạng thái phù hợp:

```text id="797h3b"
Search Results
Song Detail
Player
Playlist
Download List
Music Library
```

Tùy theo thiết kế hiện tại, không bắt buộc phải tạo màn hình mới nếu tính năng đã có.

#### 3. Download States

Hiển thị:

```text id="a6o7xu"
NOT DOWNLOADED
DOWNLOADING
DOWNLOADED
FAILED
CANCELLED
FILE MISSING
```

Tên trạng thái thực tế phải khớp Download Service của Phase 6.

#### 4. Offline Integration

Khi file đã tải:

- UI hiển thị Downloaded.
- Player sử dụng Local Source khi phù hợp.
- Không gọi stream khi không cần thiết.
- Không tải lại file mỗi lần mở màn hình.
- Nếu file bị xóa bên ngoài ứng dụng, phải cập nhật trạng thái đúng.

#### 5. Download & Sync Separation

Không gửi binary audio qua Batch Sync.

Nếu có đồng bộ thông tin Download, chỉ đồng bộ những metadata đã được yêu cầu rõ ràng.

Ví dụ:

```text id="573x1h"
Downloaded File
    └── Device-owned

Download Status
    └── Local metadata

Cloud Catalog
    └── Backend-owned
```

Không đồng bộ đường dẫn local sang tài khoản khác.

Không tự động tải lại toàn bộ nhạc sau khi đăng nhập trên thiết bị mới.

### DONE

```text id="e74cpp"
[ ] Download Service được tái sử dụng
[ ] Download UI hiển thị đúng State
[ ] Download Metadata Mapping đúng
[ ] Local File Path được giữ
[ ] Missing File được phát hiện
[ ] Offline Player nhận đúng Local Source
[ ] Không tải lại file không cần thiết
[ ] Không gửi Audio Binary vào Batch Sync
[ ] Không ảnh hưởng Download của Phase 6
```

---

## TASK 7.9 — ACCOUNT ENTRY & PLAYLIST REPOSITORY (QA10)

### 🎯 Mục tiêu

Hoàn thiện sự phối hợp giữa AccountEntry, Guest Mode, Authentication State và PlaylistRepository để dữ liệu local và cloud không bị trộn lẫn.

### 7.9.1 — AccountEntry

Kiểm tra:

```text id="9qftfj"
AccountEntry
AuthViewModel
Authentication State
Guest Mode
Session Restore
SyncService
```

Luồng:

```text id="ts974m"
App Startup
     ↓
Restore Auth State
     |
  +--+------------------+
  |                     |
Authenticated         Guest
  |                     |
Load User Data       Load Guest Data
  |                     |
Check Pending Sync    Local Only
  |                     |
Sync When Online       No Cloud Sync
  |
Main App
```

Yêu cầu:

- Khi User đăng nhập, tải đúng dữ liệu cloud của tài khoản.
- Khi Guest sử dụng, chỉ quản lý dữ liệu local.
- Khi User logout, không tự xóa nhạc local.
- Khi User A chuyển sang User B, đổi vùng dữ liệu cá nhân đúng tài khoản.
- Không để Sync Worker của User A tiếp tục gửi request bằng token User B.
- Không tự gộp dữ liệu Guest hoặc User khác.

### 7.9.2 — PlaylistRepository

Chuẩn hóa:

```text id="09munq"
Create Playlist
Get My Playlists
Get Playlist Detail
Update Playlist
Delete Playlist
Add Song
Remove Song
Reorder Songs (nếu có)
```

Cách hoạt động:

**Online**

```text id="1b8wre"
User Action
    ↓
Update Local Database
    ↓
Enqueue Operation
    ↓
Send Batch
    ↓
Receive Server Result
    ↓
Mark Synced
```

**Offline**

```text id="4qlz0u"
User Action
    ↓
Update Local Database
    ↓
Enqueue Operation
    ↓
Update UI
    ↓
Wait for Network
```

Yêu cầu:

- User sử dụng Playlist local ngay khi offline.
- Không yêu cầu API hoàn tất mới hiển thị Playlist.
- UUID phải ổn định.
- Không tạo Playlist trùng khi Sync.
- Playlist Songs giữ đúng thứ tự.
- Delete phải có quy tắc tombstone nếu cần đồng bộ.
- Conflict phải tuân thủ Phase 1.

### 7.9.3 — Account Ownership

Mỗi Playlist thuộc một nguồn quản lý:

```text id="1qkv8r"
GUEST
AUTHENTICATED USER
```

Không dùng một Playlist Repository duy nhất nhưng bỏ qua thông tin User đang quản lý dữ liệu.

Khi chuyển tài khoản:

- Không hiển thị nhầm Playlist.
- Không gửi operation của tài khoản cũ bằng JWT tài khoản mới.
- Không xóa dữ liệu offline chưa được xử lý.
- Pending Operation phải gắn với namespace/User tương ứng.

### DONE

```text id="f3x9d4"
[ ] AccountEntry Restore hoạt động
[ ] Guest Mode hoạt động
[ ] Authenticated State hoạt động
[ ] User Switching đúng
[ ] PlaylistRepository hỗ trợ Offline-first
[ ] Create Playlist Offline hoạt động
[ ] Update Playlist Offline hoạt động
[ ] Delete Playlist Offline hoạt động
[ ] Add / Remove Song Offline hoạt động
[ ] UUID ổn định
[ ] Sync theo đúng User
[ ] Không trộn dữ liệu giữa các tài khoản
```

---

## TASK 7.10 — ONLINE / OFFLINE TESTS (QA09)

### 🎯 Mục tiêu

Kiểm chứng toàn bộ cơ chế Offline-first và Synchronization trên Flutter, SQLite và Backend thực tế.

### Cách làm

#### 1. Local Repository Tests

Kiểm tra:

```text id="e55ahb"
SongRepository
LocalRepository
PlaylistRepository
Favorites Repository
History Repository
```

#### 2. Connectivity Tests

Kiểm tra:

```text id="1g0u4g"
Online
Offline
Network Restored
Backend Unreachable
App Resumed
Sync Running
```

#### 3. Offline Operation Tests

Kịch bản:

```text id="b9srah"
1. Tắt Internet
2. Mở WaveBox
3. Tạo Playlist
4. Thêm Song
5. Xóa Song khỏi Playlist
6. Thay đổi Playlist
7. Kiểm tra UI
8. Kiểm tra SQLite
9. Kiểm tra pending_sync
10. Đóng ứng dụng
11. Mở lại ứng dụng
12. Kiểm tra dữ liệu còn tồn tại
```

Kết quả:

```text id="s1mcmk"
Local Data: PRESERVED
Pending Operations: PRESERVED
UI: UPDATED
```

#### 4. Sync After Network Restored

Kịch bản:

```text id="hn7ijx"
1. Có Pending Operations
2. Khôi phục Internet
3. Kiểm tra Backend Reachability
4. Trigger Sync
5. Gửi Batch
6. Nhận kết quả
7. Đánh dấu Synced
8. Pull Remote Changes
9. Kiểm tra PostgreSQL
10. Kiểm tra SQLite
```

#### 5. Retry & Idempotency Tests

Bắt buộc kiểm tra:

```text id="f1yrx7"
Request Timeout
Server Processed But Response Lost
Retry Same operationId
Duplicate Operation
Conflict Operation
Invalid Operation
Partial Batch Result
```

Không được tạo dữ liệu trùng khi Client không nhận được response lần đầu.

#### 6. Pull & Restore Tests

```text id="n2cavk"
First Login
Existing Local Data
Existing Cloud Data
Incremental Changes
Deleted Remote Data
Conflict With Pending Local
Pagination / Cursor
```

#### 7. Two-User Isolation Tests

Tạo:

```text id="qc6hqo"
User A
User B
Guest
```

Kiểm tra:

```text id="ecb1fy"
User A:
- Own Playlist visible
- Own Favorites visible
- Own History visible

User B:
- Own Playlist visible
- Own Favorites visible
- Own History visible

Guest:
- Guest local data visible
- No authenticated cloud data
```

Các tình huống bắt buộc:

- User A logout.
- User B login.
- User B không thấy dữ liệu riêng của A.
- Pending Operation của A không được gửi dưới token B.
- Guest không tự động merge vào User B.
- Logout không xóa Downloaded Audio.

#### 8. Download Integration Tests

Kiểm tra:

```text id="4k8y9t"
Downloaded Song Online
Downloaded Song Offline
Missing Downloaded File
Download Metadata
Local Playback
```

#### 9. Regression Tests

Bắt buộc kiểm tra lại:

```text id="jv5rzq"
Login / Register
Guest Mode
Session Restore
Local Music Library
Search Local
Search Online
Player
Background Audio
Notification
Download
Offline Playback
Playlist
Favorites
History
```

#### 10. Commands

```bash id="dp8smq"
flutter pub get
```

```bash id="0x6nwp"
flutter analyze
```

```bash id="9lxxqn"
flutter test
```

Build Android:

```bash id="wyq4ka"
flutter build apk --debug
```

Kiểm thử phải bao gồm:

- Unit Tests.
- Repository Tests.
- SQLite Migration Tests.
- Sync Integration Tests.
- Backend Integration Tests.
- Thiết bị thực tế khi có thể.

### DONE

```text id="f8p9eh"
[ ] Local Repository Tests PASS
[ ] Connectivity Tests PASS
[ ] Offline Operation Tests PASS
[ ] Pending Queue Persistence PASS
[ ] Batch Sync Tests PASS
[ ] Retry / Idempotency Tests PASS
[ ] Pull / Restore Tests PASS
[ ] Download Integration Tests PASS
[ ] Two-User Isolation Tests PASS
[ ] Guest Isolation Tests PASS
[ ] Regression Tests PASS
[ ] Flutter Analyze PASS
[ ] Android Build PASS
```

---

## TASK 7.11 — DOCUMENTATION & PHASE 7 REPORT

### 🎯 Mục tiêu

Tài liệu hóa kiến trúc Offline-first, cơ chế Sync và trạng thái dữ liệu để Phase 8 có thể kiểm thử tổng thể.

Tạo:

```text id="bkgvc7"
docs/REPORT/PHASE-7-OFFLINE-SYNC.md
```

Cập nhật nếu có thay đổi được chấp thuận:

```text id="vlz5qa"
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
```

Báo cáo tối thiểu:

```markdown
# PHASE 7 — OFFLINE-FIRST & SYNCHRONIZATION REPORT

## 1. Existing Source Audit
- SongRepository
- LocalRepository
- PlaylistRepository
- SyncService
- ConnectivityService

## 2. SongRepository Mapping
- Local Song ID
- Backend Song ID
- Audio Source
- Metadata Mapping

## 3. SoundHelix Replacement
- Removed Demo References
- Backend API Integration
- Streaming Source

## 4. Local Repository Architecture
- SQLite
- Repository Responsibilities
- Migration Results

## 5. Connectivity & Sync Trigger
- Connectivity Detection
- Backend Reachability
- Sync Worker
- Retry Policy

## 6. enqueueSync & Pending Queue
- Operation Schema
- Atomic Enqueue
- Operation Ordering
- Queue Persistence

## 7. Batch Synchronization
- Batch Request
- Result Handling
- Idempotency
- Conflict Handling

## 8. Pull & Restore
- Initial Restore
- Incremental Pull
- Tombstone
- User Isolation

## 9. Download UI Integration

## 10. AccountEntry & PlaylistRepository

## 11. Online / Offline Test Results

## 12. Known Issues & Dependencies

## 13. Phase 7 Acceptance
- Completed Tasks
- Pending Tasks
- Final Status
```

### DONE

```text id="pfv8wu"
[ ] Phase 7 Report hoàn chỉnh
[ ] Local Data Mapping được mô tả
[ ] Pending Queue được mô tả
[ ] Batch Sync được mô tả
[ ] Restore Flow được mô tả
[ ] User Isolation được mô tả
[ ] Download Integration được mô tả
[ ] API Contract nhất quán
[ ] Decision Log được cập nhật
[ ] Test Results có bằng chứng
```

---

# 5. PHASE 7 FINAL REVIEW

## 🎯 Mục tiêu

Kiểm tra toàn bộ QA01–QA10 trước khi bàn giao ứng dụng cho Phase 8.

### DONE Checklist

```text id="ba0k7f"
[ ] TASK 7.1 — SongRepository Mapping (QA01)
[ ] Local / Backend Song ID Mapping
[ ] Metadata Mapping
[ ] Audio Source Mapping
[ ] Không tạo Song trùng

[ ] TASK 7.2 — Replace SoundHelix (QA02)
[ ] SoundHelix references đã được xử lý
[ ] Music Catalog lấy từ Backend
[ ] Audio Source dùng API thực tế
[ ] Offline Playback được giữ nguyên

[ ] TASK 7.3 — Standardize LocalRepository (QA03)
[ ] Repository Responsibilities rõ ràng
[ ] SQLite Access được chuẩn hóa
[ ] Local Data Transactions
[ ] Migration bảo toàn dữ liệu

[ ] TASK 7.4 — Connectivity & Sync Trigger (QA04)
[ ] Connectivity Detection
[ ] Backend Reachability
[ ] Network Restored Trigger
[ ] Login Trigger
[ ] App Resume Trigger
[ ] Không có Sync Worker trùng
[ ] Retry có giới hạn

[ ] TASK 7.5 — enqueueSync (QA05)
[ ] Tất cả thao tác cần Sync đã được kiểm tra
[ ] Atomic Enqueue
[ ] operationId duy nhất
[ ] Pending Queue không mất dữ liệu
[ ] Operation Ordering đúng

[ ] TASK 7.6 — Batch Sync (QA06)
[ ] Batch Request đúng Contract
[ ] Per-operation Result
[ ] APPLIED
[ ] DUPLICATE
[ ] CONFLICT
[ ] REJECTED
[ ] Idempotency
[ ] Retry an toàn
[ ] Không trộn User

[ ] TASK 7.7 — Pull & Restore (QA07)
[ ] Initial Restore
[ ] Incremental Pull
[ ] Playlist Restore
[ ] Favorites Restore
[ ] History Restore
[ ] Conflict Resolution
[ ] Tombstone
[ ] User Data Isolation

[ ] TASK 7.8 — Download UI Integration (QA08)
[ ] Download State
[ ] Download Metadata
[ ] Local Source
[ ] Missing File
[ ] Không ảnh hưởng Download Service
[ ] Không đồng bộ Audio Binary

[ ] TASK 7.9 — AccountEntry & PlaylistRepository (QA10)
[ ] AccountEntry
[ ] Guest Mode
[ ] Authenticated State
[ ] User Switching
[ ] Playlist CRUD Offline
[ ] Playlist Sync
[ ] Không trộn dữ liệu tài khoản

[ ] TASK 7.10 — Online / Offline Tests (QA09)
[ ] Offline Tests
[ ] Online Tests
[ ] Retry Tests
[ ] Restore Tests
[ ] Two-User Isolation
[ ] Regression Tests
[ ] Flutter Analyze
[ ] Android Build

[ ] TASK 7.11 — Documentation
[ ] Phase 7 Report
[ ] API Contract Consistency
[ ] Decision Log Updated

[ ] Không mất SQLite Data
[ ] Không mất Pending Operations
[ ] Không xóa Downloaded Audio
[ ] Không làm hỏng Phase 1–6
[ ] Git status đã được kiểm tra
```

---

# 6. ĐIỀU KIỆN PHASE 7 DONE

Chỉ được đánh dấu hoàn thành khi có bằng chứng:

**1. Offline-first**

```text id="8v89qc"
Local Library Offline: PASS
Playlist Offline: PASS
Favorites Offline: PASS
History Offline: PASS
Downloaded Playback Offline: PASS
```

**2. Pending Queue**

```text id="qet59k"
Atomic Enqueue: PASS
Queue Persistence: PASS
Operation ID: PASS
Operation Ordering: PASS
No Lost Operations: PASS
```

**3. Batch Sync**

```text id="ec33va"
Batch API: PASS
APPLIED: PASS
DUPLICATE: PASS
CONFLICT: PASS
REJECTED: PASS
Idempotent Retry: PASS
```

**4. Pull & Restore**

```text id="1l9dpr"
Initial Restore: PASS
Incremental Pull: PASS (nếu được contract yêu cầu)
Playlist Restore: PASS
Favorites Restore: PASS
History Restore: PASS
Conflict Handling: PASS
```

**5. Account Isolation**

```text id="90fs3c"
User A Data: ISOLATED
User B Data: ISOLATED
Guest Data: ISOLATED
Cross-user Access: DENIED
Wrong-user Sync: DENIED
```

**6. Connectivity & Download**

```text id="bz9zvk"
Connectivity Detection: PASS
Backend Reachability: PASS
Auto Sync Trigger: PASS
Download UI: PASS
Downloaded Audio Preservation: PASS
```

**7. Build & Tests**

```text id="n9kf0a"
Flutter Analyze: PASS
Flutter Tests: PASS
Android Build: PASS
Online / Offline Integration Tests: PASS
```

Nếu có phần chưa kiểm thử được:

```text id="ae2vlw"
[PASS]
[FAILED]
[NOT TESTED]
[BLOCKED]
[OUT OF SCOPE]
```

Không đánh dấu Pending Queue PASS nếu chưa kiểm tra trường hợp đóng ứng dụng và mở lại.

Không đánh dấu Retry PASS nếu chưa kiểm tra tình huống Server đã xử lý operation nhưng Client không nhận được response.

Không đánh dấu Restore PASS nếu chưa thử ít nhất hai tài khoản để xác minh không trộn dữ liệu.

Không đánh dấu Offline-first PASS nếu ứng dụng chỉ hoạt động khi còn Internet.

---

# 7. STOP RULE

Sau khi hoàn thành Phase 7:

**DỪNG.**

Không tự chuyển sang triển khai các tính năng mới ngoài phạm vi.

Không tự tạo thêm:

```text id="zmllbe"
Music Catalog API
New Authentication API
New Download Architecture
New Player Engine
Firebase Sync Song Song
New Database
New Conflict Resolution Rules
```

Chỉ sửa lỗi phát hiện trong Phase 7 và hoàn thiện tài liệu bàn giao.

Chỉ khi người dùng xác nhận:

```text id="ztpmvr"
PHASE 7 DONE
```

mới chuyển sang:

```text id="4kiv7i"
PHASE 8 — E2E TESTING & ACCEPTANCE
```

---

# 8. TỔNG KẾT CẤU TRÚC PHASE 7

```text id="0n71xr"
PHASE 7 — OFFLINE-FIRST & SYNCHRONIZATION
│
├── TASK 7.1
│   └── SongRepository Mapping (QA01)
│
├── TASK 7.2
│   └── Replace SoundHelix with API (QA02)
│
├── TASK 7.3
│   └── Standardize LocalRepository (QA03)
│
├── TASK 7.4
│   └── Connectivity & Sync Trigger (QA04)
│
├── TASK 7.5
│   └── Verify enqueueSync & Pending Queue (QA05)
│
├── TASK 7.6
│   └── Batch Synchronization (QA06)
│
├── TASK 7.7
│   └── Pull & Restore Data (QA07)
│
├── TASK 7.8
│   └── Download UI Integration (QA08)
│
├── TASK 7.9
│   └── AccountEntry & PlaylistRepository (QA10)
│
├── TASK 7.10
│   └── Online / Offline Tests (QA09)
│
├── TASK 7.11
│   └── Documentation & Report
│
└── TASK 7.12
    └── Final Review & Stop
```

---

# 9. THỨ TỰ THỰC THI

```text id="6zbgxr"
READ PHASE 1–6 DOCUMENTS
            ↓
AUDIT EXISTING SQLITE & SYNC SOURCE
            ↓
MAP LOCAL SONG ↔ BACKEND SONG
            ↓
REPLACE SOUNDHELIX WITH MUSIC API
            ↓
STANDARDIZE LOCAL REPOSITORIES
            ↓
IMPLEMENT CONNECTIVITY & SYNC TRIGGER
            ↓
VERIFY ATOMIC enqueueSync
            ↓
INTEGRATE BATCH SYNC API
            ↓
IMPLEMENT PULL & RESTORE
            ↓
INTEGRATE DOWNLOAD UI
            ↓
INTEGRATE ACCOUNT ENTRY & PLAYLIST
            ↓
RUN ONLINE / OFFLINE TESTS
            ↓
RUN TWO-USER ISOLATION TESTS
            ↓
WRITE PHASE 7 REPORT
            ↓
FINAL REVIEW
            ↓
PHASE 7 DONE
            ↓
STOP
```

---

## NGUYÊN TẮC QUAN TRỌNG NHẤT

Phase 7 là giai đoạn hoàn thiện **khả năng hoạt động Offline-first và đồng bộ dữ liệu đáng tin cậy của WaveBox**.

Ba nguyên tắc bắt buộc:

1. **Local-first:** thao tác local được lưu và phản ánh ngay trên giao diện, không phụ thuộc việc Backend có phản hồi tức thời hay không.
2. **Never lose pending operations:** thao tác chưa được Server xác nhận phải được giữ lại và có thể Retry an toàn bằng cùng `operationId`.
3. **Strict user isolation:** dữ liệu Playlist, Favorites, History và Pending Queue phải được phân vùng đúng tài khoản; Guest không tự động trở thành dữ liệu của một User khác.

Batch Sync phải tận dụng API Phase 4, ApiClient Phase 5 và kiến trúc lưu file Phase 6. Không viết lại các thành phần đã hoàn thành và không tạo thêm một hệ thống Cloud song song.

**Kết quả cuối cùng: người dùng có thể sử dụng WaveBox khi mất mạng, dữ liệu offline không bị mất, các thao tác được đồng bộ khi có mạng trở lại và dữ liệu giữa các tài khoản luôn được tách biệt.**