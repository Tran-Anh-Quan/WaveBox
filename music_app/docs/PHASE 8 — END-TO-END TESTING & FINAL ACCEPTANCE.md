# PHASE 8 — END-TO-END TESTING & FINAL ACCEPTANCE

## 🎯 Mục tiêu Phase 8

Kiểm thử tích hợp toàn bộ ứng dụng WaveBox từ Flutter đến Spring Boot Backend và PostgreSQL, xác minh các chức năng Authentication, Music Catalog, Player, Download, Offline-first và Synchronization hoạt động chính xác trong điều kiện sử dụng thực tế.

Phase 8 tập trung vào:

```text
PHASE 1–7 — IMPLEMENTATION COMPLETED
                  ↓
AUDIT FINAL SOURCE & ENVIRONMENT
                  ↓
PREPARE TEST ENVIRONMENT
                  ↓
TEST FLUTTER → SPRING BOOT → POSTGRESQL
                  ↓
TEST AUTHENTICATION & SECURITY
                  ↓
TEST MUSIC CATALOG & STREAMING
                  ↓
TEST PLAYER & DOWNLOAD
                  ↓
TEST ONLINE / OFFLINE & SYNC
                  ↓
TEST USER DATA ISOLATION
                  ↓
RUN AUTOMATED TESTS & BUILD
                  ↓
FIX VERIFIED BLOCKING BUGS
                  ↓
POSTMAN & DOCUMENTATION
                  ↓
FINAL ACCEPTANCE REPORT
                  ↓
PHASE 8 DONE
```

**Phạm vi requirement:**

```text
H10 — End-to-End Testing

Integration Scope:
- Authentication
- User Profile
- Music Catalog
- Search & Filter
- Playlist
- Favorites
- History
- Audio Streaming
- Background Playback
- Download
- Offline Playback
- Batch Synchronization
- Pull & Restore
- Account Isolation
```

Đầu ra Phase 8 là một phiên bản WaveBox có thể khởi chạy, kiểm thử và bàn giao, kèm báo cáo kết quả kiểm thử, danh sách lỗi còn tồn tại, Postman Collection và tài liệu hướng dẫn chạy dự án.

Phase 8 **không phải phase triển khai thêm tính năng mới**. Chỉ được sửa lỗi có căn cứ phát hiện trong quá trình kiểm thử, trong phạm vi yêu cầu và kiến trúc đã được chốt ở Phase 1–7.

---

## 1. NGUYÊN TẮC TRIỂN KHAI

### 1.1 — Previous Phases Source of Truth Rule

Trước khi kiểm thử, bắt buộc đọc:

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/IMPLEMENTATION_ROADMAP.md

docs/REPORT/PHASE-2-BACKEND-CORE.md
docs/REPORT/PHASE-3-AUTH-SECURITY.md
docs/REPORT/PHASE-4-MUSIC-DATA.md
docs/REPORT/PHASE-5-FLUTTER-AUTH-API.md
docs/REPORT/PHASE-6-PLAYER-DOWNLOAD.md
docs/REPORT/PHASE-7-OFFLINE-SYNC.md
```

Kiểm tra toàn bộ source hiện tại:

```text
Flutter Application
Spring Boot Backend
PostgreSQL
SQLite
Flyway Migrations
API Contract
Authentication
Music Data
Player
Download
Synchronization
Postman Collection
```

Không mặc định rằng một chức năng đã hoàn thành chỉ vì báo cáo của phase trước đánh dấu PASS.

Phase 8 phải kiểm tra lại bằng cách chạy ứng dụng, gọi API, kiểm tra dữ liệu và đối chiếu kết quả thực tế.

### 1.2 — Real Integration First Rule

Ưu tiên kiểm thử hệ thống thực tế:

```text
Flutter App
     ↓
ApiClient
     ↓
Spring Boot REST API
     ↓
Service / Repository
     ↓
PostgreSQL
```

Đối với dữ liệu local:

```text
Flutter App
     ↓
Repository
     ↓
SQLite
     ↓
Local File Storage
```

Không chỉ sử dụng Mock để kết luận hệ thống đã tích hợp thành công.

Mock vẫn được phép dùng trong Unit Tests hoặc kiểm tra các tình huống khó tái tạo, nhưng các luồng nghiệm thu quan trọng phải được chạy với Backend và Database thực tế.

### 1.3 — No Roles & Ownership Rule

Hệ thống chỉ có một loại tài khoản:

```text
User
```

Không kiểm thử hoặc triển khai các role:

```text
ADMIN
MODERATOR
CUSTOMER
VENDOR
```

Phải kiểm tra quyền sở hữu dữ liệu:

```text
User A
  ├── Playlist A
  ├── Favorites A
  └── History A

User B
  ├── Playlist B
  ├── Favorites B
  └── History B
```

User A không được xem, sửa, xóa hoặc đồng bộ dữ liệu cá nhân của User B.

Backend phải xác định User từ JWT, không tin `userId` do Client gửi lên.

### 1.4 — Test Evidence Rule

Mọi kết quả kiểm thử phải có bằng chứng.

Mỗi Test Case ghi nhận:

```text
Test ID
Requirement ID
Test Scenario
Preconditions
Test Steps
Expected Result
Actual Result
Status
Evidence
Defect ID (nếu có)
```

Trạng thái:

```text
PASS
FAIL
BLOCKED
NOT TESTED
NOT APPLICABLE
```

Không được ghi PASS khi:

- Chỉ kiểm tra bằng mắt mà không thực hiện luồng cần kiểm thử.
- Chỉ chạy ứng dụng nhưng chưa kiểm tra Backend.
- API trả HTTP 200 nhưng dữ liệu không được lưu đúng.
- UI hiển thị thành công nhưng PostgreSQL không có dữ liệu tương ứng.
- Mock thành công nhưng API thực tế thất bại.
- Chưa kiểm thử trường hợp lỗi quan trọng.

### 1.5 — Environment Separation Rule

Phân biệt:

```text
DEVELOPMENT
TESTING
STAGING
PRODUCTION
```

Phase 8 ưu tiên Development và Testing. Có thể sử dụng Staging nếu đã được cấu hình.

Không chạy các kịch bản phá hủy dữ liệu trên Production.

Không sử dụng tài khoản thật hoặc dữ liệu cá nhân thật làm dữ liệu kiểm thử nếu không cần thiết.

Không hardcode:

```text
Database Credentials
JWT Secret
Google OAuth Secret
API Keys
Production Credentials
```

Không đưa credentials hoặc token thực tế vào báo cáo, screenshot, Postman Collection hoặc Git.

### 1.6 — Safe Test Data Rule

Sử dụng tài khoản và dữ liệu thử nghiệm riêng:

```text
TEST USER A
TEST USER B
TEST GUEST
TEST SONGS
TEST PLAYLISTS
TEST FAVORITES
TEST HISTORY
TEST AUDIO FILES
```

Dữ liệu phải có khả năng xác định và phân biệt với dữ liệu thực tế.

Yêu cầu:

- Không sử dụng dữ liệu mẫu trong production.
- Không tải file nhạc không được cấp phép.
- Chỉ sử dụng audio fixture hợp lệ hoặc file được phép kiểm thử.
- Không tự ý xóa dữ liệu thật.
- Không DROP hoặc TRUNCATE database.
- Không xóa SQLite của người dùng để làm sạch môi trường test.

Nếu cần môi trường test sạch, tạo dữ liệu kiểm thử riêng và có quy trình dọn dẹp chỉ áp dụng cho dữ liệu đó.

### 1.7 — Bug Fix Scope Rule

Trong Phase 8 được phép:

```text
✅ Sửa bug đã xác định được nguyên nhân
✅ Sửa API Integration bị sai
✅ Sửa Validation bị thiếu
✅ Sửa lỗi xử lý dữ liệu Local / Cloud
✅ Sửa lỗi Authentication
✅ Sửa lỗi Player / Download
✅ Sửa lỗi Offline / Sync
✅ Bổ sung Regression Tests
✅ Cập nhật tài liệu bị sai
```

Không được:

```text
❌ Tự tạo tính năng mới
❌ Thay đổi kiến trúc lớn không có quyết định
❌ Viết lại toàn bộ Backend
❌ Viết lại toàn bộ Flutter
❌ Xóa feature hiện có
❌ Xóa database để làm test PASS
❌ Thay đổi API Contract tùy tiện
❌ Bỏ qua lỗi để đánh dấu PASS
❌ Tắt bảo mật để test thuận tiện
❌ Commit / push khi chưa được yêu cầu
```

Nếu phát hiện lỗi cần thay đổi kiến trúc, ghi nhận và báo cáo thay vì tự ý triển khai một hướng mới.

### 1.8 — Preserve Existing Data Rule

Bắt buộc bảo vệ:

```text
PostgreSQL User Data
SQLite Local Data
Playlists
Favorites
History
Pending Sync Operations
Downloaded Audio Files
Original Imported Music
Authentication Sessions
```

Nếu có migration hoặc sửa dữ liệu phục vụ khắc phục lỗi:

- Phải xác định ảnh hưởng.
- Có phương án bảo toàn dữ liệu.
- Không sửa migration đã áp dụng.
- Ưu tiên migration bổ sung.
- Kiểm thử trên bản sao hoặc môi trường test trước.

---

## 2. ĐIỀU KIỆN BẮT ĐẦU

Phase 8 được phép bắt đầu khi:

```text
PHASE 1 — ARCHITECTURE DONE
              +
PHASE 2 — BACKEND CORE DONE
              +
PHASE 3 — AUTHENTICATION DONE
              +
PHASE 4 — MUSIC DATA DONE
              +
PHASE 5 — FLUTTER API INTEGRATION DONE
              +
PHASE 6 — PLAYER & DOWNLOAD DONE
              +
PHASE 7 — OFFLINE-FIRST & SYNC DONE
```

Hệ thống cần có:

```text
Flutter Source Code
Spring Boot Source Code
PostgreSQL Database
SQLite Database
API_CONTRACT.md
Backend Tests
Flutter Tests
Postman Collections
Environment Configuration
Test Accounts
Authorized Test Audio
```

### Kiểm tra môi trường

**Flutter:**

```bash
flutter --version
flutter doctor
flutter pub get
flutter analyze
```

**Backend:**

```bash
java -version
mvn -version
mvn clean test
```

Nếu sử dụng Gradle, dùng Gradle Wrapper tương ứng.

**Database:**

Kiểm tra PostgreSQL và trạng thái Flyway bằng công cụ quản trị database.

**Git:**

```bash
git status --short
```

### Dependency cần ghi nhận

```text
[DEPENDENCY — TEST DEVICE]
[DEPENDENCY — GOOGLE OAUTH CONFIGURATION]
[DEPENDENCY — TEST DATABASE]
[DEPENDENCY — AUTHENTICATED TEST ACCOUNTS]
[DEPENDENCY — LICENSED AUDIO FILES]
[DEPENDENCY — NETWORK ENVIRONMENT]
```

Nếu thiếu một dependency:

- Tiếp tục các kiểm thử không phụ thuộc vào thành phần đó.
- Ghi rõ phần bị BLOCKED.
- Không tự thay thế bằng dữ liệu giả rồi tuyên bố hệ thống đã nghiệm thu.

---

## 3. PHẠM VI PHASE 8

### CHỈ LÀM

```text
H10 — End-to-End Testing

Flutter → Spring Boot → PostgreSQL
Authentication & Security Tests
Music Catalog Tests
Search & Filter Tests
Playlist / Favorites / History Tests
Audio Streaming Tests
Background Player Tests
Download Tests
Offline Playback Tests
Batch Sync Tests
Pull & Restore Tests
User Isolation Tests
Regression Tests
Flutter Tests
Backend Tests
Android Build
Postman Collection
Project Documentation
Defect Tracking
Final Acceptance Report
```

### KHÔNG ĐƯỢC LÀM

```text
New Backend Architecture
New Flutter Architecture
New API Features
New Database Design
New Player Engine
New Authentication Mechanism
New Sync Mechanism
New Music Catalog
New UI Features
Unrequested Refactoring
Production Database Reset
```

Chỉ sửa lỗi cần thiết để đáp ứng các yêu cầu đã có trong Phase 1–7.

---

# 4. CÁC TASK THỰC HIỆN

## TASK 8.1 — FINAL SOURCE & ENVIRONMENT AUDIT (H10)

### 🎯 Mục tiêu

Xác minh toàn bộ thành phần cần thiết cho kiểm thử E2E tồn tại, cấu hình đúng và có thể khởi chạy.

### Cách làm

#### 1. Audit Backend

Kiểm tra:

```text
Spring Boot Application
Configuration
SecurityConfig
JWT
Auth Controller
User Controller
Music Catalog Controller
Search Controller
Streaming Controller
Playlist Controller
Favorites Controller
History Controller
Batch Sync Controller
Pull / Restore API
Exception Handler
Flyway Migrations
```

#### 2. Audit Flutter

Kiểm tra:

```text
main.dart
ApiClient
AuthRepository
AuthViewModel
Session Restore
Secure Token Storage
SongRepository
PlaylistRepository
SyncService
ConnectivityService
AppDatabase
Player Service
Download Service
Audio Handler
Search Screen
AccountEntry
```

#### 3. Audit Database

Kiểm tra:

```text
PostgreSQL:
- Users
- Refresh Sessions
- Songs
- Albums
- Artists
- Genres
- Playlists
- Playlist Songs
- Favorites
- History
- Sync Operation Records (nếu có)

SQLite:
- Local Songs
- Playlists
- Favorites
- History
- Download Metadata
- Pending Sync
```

Không giả định bảng hoặc tên bảng tồn tại đúng như danh sách. Phải đối chiếu schema thực tế và migration.

#### 4. Environment Validation

Kiểm tra:

```text
API_BASE_URL
Database Connection
JWT Configuration
Google OAuth Configuration
Media Storage Configuration
Download Storage
Network Configuration
```

#### 5. Existing Test Results

Thu thập:

```text
Backend Unit Test Results
Backend Integration Test Results
Flutter Unit Test Results
Flutter Widget Test Results
Previous Phase Regression Results
```

### DONE

Có bảng:

| Component | Status | Testability | Notes |
|---|---|---|---|
| Flutter Application | READY / BLOCKED | YES / NO | Ghi chú |
| Spring Boot | READY / BLOCKED | YES / NO | Ghi chú |
| PostgreSQL | READY / BLOCKED | YES / NO | Ghi chú |
| SQLite | READY / BLOCKED | YES / NO | Ghi chú |
| Authentication | READY / BLOCKED | YES / NO | Ghi chú |
| Music API | READY / BLOCKED | YES / NO | Ghi chú |
| Streaming | READY / BLOCKED | YES / NO | Ghi chú |
| Synchronization | READY / BLOCKED | YES / NO | Ghi chú |

---

## TASK 8.2 — FLUTTER → SPRING BOOT → POSTGRESQL E2E (H10)

### 🎯 Mục tiêu

Kiểm chứng dữ liệu đi xuyên suốt từ giao diện Flutter đến Spring Boot và được lưu hoặc truy vấn chính xác trong PostgreSQL.

### Cách làm

#### 1. Basic Connectivity

Luồng:

```text
Flutter
   ↓
ApiClient
   ↓
Spring Boot
   ↓
PostgreSQL
   ↓
Response
   ↓
Flutter UI
```

Kiểm tra:

- Flutter kết nối đúng Backend.
- Request đến đúng endpoint.
- JWT được gửi đúng khi cần.
- Backend xử lý request.
- PostgreSQL được truy vấn hoặc cập nhật.
- Response đúng API Contract.
- UI hiển thị đúng dữ liệu.

#### 2. End-to-End Data Verification

Không chỉ dựa vào response.

Ví dụ:

```text
1. User đăng nhập từ Flutter
2. Backend xác thực
3. Flutter nhận token
4. Flutter tạo Playlist
5. Backend nhận request
6. PostgreSQL lưu Playlist
7. Flutter nhận response
8. Gọi lại API lấy Playlist
9. Xác minh dữ liệu
```

Phải đối chiếu:

```text
Request
Backend Logs
Database State
API Response
Flutter UI State
```

#### 3. API Contract Verification

Mỗi API phải kiểm tra:

```text
HTTP Method
Endpoint
Authentication
Request Body
Response Body
HTTP Status
Error Code
Data Type
UUID
Timestamp
Pagination
```

Đặc biệt kiểm tra:

- `PUT` và `PATCH`.
- JSON field naming.
- Null và missing fields.
- UUID format.
- Error response.
- Pagination.
- Batch Sync Response.

Không tự sửa một phía để che lỗi contract. Nếu phát hiện sai lệch, phải xác định nguồn lỗi và cập nhật có kiểm soát.

### DONE

```text
[ ] Flutter gọi Backend thực tế
[ ] ApiClient gửi đúng request
[ ] Backend nhận đúng dữ liệu
[ ] PostgreSQL lưu đúng dữ liệu
[ ] API trả đúng response
[ ] Flutter hiển thị đúng dữ liệu
[ ] Data Mapping chính xác
[ ] Không có duplicate records ngoài ý muốn
[ ] API Contract nhất quán
```

---

## TASK 8.3 — AUTHENTICATION & SECURITY E2E

### 🎯 Mục tiêu

Kiểm thử toàn bộ vòng đời đăng nhập, xác thực và quản lý tài khoản từ Flutter đến Backend.

### Cách làm

Kiểm thử:

```text
REGISTER
LOGIN
TOKEN STORAGE
SESSION RESTORE
ACCESS TOKEN REFRESH
LOGOUT
PROFILE
CHANGE PASSWORD
GOOGLE SIGN-IN
GUEST MODE
ACCOUNT SWITCHING
```

#### Test Scenario

| Test ID | Scenario | Expected Result |
|---|---|---|
| AUTH-01 | Register hợp lệ | Tài khoản được tạo |
| AUTH-02 | Register email trùng | Bị từ chối đúng contract |
| AUTH-03 | Login đúng thông tin | Nhận token |
| AUTH-04 | Login sai password | Bị từ chối |
| AUTH-05 | Khởi động lại ứng dụng | Khôi phục phiên hợp lệ |
| AUTH-06 | Access Token hết hạn | Tự refresh |
| AUTH-07 | Refresh Token hết hạn | Phiên bị từ chối |
| AUTH-08 | Logout | Client xóa session, Server thu hồi refresh session khi kết nối thành công |
| AUTH-09 | Get Profile | Nhận đúng hồ sơ |
| AUTH-10 | Update Profile | Hồ sơ được cập nhật |
| AUTH-11 | Change Password | Password mới hoạt động |
| AUTH-12 | Google Sign-In | Nhận WaveBox JWT |
| AUTH-13 | Continue as Guest | Vào Guest Mode |
| AUTH-14 | Chuyển User | Không dùng nhầm token |

#### Token Security

Kiểm tra:

- Access Token được lưu trong Secure Storage.
- Refresh Token được lưu trong Secure Storage.
- Không lưu password.
- Không log token.
- Không sử dụng Google ID Token thay cho WaveBox JWT.
- Token không hợp lệ bị từ chối.
- Token hết hạn được xử lý đúng.
- Refresh Token bị thu hồi không thể sử dụng lại.
- Request không tự refresh vô hạn.

#### Security Tests

Tấn công thử nghiệm trong môi trường kiểm thử:

```text
Missing Authorization Header
Malformed JWT
Expired JWT
Invalid Signature
Tampered JWT
Revoked Refresh Token
Reused Refresh Token
Unauthorized Endpoint Access
```

#### Guest & Logout

Kiểm tra:

- Guest có thể sử dụng chức năng local.
- Guest không truy cập API cá nhân cần JWT.
- Logout không xóa nhạc đã tải.
- Logout không reset SQLite.
- Logout không làm mất thư viện nhạc local.
- Không tuyên bố Server đã thu hồi token khi request logout chưa thành công.

### DONE

```text
[ ] Register / Login E2E PASS
[ ] Session Restore PASS
[ ] Automatic Refresh PASS
[ ] Logout PASS
[ ] Profile PASS
[ ] Change Password PASS
[ ] Google Sign-In PASS hoặc BLOCKED rõ ràng
[ ] Guest Mode PASS
[ ] Account Switching PASS
[ ] JWT Security Tests PASS
[ ] No Sensitive Data Exposure
```

---

## TASK 8.4 — MUSIC CATALOG, SEARCH & PLAYLIST E2E

### 🎯 Mục tiêu

Kiểm thử các luồng dữ liệu âm nhạc từ Backend đến giao diện Flutter, bao gồm Catalog, Search, Playlist, Favorites và History.

### Cách làm

#### 1. Music Catalog

Kiểm tra:

```text
List Songs
Song Detail
List Albums
Album Detail
List Artists
Artist Detail
List Genres
Genre Detail
```

Yêu cầu:

- Dữ liệu lấy từ Backend thực tế.
- ID ánh xạ chính xác.
- Metadata hiển thị đúng.
- Artwork null được xử lý.
- Pagination hoạt động.
- Không tạo bài hát trùng khi tải lại Catalog.

#### 2. Search & Filter

Kiểm tra:

```text
Search Song
Search Artist
Search Album
Filter Genre
Filter Artist
Filter Album
Sort
Pagination
Empty Result
Invalid Query
```

Đồng thời kiểm tra:

- Local Search hoạt động khi offline.
- Online Search gọi Backend khi online.
- Lỗi Backend không làm mất khả năng tìm kiếm Local.
- Kết quả Local và Online được phân biệt rõ.

#### 3. Playlist E2E

Kịch bản:

```text
1. User Login
2. Create Playlist từ Flutter
3. Backend nhận request
4. PostgreSQL lưu Playlist
5. Flutter hiển thị Playlist
6. Add Song
7. Remove Song
8. Reorder Songs (nếu có)
9. Update Playlist
10. Delete Playlist
11. Xác minh dữ liệu Backend và Local
```

#### 4. Favorites

Kiểm tra:

```text
Add Favorite
Get Favorites
Remove Favorite
Duplicate Favorite
Favorite After App Restart
Favorite After Sync
```

#### 5. History

Kiểm tra:

```text
Record History
Get History
Repeated Listening Event
Duplicate Event Retry
History Pagination
History After Restore
```

History phải phân biệt các lượt nghe khác nhau của cùng một bài hát.

### DONE

```text
[ ] Catalog E2E PASS
[ ] Search E2E PASS
[ ] Filter / Sort PASS
[ ] Playlist CRUD PASS
[ ] Add / Remove Song PASS
[ ] Favorites PASS
[ ] History PASS
[ ] Pagination PASS
[ ] Backend / Local Mapping PASS
[ ] Không tạo duplicate ngoài ý muốn
```

---

## TASK 8.5 — AUDIO STREAMING, PLAYER & DOWNLOAD E2E

### 🎯 Mục tiêu

Kiểm thử toàn bộ quá trình lấy audio từ nguồn hợp lệ, phát nhạc, điều khiển Player, tải file về và phát lại khi offline.

### Cách làm

#### 1. Audio Streaming

Luồng:

```text
Flutter
   ↓
Select Song
   ↓
Music Metadata API
   ↓
Audio Streaming API
   ↓
Media Storage
   ↓
Audio Response
   ↓
just_audio
   ↓
Playback
```

Kiểm tra:

```text
Valid Audio File
Content-Type
Content-Length
Range Request
206 Partial Content
416 Range Not Satisfiable
Missing File
Unauthorized Access (nếu yêu cầu)
Network Failure
```

Không đánh dấu Streaming PASS nếu chỉ nhận HTTP 200 mà không phát được audio.

#### 2. Player

Kiểm tra:

```text
Play
Pause
Resume
Next
Previous
Seek
Queue
Volume
Repeat / Shuffle (nếu có)
Playback State
```

Đảm bảo:

- Chỉ có một Playback Engine chính.
- Không phát hai bài cùng lúc.
- Queue không bị trùng.
- Chuyển bài đúng.
- Player State đồng bộ giữa Full Player và Mini Player.

#### 3. Background Audio

Kiểm tra:

```text
Play Song
Switch App
Lock Screen
Open Notification
Pause
Resume
Next
Previous
Return to App
```

Kiểm tra thêm Audio Focus khi:

- Có cuộc gọi.
- Rút tai nghe.
- Cắm tai nghe.
- Ứng dụng khác phát âm thanh.
- Hệ điều hành tạm ngắt audio.

#### 4. Notification & Artwork

Kiểm tra:

- Song Title.
- Artist.
- Artwork.
- Playback State.
- Play/Pause.
- Next/Previous.
- Media Session.

Không để Notification hiển thị metadata của bài hát cũ sau khi chuyển bài.

#### 5. Download E2E

Kịch bản:

```text
1. Chọn bài hát được phép tải
2. Bắt đầu Download
3. Theo dõi Progress
4. Download hoàn tất
5. Xác minh file trên thiết bị
6. Xác minh Download Metadata trong SQLite
7. Mở lại ứng dụng
8. Kiểm tra Download Status
9. Phát file đã tải
```

Kiểm tra thêm:

```text
Cancel
Retry
Failed Download
Duplicate Download
Insufficient Storage
Invalid Response
Partial File
Missing Downloaded File
```

#### 6. Safe Delete

Thử các trường hợp:

```text
Delete Downloaded Copy
Protect Original Imported File
Protect Unknown File Path
Path Traversal
Missing File
Delete Failure
```

Kết quả:

- Chỉ xóa file thuộc vùng Download do ứng dụng quản lý.
- Không xóa file nhạc gốc.
- Không xóa metadata Catalog không liên quan.
- Không làm mất Playlist, Favorites hoặc History.

#### 7. Sleep Timer

Kiểm tra:

```text
Start Timer
Cancel Timer
Reset Timer
Timer Expiration
Background Timer
Screen Locked
```

Khi hết giờ, Player phải dừng hoặc tạm dừng theo thiết kế đã chốt.

### DONE

```text
[ ] Streaming E2E PASS
[ ] Range Request PASS
[ ] Player Controls PASS
[ ] Background Playback PASS
[ ] Notification PASS
[ ] Media Session PASS
[ ] Artwork PASS
[ ] Volume PASS
[ ] Download PASS
[ ] Safe Delete PASS
[ ] Offline Playback PASS
[ ] Sleep Timer PASS
```

---

## TASK 8.6 — OFFLINE-FIRST & SYNCHRONIZATION E2E

### 🎯 Mục tiêu

Kiểm thử hoạt động Offline-first, bảo đảm thao tác local không bị mất và dữ liệu được đồng bộ chính xác khi mạng được khôi phục.

Đây là một trong những phần quan trọng nhất của Phase 8.

### 1. Offline Mode

Tắt Wi-Fi và Mobile Data.

Kiểm tra:

```text
Local Music Library
Local Search
Downloaded Audio
Local Playlist
Local Favorites
Local History
Pending Sync Queue
```

Ứng dụng phải tiếp tục sử dụng được các tính năng local đã cam kết hỗ trợ offline.

### 2. Offline Playlist Operations

Kịch bản:

```text
1. Đăng nhập User A
2. Tắt Internet
3. Tạo Playlist
4. Thêm Song vào Playlist
5. Thay đổi tên Playlist
6. Xóa một Song khỏi Playlist
7. Kiểm tra SQLite
8. Kiểm tra pending_sync
9. Đóng ứng dụng
10. Mở lại ứng dụng
11. Xác minh dữ liệu vẫn tồn tại
```

Expected:

```text
Local Playlist: PRESERVED
Pending Operations: PRESERVED
UI State: UPDATED
Cloud Sync: WAITING
```

### 3. Sync After Network Restored

Kịch bản:

```text
1. Khôi phục Internet
2. Kiểm tra Backend Reachability
3. Trigger Sync
4. Lấy Pending Operations
5. Gửi Batch Request
6. Backend xử lý
7. PostgreSQL cập nhật
8. Client nhận kết quả
9. Client xác nhận từng Operation
10. Pull dữ liệu mới
11. Đối chiếu SQLite và PostgreSQL
```

Không xóa Pending Operation trước khi nhận được kết quả xác nhận.

### 4. Retry & Idempotency

Phải kiểm thử tình huống:

```text
Client Sends Batch
       ↓
Backend Processes Operation
       ↓
Network Response Lost
       ↓
Client Still Has Pending Operation
       ↓
Retry Same operationId
       ↓
Backend Returns Previous Result
       ↓
No Duplicate Data
```

Bắt buộc kiểm tra:

- Retry cùng `operationId`.
- Backend đã xử lý nhưng Client chưa nhận response.
- Duplicate Operation.
- Partial Batch Result.
- Network disconnect giữa Batch.
- Backend unavailable.
- Refresh Token hết hạn khi Sync.

Không được tạo UUID mới cho cùng thao tác khi Retry.

### 5. Pull & Restore

Kiểm thử:

```text
First Login
Initial Restore
Existing Local Data
Existing Cloud Data
Incremental Pull
Deleted Cloud Data
Pending Local Changes
Conflict Handling
```

Đảm bảo:

- Playlist được khôi phục.
- Favorites được khôi phục.
- History được khôi phục.
- UUID được giữ.
- Không tạo duplicate.
- Pending Local không bị xóa do Pull.
- Tombstone được xử lý nếu có.
- Downloaded Audio không bị xóa khi Restore Metadata.

### 6. Two-User Isolation

Chuẩn bị:

```text
USER A
USER B
GUEST
```

Kiểm thử:

| Scenario | Expected Result |
|---|---|
| User A tạo Playlist | Chỉ A sở hữu |
| User B đăng nhập | Không thấy Playlist riêng của A |
| User B tạo Favorites | Gắn với B |
| User A đăng nhập lại | Không thấy Favorites riêng của B |
| User A logout | Local Music vẫn được giữ |
| Guest sử dụng App | Không đọc Cloud Data riêng của User |
| A có Pending Queue | Không gửi bằng Token của B |
| B Restore Data | Chỉ nhận dữ liệu của B |

### 7. Conflict Resolution

Kiểm tra:

```text
Playlist Updated Locally
Playlist Updated on Cloud
          ↓
Detect Version Conflict
          ↓
Apply Conflict Policy
          ↓
Preserve / Merge / Mark Conflict
```

Không tự động ghi đè Local hoặc Cloud khi chưa xác định đúng quy tắc.

Phải kiểm tra riêng:

- Playlist Metadata.
- Playlist Songs.
- Favorites.
- History.

### DONE

```text
[ ] Offline Mode PASS
[ ] Local Operation Persistence PASS
[ ] Pending Queue Persistence PASS
[ ] Network Restored Trigger PASS
[ ] Batch Sync PASS
[ ] Idempotency PASS
[ ] Retry PASS
[ ] Pull & Restore PASS
[ ] Conflict Handling PASS
[ ] User A / B Isolation PASS
[ ] Guest Isolation PASS
[ ] Download Preservation PASS
```

---

## TASK 8.7 — SECURITY & DATA INTEGRITY TESTS

### 🎯 Mục tiêu

Kiểm tra bảo mật toàn hệ thống, xác minh dữ liệu đúng người sở hữu và không bị thay đổi trái phép.

### Cách làm

#### 1. Authentication Security

Kiểm tra:

```text
Invalid JWT
Expired JWT
Invalid Signature
Missing Token
Revoked Refresh Token
Refresh Token Reuse
Google Token Invalid Audience
```

#### 2. Ownership Security

Kiểm thử bằng hai tài khoản:

```text
User A
User B
```

Thử truy cập:

```text
Playlist A / Playlist B
Favorites A / Favorites B
History A / History B
Profile A / Profile B
Batch Operation A / Batch Operation B
```

Các thao tác truy cập chéo không được phép phải bị Backend từ chối.

Không dựa vào việc Flutter ẩn nút hoặc ẩn màn hình để kết luận bảo mật.

#### 3. Input Validation

Kiểm tra:

```text
Empty Fields
Malformed UUID
Invalid JSON
Oversized Payload
Invalid Pagination
Invalid Sort Field
Invalid Batch Action
Invalid Operation ID
Invalid File Identifier
```

#### 4. File & Streaming Security

Kiểm tra:

- Path Traversal.
- Truy cập file không tồn tại.
- Truy cập audio không có quyền.
- MIME Type sai.
- Range không hợp lệ.
- Physical Server Path không bị lộ.

#### 5. Data Integrity

Đối chiếu:

```text
User ID
Song ID
Playlist ID
Playlist-Song Relationship
Favorite Records
History Events
Download Metadata
Sync Operation ID
```

Kiểm tra:

- UUID không bị đổi ngoài ý muốn.
- Foreign Key còn hợp lệ.
- Không có dữ liệu trùng sai nghiệp vụ.
- Không có bản ghi cá nhân thuộc nhầm User.
- Pending Operation không bị mất.
- SQLite và PostgreSQL nhất quán sau khi Sync.

### DONE

```text
[ ] JWT Security PASS
[ ] Ownership Verification PASS
[ ] Input Validation PASS
[ ] File Security PASS
[ ] Data Integrity PASS
[ ] No Cross-user Data Leakage
[ ] No Plaintext Password Exposure
[ ] No Token / Secret Exposure
```

---

## TASK 8.8 — AUTOMATED TESTS & FINAL BUILD

### 🎯 Mục tiêu

Chạy toàn bộ kiểm thử tự động và build ứng dụng để xác minh không còn lỗi nghiêm trọng trước khi bàn giao.

### Cách làm

#### 1. Backend Tests

Chạy:

```bash
mvn clean test
```

Hoặc lệnh Gradle tương ứng.

Kiểm tra:

```text
Unit Tests
Repository Tests
Service Tests
Controller Tests
Security Tests
Authentication Tests
Music API Tests
Streaming Tests
Batch Sync Tests
Integration Tests
Flyway Migration Tests
```

Tổng hợp:

```text
Total Tests
Passed
Failed
Skipped
Errors
```

Không chỉ dựa vào exit code nếu một số test bị skip hoặc không được thực thi.

#### 2. Flutter Tests

Chạy:

```bash
flutter pub get
flutter analyze
flutter test
```

Kiểm tra:

```text
Unit Tests
Widget Tests
Repository Tests
ApiClient Tests
Authentication Tests
Player Tests
Download Tests
Offline Tests
Sync Tests
```

#### 3. Database Validation

Kiểm tra:

- Flyway migration.
- Schema.
- Constraints.
- Index.
- Foreign Keys.
- User Ownership.
- Sync Operation Records.
- Không có dữ liệu test lẫn vào production.

#### 4. Android Build

Build:

```bash
flutter build apk --release
```

Nếu cần kiểm tra nhanh:

```bash
flutter build apk --debug
```

Nếu project hỗ trợ iOS và có môi trường phù hợp, chạy build iOS tương ứng.

#### 5. Build Validation

Kiểm tra:

```text
Application Starts
Main Screen Displays
Login Works
Guest Mode Works
Player Works
Background Audio Works
Download Works
Offline Mode Works
```

Build thành công không đồng nghĩa mọi E2E Test đều PASS.

Phải kiểm tra trực tiếp ứng dụng sau khi cài bản build.

#### 6. Device Testing

Ưu tiên Android Physical Device.

Kiểm tra:

```text
Fresh Install
Existing App Upgrade (nếu có build cũ)
Login
Background Playback
Notification
Download
Offline Playback
Network Switching
Application Restart
```

Không kiểm thử Upgrade bằng cách xóa dữ liệu ứng dụng trước khi cài bản mới.

### DONE

```text
[ ] Backend Tests PASS
[ ] Backend Integration Tests PASS
[ ] Flyway Migration Tests PASS
[ ] Flutter Tests PASS
[ ] Flutter Analyze PASS
[ ] Android Release Build PASS
[ ] Physical Device Smoke Test PASS
[ ] No Critical Runtime Error
```

---

## TASK 8.9 — POSTMAN COLLECTION & PROJECT DOCUMENTATION

### 🎯 Mục tiêu

Hoàn thiện công cụ kiểm thử API và hướng dẫn khởi chạy, cấu hình và bàn giao dự án.

### 1. Postman Collection

Kiểm tra và hợp nhất các Collection đã có:

```text
postman/
├── WaveBox-Auth.postman_collection.json
├── WaveBox-Music-Data.postman_collection.json
└── WaveBox-Environment.example.json
```

Tên file thực tế có thể khác theo cấu trúc project hiện tại.

Postman phải bao gồm:

```text
AUTH
    Register
    Login
    Refresh
    Logout
    Google Sign-In
    Profile
    Change Password

MUSIC
    Songs
    Albums
    Artists
    Genres
    Search
    Filter

STREAMING
    Audio Stream
    Range Request

PLAYLIST
    Create
    Read
    Update
    Delete
    Add Song
    Remove Song

FAVORITES
    Add
    List
    Remove

HISTORY
    Record
    List

SYNC
    Batch Sync
    Duplicate Operation
    Conflict
    Rejected
    Pull / Restore
```

Yêu cầu:

- Đúng endpoint.
- Đúng HTTP method.
- Đúng JSON schema.
- Tự động lưu token vào biến môi trường.
- Kiểm tra response và HTTP status.
- Có test script cho các luồng quan trọng.
- Không chứa credentials thực tế.
- Có hướng dẫn sử dụng User A và User B để test ownership.

### 2. Project Documentation

Cập nhật hoặc tạo:

```text
README.md
docs/REPORT/PHASE-8-E2E-ACCEPTANCE.md
backend/.env.example
postman/WaveBox-Environment.example.json
```

Tài liệu phải hướng dẫn:

```text
Project Overview
System Architecture
Prerequisites
Environment Variables
PostgreSQL Setup
Flyway Migration
Spring Boot Startup
Flutter Setup
Flutter Startup
Android Emulator Configuration
Physical Device Configuration
Postman Usage
Test Execution
Troubleshooting
Known Limitations
```

### 3. Run Commands

Cung cấp lệnh chạy Backend:

```bash
mvn spring-boot:run
```

Hoặc lệnh phù hợp với build tool hiện tại.

Cung cấp lệnh chạy Flutter:

```bash
flutter pub get
flutter run
```

Cung cấp lệnh kiểm thử:

```bash
mvn clean test
flutter analyze
flutter test
```

Cung cấp lệnh build:

```bash
flutter build apk --release
```

Không ghi password hoặc secret thực tế vào README.

### 4. Delivery Package

Chuẩn bị các thành phần bàn giao:

```text
WaveBox Source Code
Backend Source
Flutter Source
Database Migration Files
API Contract
Postman Collections
Environment Templates
Run Instructions
Test Reports
Known Issues
Build Artifact
```

Nếu có file build hoặc gói bàn giao, phải ghi rõ:

- Phiên bản.
- Ngày build.
- Môi trường build.
- Commit hoặc revision tương ứng nếu có.
- Các dependency bên ngoài cần cấu hình.

### DONE

```text
[ ] Postman Collections đầy đủ
[ ] Environment Template an toàn
[ ] README hoàn chỉnh
[ ] Hướng dẫn chạy Backend
[ ] Hướng dẫn chạy Flutter
[ ] Hướng dẫn Database
[ ] Hướng dẫn Test
[ ] Known Issues được liệt kê
[ ] Build Artifact được xác định
```

---

## TASK 8.10 — DEFECT TRACKING & FINAL ACCEPTANCE REPORT

### 🎯 Mục tiêu

Tổng hợp toàn bộ kết quả kiểm thử, phân loại lỗi, đánh giá mức độ hoàn thành và xác định các vấn đề còn tồn tại trước khi bàn giao.

### 1. Defect Classification

Phân loại lỗi:

```text
CRITICAL
HIGH
MEDIUM
LOW
```

**CRITICAL**

- Mất dữ liệu người dùng.
- User A truy cập được dữ liệu User B.
- Lộ password, JWT Secret hoặc credentials.
- Không thể chạy ứng dụng hoặc Backend.
- Migration làm mất dữ liệu.
- Không thể thực hiện các luồng cốt lõi.

**HIGH**

- Login/Refresh/Logout lỗi nghiêm trọng.
- Playlist hoặc Sync tạo dữ liệu sai.
- Không thể phát nhạc hoặc Download chức năng chính.
- Offline thao tác làm mất dữ liệu.
- Backend và Flutter không tương thích API Contract.

**MEDIUM**

- Một số màn hình hoặc trạng thái lỗi.
- Search/Filter không hoàn toàn chính xác.
- Retry hoặc Restore có trường hợp biên chưa xử lý.
- UI chưa cập nhật đúng trạng thái.

**LOW**

- Lỗi hiển thị nhỏ.
- Nội dung thông báo chưa chuẩn.
- Căn chỉnh giao diện.
- Vấn đề không ảnh hưởng nghiệp vụ chính.

### 2. Defect Report

Tạo bảng:

| Defect ID | Phase / Module | Description | Severity | Status | Evidence |
|---|---|---|---|---|---|
| BUG-001 | Auth | Mô tả lỗi thực tế | HIGH | OPEN / FIXED | Test ID |
| BUG-002 | Player | Mô tả lỗi thực tế | MEDIUM | OPEN / FIXED | Test ID |
| BUG-003 | Sync | Mô tả lỗi thực tế | CRITICAL | OPEN / FIXED | Test ID |

Không tạo lỗi giả để điền bảng.

### 3. Regression After Bug Fix

Mỗi khi sửa bug:

```text
Reproduce Bug
     ↓
Identify Root Cause
     ↓
Apply Minimal Fix
     ↓
Run Related Test
     ↓
Run Regression Test
     ↓
Verify No New Issue
     ↓
Update Defect Status
```

Không đánh dấu Fixed chỉ vì source đã thay đổi.

Phải chạy lại test tương ứng và có bằng chứng.

### 4. Acceptance Decision

Phân loại tổng thể:

```text
ACCEPTED
ACCEPTED WITH KNOWN ISSUES
REJECTED
BLOCKED
```

Quy tắc:

- `ACCEPTED`: các tiêu chí bắt buộc đã PASS, không còn lỗi Critical/High chưa xử lý.
- `ACCEPTED WITH KNOWN ISSUES`: các luồng cốt lõi và yêu cầu bắt buộc PASS, chỉ còn lỗi đã được đánh giá và chấp thuận.
- `REJECTED`: còn lỗi nghiêm trọng hoặc không đạt tiêu chí cốt lõi.
- `BLOCKED`: không thể hoàn thành nghiệm thu do thiếu môi trường hoặc dependency bắt buộc.

Không được tuyên bố hoàn thành nếu còn lỗi bảo mật, mất dữ liệu hoặc truy cập chéo giữa các User.

### 5. Final Acceptance Report

Tạo:

```text
docs/REPORT/PHASE-8-E2E-ACCEPTANCE.md
```

Cấu trúc:

```markdown
# PHASE 8 — E2E TESTING & FINAL ACCEPTANCE

## 1. Project Information
- Project Version
- Test Date
- Environment
- Build Information

## 2. Test Environment
- Flutter
- Spring Boot
- PostgreSQL
- Android Device
- Network Configuration

## 3. Backend Test Results

## 4. Flutter Test Results

## 5. Flutter → Spring Boot → PostgreSQL E2E

## 6. Authentication & Security

## 7. Music Catalog & Search

## 8. Playlist / Favorites / History

## 9. Streaming / Player / Download

## 10. Offline-first & Synchronization

## 11. User Isolation & Data Integrity

## 12. Automated Tests & Build

## 13. Postman & Documentation

## 14. Defect Summary

## 15. Known Issues & Limitations

## 16. Requirement Acceptance Matrix

## 17. Final Acceptance Decision

## 18. Handover Instructions
```

### DONE

```text
[ ] Test Results được tổng hợp
[ ] Defects được phân loại
[ ] Bug Fixes có Regression Evidence
[ ] Requirement Acceptance Matrix hoàn chỉnh
[ ] Known Issues được ghi rõ
[ ] Final Acceptance Decision được xác định
[ ] Handover Instructions đầy đủ
```

---

# 5. PHASE 8 FINAL REVIEW

## 🎯 Mục tiêu

Kiểm tra toàn bộ hệ thống trước khi xác nhận nghiệm thu và bàn giao.

### DONE Checklist

```text
[ ] TASK 8.1 — Final Source & Environment Audit
[ ] Flutter Source Ready
[ ] Backend Source Ready
[ ] PostgreSQL Ready
[ ] SQLite Ready
[ ] API Contract Available
[ ] Test Environment Available

[ ] TASK 8.2 — Flutter → Backend → Database
[ ] Flutter gọi Backend thực tế
[ ] Backend xử lý request
[ ] PostgreSQL lưu và truy vấn đúng
[ ] Response đúng Contract
[ ] Data Mapping chính xác

[ ] TASK 8.3 — Authentication & Security
[ ] Register
[ ] Login
[ ] Session Restore
[ ] Refresh
[ ] Logout
[ ] Profile
[ ] Change Password
[ ] Google Sign-In
[ ] Guest Mode
[ ] JWT Validation
[ ] User Ownership

[ ] TASK 8.4 — Music Data
[ ] Songs
[ ] Albums
[ ] Artists
[ ] Genres
[ ] Search
[ ] Filter
[ ] Playlist CRUD
[ ] Favorites
[ ] History

[ ] TASK 8.5 — Player & Download
[ ] Streaming
[ ] Range Request
[ ] Play / Pause / Next / Previous
[ ] Background Playback
[ ] Notification
[ ] Media Session
[ ] Artwork
[ ] Volume
[ ] Download
[ ] Safe Delete
[ ] Offline Playback
[ ] Sleep Timer

[ ] TASK 8.6 — Offline & Synchronization
[ ] Offline Mode
[ ] Pending Queue
[ ] Atomic Enqueue
[ ] Batch Sync
[ ] Retry
[ ] Idempotency
[ ] Pull
[ ] Restore
[ ] Conflict Handling
[ ] User Isolation

[ ] TASK 8.7 — Security & Data Integrity
[ ] Invalid JWT
[ ] Expired JWT
[ ] Unauthorized Access
[ ] Cross-user Access
[ ] Input Validation
[ ] File Security
[ ] Data Integrity

[ ] TASK 8.8 — Automated Tests & Build
[ ] Backend Tests
[ ] Backend Integration Tests
[ ] Flutter Tests
[ ] Flutter Analyze
[ ] Android Release Build
[ ] Physical Device Smoke Test

[ ] TASK 8.9 — Postman & Documentation
[ ] Postman Collections
[ ] Environment Templates
[ ] README
[ ] Database Setup Guide
[ ] Backend Run Guide
[ ] Flutter Run Guide
[ ] Test Guide

[ ] TASK 8.10 — Final Report
[ ] Defect Report
[ ] Requirement Acceptance Matrix
[ ] Known Issues
[ ] Acceptance Decision
[ ] Handover Instructions

[ ] Không còn lỗi Critical chưa xử lý
[ ] Không còn lỗi bảo mật nghiêm trọng
[ ] Không mất dữ liệu
[ ] Không trộn dữ liệu User
[ ] Không làm hỏng Player / Download
[ ] Git status đã được kiểm tra
```

---

# 6. ĐIỀU KIỆN PHASE 8 DONE

Chỉ được đánh dấu Phase 8 DONE khi có đủ bằng chứng:

**1. System Integration**

```text
Flutter → Spring Boot: PASS
Spring Boot → PostgreSQL: PASS
Flutter → PostgreSQL E2E: PASS
API Contract Consistency: PASS
```

**2. Authentication**

```text
Register: PASS
Login: PASS
Refresh: PASS
Logout: PASS
Session Restore: PASS
Profile: PASS
Google Sign-In: PASS hoặc có ngoại lệ được chấp thuận
Guest Mode: PASS
```

**3. Music Data**

```text
Catalog: PASS
Search: PASS
Playlist: PASS
Favorites: PASS
History: PASS
Streaming: PASS
```

**4. Player & Download**

```text
Playback: PASS
Background Audio: PASS
Notification: PASS
Media Session: PASS
Download: PASS
Safe Delete: PASS
Offline Playback: PASS
Sleep Timer: PASS
```

**5. Offline & Sync**

```text
Offline Operation: PASS
Pending Queue: PASS
Batch Sync: PASS
Retry: PASS
Idempotency: PASS
Pull & Restore: PASS
Conflict Resolution: PASS
User Isolation: PASS
```

**6. Security**

```text
JWT Verification: PASS
Invalid Token Rejection: PASS
Expired Token Rejection: PASS
Refresh Revocation: PASS
Cross-user Access: DENIED
Sensitive Data Exposure: NONE
```

**7. Build & Documentation**

```text
Backend Tests: PASS
Flutter Tests: PASS
Flutter Analyze: PASS
Android Release Build: PASS
Postman Collections: READY
README: COMPLETE
Acceptance Report: COMPLETE
```

Mỗi mục phải có trạng thái:

```text
[PASS]
[FAIL]
[BLOCKED]
[NOT TESTED]
[NOT APPLICABLE]
```

Không được tự chuyển một tiêu chí `BLOCKED` hoặc `NOT TESTED` thành PASS.

Các ngoại lệ phải ghi rõ nguyên nhân, phạm vi ảnh hưởng và người chấp thuận.

---

# 7. STOP RULE

Sau khi hoàn thành Phase 8:

**DỪNG.**

Không tự tạo thêm tính năng hoặc thay đổi kiến trúc sau nghiệm thu.

Không tự:

```text
Thêm API mới
Thay Database
Viết lại Player
Thay Authentication
Tạo Sync Engine mới
Thay đổi API Contract
Đưa dữ liệu test vào Production
Tự động triển khai Production
```

Nếu phát hiện lỗi sau nghiệm thu, ghi nhận thành Defect hoặc Change Request riêng.

Chỉ khi người dùng xác nhận:

```text
PHASE 8 DONE
```

mới được xem toàn bộ quá trình Phase 1–8 hoàn thành và chuyển sang trạng thái bàn giao dự án.

---

# 8. TỔNG KẾT CẤU TRÚC PHASE 8

```text
PHASE 8 — E2E TESTING & FINAL ACCEPTANCE
│
├── TASK 8.1
│   └── Final Source & Environment Audit
│
├── TASK 8.2
│   └── Flutter → Spring Boot → PostgreSQL E2E (H10)
│
├── TASK 8.3
│   └── Authentication & Security E2E
│
├── TASK 8.4
│   └── Music Catalog / Search / Playlist E2E
│
├── TASK 8.5
│   └── Streaming / Player / Download E2E
│
├── TASK 8.6
│   └── Offline-first & Synchronization E2E
│
├── TASK 8.7
│   └── Security & Data Integrity Tests
│
├── TASK 8.8
│   └── Automated Tests & Final Build
│
├── TASK 8.9
│   └── Postman & Project Documentation
│
├── TASK 8.10
│   └── Defect Tracking & Acceptance Report
│
└── TASK 8.11
    └── Final Review & Handover
```

---

# 9. THỨ TỰ THỰC THI

```text
READ PHASE 1–7 DOCUMENTS
            ↓
AUDIT FINAL SOURCE & ENVIRONMENT
            ↓
PREPARE TEST DATABASE & TEST ACCOUNTS
            ↓
START POSTGRESQL
            ↓
RUN FLYWAY MIGRATIONS
            ↓
START SPRING BOOT
            ↓
VERIFY BACKEND HEALTH
            ↓
RUN FLUTTER APPLICATION
            ↓
TEST FLUTTER → API → POSTGRESQL
            ↓
TEST AUTHENTICATION & SECURITY
            ↓
TEST MUSIC CATALOG & SEARCH
            ↓
TEST PLAYLIST / FAVORITES / HISTORY
            ↓
TEST STREAMING / PLAYER / DOWNLOAD
            ↓
TEST OFFLINE / BATCH SYNC / RESTORE
            ↓
TEST USER ISOLATION
            ↓
RUN BACKEND & FLUTTER TESTS
            ↓
BUILD AND VERIFY ANDROID APP
            ↓
FIX VERIFIED BLOCKING BUGS
            ↓
RUN REGRESSION TESTS
            ↓
COMPLETE POSTMAN & README
            ↓
WRITE FINAL ACCEPTANCE REPORT
            ↓
FINAL REVIEW
            ↓
PHASE 8 DONE
            ↓
HANDOVER
```

---

## NGUYÊN TẮC QUAN TRỌNG NHẤT

Phase 8 là giai đoạn xác nhận **toàn bộ WaveBox thực sự hoạt động như một hệ thống thống nhất**, không phải chỉ là tập hợp các module đã code xong.

Một chức năng chỉ được xem là hoàn thành khi:

- Flutter gửi request đúng.
- Backend xử lý đúng nghiệp vụ.
- PostgreSQL hoặc SQLite lưu dữ liệu đúng.
- Kết quả trả về đúng API Contract.
- UI thể hiện đúng trạng thái.
- Dữ liệu vẫn an toàn khi ứng dụng gặp lỗi, mất mạng hoặc khởi động lại.

Đặc biệt, phải xác minh được ba yếu tố cốt lõi:

1. **Data Integrity:** Không mất, không trùng và không ghi sai dữ liệu.
2. **Security:** Không User nào truy cập được dữ liệu cá nhân của User khác.
3. **Reliability:** Ứng dụng vẫn sử dụng được offline và đồng bộ lại an toàn khi có mạng.

**Kết quả cuối cùng không chỉ là một bản APK chạy được, mà là một phiên bản WaveBox có thể kiểm thử, có bằng chứng nghiệm thu, có tài liệu chạy dự án và có danh sách rõ ràng về mọi lỗi hoặc giới hạn còn tồn tại.**