# PHASE 1 — PHÂN TÍCH, AUDIT VÀ CHỐT KIẾN TRÚC

## 🎯 Mục tiêu Phase 1

Khảo sát toàn bộ Excel yêu cầu, tài liệu đặc tả và source code thực tế của dự án WaveBox trước khi triển khai Backend và tích hợp Flutter.

Phase 1 **không triển khai tính năng, không sửa source code**, chỉ tập trung xác định hiện trạng và chốt các quyết định kiến trúc dùng chung cho Phase 2–8.

Luồng thực hiện:

```text
Existing Project
       ↓
Audit Excel Requirements
       ↓
Audit Documentation
       ↓
Audit Flutter Source Code
       ↓
Audit Backend & Database (nếu đã tồn tại)
       ↓
Map Requirements ↔ Existing Implementation
       ↓
Resolve Architecture Conflicts
       ↓
Define API Contract
       ↓
Define Data & Sync Architecture
       ↓
Architecture Decision & Roadmap
       ↓
PHASE 1 DONE
```

Đầu ra bắt buộc:

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/IMPLEMENTATION_ROADMAP.md
```

Các tài liệu này là **Source of Truth** cho Phase 2–8. Những phase sau phải tuân thủ các quyết định đã được thống nhất trong Phase 1, không tự ý tạo API, cấu trúc dữ liệu hoặc cơ chế đồng bộ khác.

---

## 1. NGUYÊN TẮC PHÂN TÍCH

### 1.1 — Source-First Rule

Đọc source code và tài liệu thực tế trước khi đưa ra kết luận.

Không được mặc định rằng nội dung trong Excel, báo cáo hoặc kế hoạch triển khai đã được thực hiện trong source code.

Phải khảo sát tối thiểu các thành phần sau.

**Flutter Application**

```text
lib/
├── main.dart
├── core/
│   └── network/
│       └── api_client.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   └── presentation/
│   │       └── ...
│   ├── library/
│   │   └── data/
│   │       └── song_repository.dart
│   ├── sync/
│   │   └── data/
│   │       └── sync_service.dart
│   └── ...
├── data/
│   └── app_database.dart
└── ...
```

Đây là các đường dẫn cần ưu tiên kiểm tra theo cấu trúc đã biết. Phải tìm kiếm source thực tế để xác nhận, không được tạo file hoặc kết luận file tồn tại chỉ dựa trên danh sách này.

Đọc thêm toàn bộ các thành phần liên quan:

```text
ApiClient
ConnectivityService
AuthRepository
AuthViewModel
LoginScreen
RegisterScreen
ProfileScreen
SongRepository
SyncService
AppDatabase
audio_handler.dart
các Repository liên quan đến Playlist
các Repository liên quan đến Favorites
các Repository liên quan đến History
các Service liên quan đến Download
các màn hình Search, Album, Artist, Genre
```

**Backend Application — nếu đã tồn tại**

```text
pom.xml / build.gradle
application.yml / application.properties
Entity
DTO
Repository
Service
Controller
SecurityConfig
JWT Filter
Authentication Provider
Exception Handler
Flyway Migration
Database Configuration
```

Không mặc định Backend Spring Boot đã có sẵn. Nếu chưa tồn tại, ghi nhận:

```text
[NOT IMPLEMENTED — BACKEND NOT FOUND]
```

Không tạo Backend trong Phase 1.

**Database và cấu hình**

```text
SQLite schema
SQLite migrations
PostgreSQL schema (nếu có)
Flyway migrations (nếu có)
SharedPreferences
Secure Storage (nếu có)
Environment variables
API Base URL
Network configuration
Firebase configuration (nếu có)
```

### 1.2 — Documentation-First Comparison

Đọc toàn bộ tài liệu yêu cầu, Excel và báo cáo có liên quan.

Bắt buộc rà soát các nhóm:

```text
H01–H10     Backend
AQ01–AQ09   Backend Music Data
MQ01–MQ11   Flutter Authentication & API Integration
AT01–AT11   Flutter Player & Download
QA01–QA10   Offline-first & Synchronization
```

Tổng cộng:

```text
H01–H10    = 10 requirements
AQ01–AQ09  =  9 requirements
MQ01–MQ11  = 11 requirements
AT01–AT11  = 11 requirements
QA01–QA10  = 10 requirements
--------------------------------
TOTAL      = 51 requirements
```

Ngoài ra, đối chiếu với các Use Case chi tiết trong tài liệu Chương IV, từ UC 1.1 đến UC 10.4, tổng cộng 44 Use Case đã được thống kê.

Phải phân biệt rõ:

```text
REQUIREMENT
    ↓
USE CASE
    ↓
EXPECTED BEHAVIOR
    ↓
EXISTING IMPLEMENTATION
    ↓
GAP / CONFLICT
    ↓
TARGET PHASE
```

Không tự suy diễn nội dung của một requirement khi Excel không có dữ liệu hoặc không thể đọc được. Phải ghi rõ requirement nào thiếu nguồn, thiếu mô tả hoặc chưa đủ thông tin.

### 1.3 — Evidence-Based Decision

Mọi kết luận kiến trúc phải có căn cứ từ ít nhất một trong các nguồn:

```text
Excel Requirement
Source Code
Database Schema
Existing API
Use Case Specification
Project Configuration
```

Phân loại kết quả:

```text
[EXISTING]       Đã có trong source
[IMPLEMENTED]   Đã triển khai và hoạt động
[PARTIAL]       Đã triển khai một phần
[MISSING]       Chưa có
[BUG]           Có lỗi hoặc hành vi sai
[CONFLICT]      Mâu thuẫn giữa tài liệu và source
[DEPENDENCY]    Thiếu điều kiện hoặc cấu hình bên ngoài
[PROPOSED]      Phương án kiến trúc đề xuất
[DECIDED]       Quyết định đã được chốt
[OUT OF SCOPE]  Không thuộc phạm vi dự án
```

Không đánh dấu `[IMPLEMENTED]` chỉ vì file hoặc class đã tồn tại. Phải kiểm tra logic thực tế và test hiện có nếu có thể.

### 1.4 — Read-only Rule

Phase 1 chỉ được phép đọc source và tạo tài liệu kiến trúc.

```text
✅ Đọc source code
✅ Đọc Excel và tài liệu
✅ Đọc cấu trúc database
✅ Kiểm tra API hiện có
✅ Chạy các lệnh kiểm tra không làm thay đổi dữ liệu
✅ Tạo và cập nhật tài liệu trong docs/
✅ Tạo bảng mapping và báo cáo

❌ Không sửa source code
❌ Không tạo tính năng
❌ Không refactor
❌ Không cài thêm dependency
❌ Không tạo Entity, DTO, Controller hoặc Service
❌ Không tạo migration
❌ Không thay đổi database schema
❌ Không INSERT / UPDATE / DELETE dữ liệu
❌ Không DROP / TRUNCATE database hoặc table
❌ Không thay đổi cấu hình đang chạy
❌ Không commit / push Git
```

Trước khi bắt đầu, kiểm tra:

```bash
git status --short
```

Sau khi hoàn thành, kiểm tra lại để bảo đảm không có thay đổi ngoài các tài liệu Phase 1 được phép tạo.

Không được ghi đè hoặc xóa tài liệu cũ khi chưa kiểm tra nội dung và lịch sử của nó.

---

## 2. ĐIỀU KIỆN BẮT ĐẦU

Phase 1 có thể bắt đầu khi có:

```text
Project source code
       +
Excel Requirements
       +
Existing Documentation
       +
Flutter development environment (nếu có)
       +
Backend source (nếu đã có)
       +
Database files/configuration (nếu có)
```

Nếu một thành phần không tồn tại, vẫn tiếp tục audit các thành phần còn lại và ghi nhận trạng thái.

Ví dụ:

```text
[DEPENDENCY — EXCEL NOT FOUND]
[DEPENDENCY — BACKEND NOT FOUND]
[DEPENDENCY — POSTGRESQL NOT CONFIGURED]
[DEPENDENCY — GOOGLE OAUTH CONFIGURATION UNKNOWN]
```

Không tự tạo dữ liệu, tài khoản, database hoặc cấu hình giả để làm cho kết quả audit có vẻ hoàn chỉnh.

Nếu không thể chạy ứng dụng hoặc kết nối database, phải phân biệt:

```text
NOT TESTED
```

với:

```text
FAILED
```

Không được kết luận một chức năng bị lỗi chỉ vì môi trường kiểm thử chưa sẵn sàng.

---

## 3. PHẠM VI PHASE 1

### CHỈ LÀM

```text
1. Audit Excel Requirements
2. Audit Documentation và Use Case
3. Audit Flutter Source Code
4. Audit Backend Source Code (nếu có)
5. Audit Database và Local Storage
6. Mapping 51 Requirements
7. Phân tích các điểm mâu thuẫn
8. Chốt kiến trúc Backend–Flutter–Database
9. Chốt API Contract
10. Chốt Authentication, UUID và Synchronization
11. Lập kế hoạch triển khai Phase 2–8
12. Ghi báo cáo và review
```

### KHÔNG LÀM

```text
Triển khai Spring Boot
Tạo PostgreSQL Schema
Viết Flyway Migration
Tạo Entity / DTO / Repository
Viết API Controller
Cấu hình JWT thực tế
Tích hợp Google Sign-In
Sửa Flutter ApiClient
Viết lại SyncService
Thay đổi SQLite
Sửa Player / Download
Triển khai Batch Sync
Viết tính năng mới
```

---

# 4. CÁC TASK THỰC HIỆN

## TASK 1.1 — AUDIT EXCEL REQUIREMENTS

### 🎯 Mục tiêu

Xác định chính xác yêu cầu của toàn bộ hệ thống và mối quan hệ giữa 51 requirement với 8 phase triển khai.

### Cách làm

Đọc toàn bộ workbook, bao gồm:

- Tất cả sheet.
- Nội dung từng dòng và từng cột.
- Mô tả chức năng.
- Input và output.
- Điều kiện tiền đề.
- Luồng chính và luồng thay thế.
- Quy tắc nghiệp vụ.
- Điều kiện xử lý lỗi.
- Các ghi chú hoặc requirement phụ thuộc.

Đối chiếu đầy đủ:

```text
H01–H10
AQ01–AQ09
MQ01–MQ11
AT01–AT11
QA01–QA10
```

Với mỗi requirement, ghi nhận:

```text
Requirement ID
Requirement Name
Original Description
Expected Behavior
Input / Output
Dependencies
Related Use Case
Related Source File
Target Phase
Missing Information
Conflict
```

Không tự rút gọn hoặc thay đổi ý nghĩa yêu cầu gốc.

### DONE

Có bảng Requirement Traceability:

| ID | Requirement | Related Source | Related UC | Status | Target Phase | Notes |
|---|---|---|---|---|---|---|
| H01 | Theo nội dung Excel | File thực tế | UC liên quan | EXISTING / MISSING | Phase 2–3 | Ghi chú |
| AQ01 | Theo nội dung Excel | File thực tế | UC liên quan | EXISTING / MISSING | Phase 4 | Ghi chú |
| MQ01 | Theo nội dung Excel | File thực tế | UC liên quan | EXISTING / MISSING | Phase 5 | Ghi chú |
| AT01 | Theo nội dung Excel | File thực tế | UC liên quan | EXISTING / MISSING | Phase 6 | Ghi chú |
| QA01 | Theo nội dung Excel | File thực tế | UC liên quan | EXISTING / MISSING | Phase 7 | Ghi chú |

Bảng thực tế phải chứa đủ 51 requirement, không chỉ các dòng minh họa.

---

## TASK 1.2 — AUDIT FLUTTER SOURCE CODE

### 🎯 Mục tiêu

Xác định Flutter đã có những chức năng nào, đang sử dụng cơ chế nào và phần nào cần tích hợp hoặc thay đổi ở các phase sau.

### Cách làm

Rà soát các nhóm:

```text
AUTHENTICATION
API CLIENT
LOCAL DATABASE
SONG LIBRARY
PLAYLIST
FAVORITES
HISTORY
SEARCH
ONLINE MUSIC
BACKGROUND AUDIO
NOTIFICATION
DOWNLOAD
OFFLINE PLAYBACK
SYNC
CONNECTIVITY
```

Với từng thành phần, ghi nhận:

```text
File Path
Class / Method
Current Responsibility
Current Data Source
API Endpoint (nếu có)
Local Storage Used
Network Dependency
Current Behavior
Missing Requirement
Potential Conflict
Target Phase
```

Đặc biệt kiểm tra các thành phần đã biết hoặc từng xuất hiện trong source:

```text
ApiClient
ConnectivityService
AuthRepository
AuthViewModel
SongRepository
SyncService
AppDatabase
audio_handler.dart
just_audio
video_player
file_picker
SharedPreferences
```

Phải xác minh:

- `ApiClient` đang sử dụng base URL nào.
- Các API đang được gọi thực tế.
- Cơ chế lưu và khôi phục token.
- `AuthRepository` đang xử lý Register, Login, Google và Profile như thế nào.
- `SongRepository` đang ưu tiên dữ liệu local hay remote.
- SQLite đang có những bảng nào.
- Cơ chế `pending_sync` hoạt động ra sao.
- Cách retry và xử lý thao tác thất bại.
- Player và Download đang lưu file ở đâu.
- Chức năng nào hoạt động offline không cần Backend.

### DONE

Có bảng:

| Component | File Path | Current State | Data Source | Requirement Mapping | Issue |
|---|---|---|---|---|---|
| ApiClient | Đường dẫn thực tế | EXISTING / PARTIAL | REST API | MQ02 | Ghi chú |
| AuthRepository | Đường dẫn thực tế | EXISTING / PARTIAL | Backend | MQ01–MQ09 | Ghi chú |
| AppDatabase | Đường dẫn thực tế | EXISTING / PARTIAL | SQLite | QA01–QA10 | Ghi chú |
| SyncService | Đường dẫn thực tế | EXISTING / PARTIAL | Chưa kết luận | QA04–QA07 | Ghi chú |
| SongRepository | Đường dẫn thực tế | EXISTING / PARTIAL | Local / Remote | AQ01–AQ09 | Ghi chú |

---

## TASK 1.3 — AUDIT BACKEND, API VÀ DATABASE

### 🎯 Mục tiêu

Xác minh Backend và hệ thống lưu trữ hiện tại có gì, thiếu gì và có thể tái sử dụng phần nào.

### Cách làm

Nếu có Backend, đọc toàn bộ:

```text
Spring Boot Configuration
Controller
Service
Repository
Entity
DTO
Security
JWT
Exception Handler
Database Configuration
Flyway Migration
Tests
```

Nếu chưa có Backend, ghi nhận:

```text
[MISSING — SPRING BOOT BACKEND]
```

Kiểm tra các API hiện tại:

```text
/api/auth/register
/api/auth/login
/api/auth/google
/api/auth/profile
/api/songs
```

Đây là các endpoint từng được ghi nhận trong quá trình khảo sát trước đó; phải tìm và xác minh lại trong source hiện tại. Không được mặc định chúng vẫn tồn tại hoặc có cùng request/response.

Rà soát database:

**SQLite phía Flutter**

- Danh sách table.
- Primary key và Foreign key.
- Cấu trúc playlist.
- Favorites và History.
- Song metadata.
- Download metadata.
- Pending sync queue.
- SQLite version và migration.

**PostgreSQL phía Backend**

Nếu đã tồn tại, kiểm tra:

- Database và schema.
- Table và relationship.
- Primary key và Foreign key.
- Unique constraint.
- Index.
- Migration hiện có.

Không thay đổi dữ liệu hoặc schema trong quá trình khảo sát.

### DONE

Có bảng:

| Storage | Existing | Tables / Collections | Purpose | Status | Notes |
|---|---|---|---|---|---|
| Flutter SQLite | YES / NO | Theo source | Local data | EXISTING / MISSING | Ghi chú |
| PostgreSQL | YES / NO | Theo source | Cloud data | EXISTING / MISSING | Ghi chú |
| Local File Storage | YES / NO | Theo source | Audio downloads | EXISTING / MISSING | Ghi chú |
| Firebase Firestore | YES / NO | Theo source | Cloud sync nếu có | EXISTING / MISSING | Ghi chú |

---

## TASK 1.4 — REQUIREMENT MAPPING VÀ PHÂN TÍCH MÂU THUẪN

### 🎯 Mục tiêu

Tìm ra những điểm không thống nhất giữa Excel, Use Case, tài liệu kiến trúc và source code trước khi đưa ra quyết định cuối cùng.

### Cách làm

Đối chiếu:

```text
51 Requirements
       ↕
44 Detailed Use Cases
       ↕
Flutter Source Code
       ↕
Backend Source Code
       ↕
Database Schema
```

Ưu tiên kiểm tra các vấn đề sau:

**1. REST API và Firebase Firestore**

Tài liệu Chương IV có nhắc đến Firebase Cloud Firestore trong nhóm đồng bộ dữ liệu.

Trong khi đó, source Flutter từng được ghi nhận có:

```text
ApiClient
SyncService
pending_sync
REST API
```

Và kế hoạch triển khai đang định hướng:

```text
Flutter
   ↓
Spring Boot REST API
   ↓
PostgreSQL
```

Phải xác định:

- Firebase Firestore có thực sự được dùng trong source không?
- Firestore là kiến trúc cũ, mô tả dự kiến hay yêu cầu bắt buộc?
- Spring Boot có phải Backend duy nhất cho dữ liệu tài khoản và đồng bộ không?
- Có endpoint hoặc logic nào đang sử dụng song song hai hệ thống không?

**Nguyên tắc kiến trúc mục tiêu:** Không sử dụng đồng thời Spring Boot REST và Firestore làm hai nguồn dữ liệu chính cho cùng một loại dữ liệu nếu không có yêu cầu rõ ràng.

Phương án mặc định được đề xuất là Spring Boot REST + PostgreSQL làm Backend cloud chính; SQLite và file storage làm lớp lưu trữ local. Chỉ giữ Firestore nếu requirement gốc chứng minh nó là thành phần bắt buộc và có kiến trúc tích hợp được xác định rõ.

**2. Online và Offline**

Làm rõ:

- Bài hát nào được phát từ file local?
- Bài hát nào được stream từ Backend?
- Bài hát nào được tải về?
- Khi mất mạng, chức năng nào tiếp tục hoạt động?
- Metadata được lấy từ local hay Backend?
- Có được phép phát nhạc online khi chưa đăng nhập không?

**3. Local Database và Cloud Database**

Xác định dữ liệu nào được lưu:

- Chỉ local.
- Chỉ Backend.
- Cả local và Backend.
- Chỉ đồng bộ một phần.

**4. Authentication và User Ownership**

Đối chiếu Login, Register, Guest, Google Sign-In, Profile, Logout và đồng bộ theo tài khoản.

**5. Player và Download**

Kiểm tra sự thống nhất giữa `just_audio`, cơ chế background audio, notification, download và phát offline.

### DONE

Có bảng Conflict Resolution:

| Conflict ID | Source A | Source B | Conflict | Proposed Resolution | Status |
|---|---|---|---|---|---|
| C01 | Chương IV | SyncService | Firestore và REST | Chốt một nguồn cloud chính | DECIDED / OPEN |
| C02 | Excel | Flutter | Online/Offline behavior | Theo requirement đã xác minh | DECIDED / OPEN |
| C03 | SQLite | PostgreSQL | Local và cloud ownership | Chốt data ownership | DECIDED / OPEN |
| C04 | Auth documentation | Source | Cơ chế token | Chốt JWT flow | DECIDED / OPEN |

Không tự xóa bỏ một requirement chỉ vì source code hiện tại chưa triển khai.

---

## TASK 1.5 — CHỐT KIẾN TRÚC LƯU TRỮ DỮ LIỆU

### 🎯 Mục tiêu

Xác định chính xác vai trò của từng tầng lưu trữ và quyền sở hữu dữ liệu.

### Kiến trúc mục tiêu đề xuất

```text
                    FLUTTER APP
                         |
          +--------------+--------------+
          |              |              |
       UI Layer       Repository     Player
          |              |              |
          +--------------+--------------+
                         |
              +----------+----------+
              |                     |
         SQLite Local           Local Files
              |                     |
        Metadata/Cache         Downloaded Audio
        User Data
        Pending Sync
              |
              |
          REST API
              |
          SPRING BOOT
              |
       +------+------+ 
       |             |
   PostgreSQL    Media Storage
   Metadata      Audio/Artwork
   User Data
```

Đây là kiến trúc mục tiêu để đánh giá và xác nhận trong Phase 1, không phải xác nhận rằng tất cả thành phần đã tồn tại.

### Quy tắc lưu trữ cần chốt

| Dữ liệu | Local Flutter | Backend | Nguyên tắc |
|---|---|---|---|
| User Profile | Cache | PostgreSQL | Backend là nguồn dữ liệu chính khi có tài khoản |
| Authentication | Token trong secure storage | User và refresh session | Không lưu mật khẩu dạng thuần |
| Song Metadata | SQLite cache | PostgreSQL | Backend quản lý catalog |
| Audio File | Local file | Media storage | Không lưu file audio trực tiếp trong SQLite/PostgreSQL |
| Playlist | SQLite | PostgreSQL | Hỗ trợ offline và đồng bộ |
| Favorites | SQLite | PostgreSQL | Gắn với User |
| History | SQLite | PostgreSQL | Đồng bộ theo sự kiện |
| Download Metadata | SQLite | Có thể lưu trạng thái cần thiết | File nhạc thực tế nằm trên thiết bị |
| Pending Sync | SQLite | Không áp dụng | Chỉ tồn tại ở Client cho đến khi được xác nhận |

Nếu Excel quy định khác, phải ghi lại khác biệt và quyết định rõ ràng trước khi chốt kiến trúc.

### DONE

Có sơ đồ kiến trúc và bảng Data Ownership trong:

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
```

---

## TASK 1.6 — CHỐT API CONTRACT

### 🎯 Mục tiêu

Tạo một tài liệu thống nhất để Flutter và Backend triển khai cùng một chuẩn API, tránh sai lệch request, response, HTTP status và cơ chế đồng bộ.

Tạo:

```text
docs/API_CONTRACT.md
```

### 1.6.1 — API Convention

Chốt các quy tắc chung:

```text
Protocol: HTTP REST
Data Format: JSON
Encoding: UTF-8
JSON naming: camelCase
ID format: UUID
Timestamp: ISO-8601 UTC
Authentication: Bearer JWT
Content-Type: application/json
```

Mỗi endpoint phải khai báo:

```text
HTTP Method
URL
Authentication Required
Path Parameters
Query Parameters
Request Body
Success Response
Error Response
HTTP Status
Validation Rules
Ownership Rules
Related Requirement ID
```

### 1.6.2 — PUT và PATCH

Chốt nguyên tắc:

```text
POST   → Tạo resource
GET    → Đọc resource
PUT    → Thay thế toàn bộ resource
PATCH  → Cập nhật một phần resource
DELETE → Xóa resource
```

Quy định:

- `PUT` dùng khi Client gửi đầy đủ trạng thái cần thay thế.
- `PATCH` dùng khi Client chỉ gửi các trường cần cập nhật.
- Không dùng `PUT` cho cập nhật từng trường nếu hợp đồng API quy định đó là partial update.
- Kiểm tra API hiện tại, đặc biệt Profile đang được gọi bằng `PUT` hay `PATCH`.
- Nếu phải thay đổi API cũ, ghi rõ phương án tương thích và các nơi cần cập nhật ở Phase 5.

Không tự ý đổi endpoint đang được Flutter sử dụng mà không ghi nhận ảnh hưởng.

### 1.6.3 — JSON Structure

Chốt cấu trúc request/response thống nhất.

Ví dụ response thành công:

```json
{
  "data": {
    "id": "uuid",
    "name": "Example"
  }
}
```

Ví dụ response lỗi:

```json
{
  "timestamp": "2026-11-13T10:00:00Z",
  "status": 400,
  "code": "VALIDATION_ERROR",
  "message": "Request validation failed",
  "path": "/api/example",
  "fieldErrors": [
    {
      "field": "name",
      "message": "Name is required"
    }
  ]
}
```

Đây là cấu trúc đề xuất; phải ghi thành chuẩn thống nhất và dùng xuyên suốt API Contract.

Không trả stack trace, database password hoặc thông tin nội bộ trong response production.

### 1.6.4 — HTTP Status Convention

Chốt tối thiểu:

| Status | Ý nghĩa | Sử dụng |
|---|---|---|
| 200 | OK | GET, PUT, PATCH hoặc thao tác thành công có response |
| 201 | Created | Tạo resource thành công |
| 204 | No Content | DELETE hoặc thao tác thành công không có response body |
| 400 | Bad Request | Request sai định dạng hoặc validation lỗi |
| 401 | Unauthorized | Chưa đăng nhập hoặc token không hợp lệ/hết hạn |
| 403 | Forbidden | Không có quyền thao tác resource |
| 404 | Not Found | Resource hoặc endpoint không tồn tại |
| 409 | Conflict | Trùng dữ liệu hoặc xung đột version |
| 415 | Unsupported Media Type | Content-Type không được hỗ trợ |
| 429 | Too Many Requests | Vượt giới hạn request |
| 500 | Internal Server Error | Lỗi hệ thống |
| 503 | Service Unavailable | Service phụ thuộc tạm thời không khả dụng |

Phân biệt rõ lỗi xác thực `401`, lỗi quyền sở hữu `403` và lỗi không tìm thấy `404`.

### 1.6.5 — API Groups

Đối chiếu Excel và source rồi lập danh sách API chính thức.

Các nhóm cần kiểm tra:

```text
AUTH
USER PROFILE
MUSIC CATALOG
SEARCH
ALBUM
ARTIST
GENRE
STREAMING
PLAYLIST
FAVORITES
HISTORY
BATCH SYNC
```

Danh sách endpoint cuối cùng phải xuất phát từ requirement và luồng Use Case. Không tự tạo endpoint không có nhu cầu nghiệp vụ.

### DONE

`docs/API_CONTRACT.md` phải có:

```text
1. API Conventions
2. Authentication Rules
3. Endpoint Inventory
4. Request / Response Schema
5. PUT / PATCH Rules
6. HTTP Status Convention
7. Error Response Schema
8. Pagination / Search / Filter Rules
9. UUID Rules
10. Batch Sync Contract
11. Ownership Rules
12. Requirement Mapping
```

---

## TASK 1.7 — CHỐT USER, AUTHENTICATION, UUID VÀ SYNC

### 🎯 Mục tiêu

Chốt các quy tắc dùng chung giữa Flutter và Backend, đặc biệt là tài khoản, định danh dữ liệu offline và đồng bộ.

### 1.7.1 — Single User Model, No Roles

Hệ thống chỉ sử dụng một loại tài khoản:

```text
User
```

Không triển khai:

```text
ADMIN
MODERATOR
CUSTOMER
VENDOR
ROLE_BASED_ACCESS_CONTROL
```

Mỗi tài khoản có một `userId` duy nhất.

Các dữ liệu cá nhân phải gắn với chủ sở hữu:

```text
userId
   |
   +-- Playlists
   +-- Favorites
   +-- History
   +-- Profile
```

Quy tắc:

- Không có trường role để phân quyền nghiệp vụ.
- User chỉ được truy cập dữ liệu thuộc tài khoản của mình.
- Backend lấy `userId` từ JWT đã xác thực.
- Không tin `userId` do Client tự gửi trong request body để quyết định quyền sở hữu.
- Mọi API thao tác dữ liệu cá nhân phải kiểm tra ownership.

### 1.7.2 — UUID Strategy

Chốt chuẩn UUID:

```text
UUID v4
```

Quy tắc đề xuất:

| Object | Nơi tạo ID | Quy tắc |
|---|---|---|
| User | Backend | Tạo khi đăng ký |
| Catalog Song | Backend | ID ổn định do Backend quản lý |
| Album | Backend | ID ổn định do Backend quản lý |
| Artist | Backend | ID ổn định do Backend quản lý |
| Genre | Backend | ID ổn định do Backend quản lý |
| Playlist | Client hoặc Backend theo contract | Phải hỗ trợ tạo offline nếu requirement yêu cầu |
| Favorite | Theo thiết kế khóa dữ liệu | Tránh tạo bản ghi trùng cho cùng User/Song |
| History Event | Client | ID duy nhất để chống gửi trùng |
| Sync Operation | Client | UUID riêng cho từng operation |

Đối với dữ liệu người dùng phải tạo khi offline, ưu tiên Client tạo UUID ngay từ đầu để giữ nguyên ID khi đồng bộ lên Backend.

Không dùng index của SQLite, tên bài hát hoặc timestamp làm ID thay thế UUID.

### 1.7.3 — Authentication Flow

Chốt luồng xác thực mục tiêu:

**Register**

```text
Flutter
   ↓
POST /api/auth/register
   ↓
Backend Validate
   ↓
Hash Password bằng BCrypt
   ↓
Create User
   ↓
Issue Access Token + Refresh Token
   ↓
Flutter Store Tokens Securely
```

**Login**

```text
Flutter
   ↓
POST /api/auth/login
   ↓
Backend Verify Credentials
   ↓
Issue Access Token + Refresh Token
   ↓
Flutter Store Session
```

**Authenticated API**

```text
Flutter
   ↓
Authorization: Bearer <accessToken>
   ↓
Spring Security
   ↓
Verify JWT
   ↓
Resolve User ID
   ↓
Check Resource Ownership
   ↓
Controller / Service
```

**Refresh**

```text
Access Token Expired
       ↓
Flutter Sends Refresh Token
       ↓
Backend Validate Refresh Token
       ↓
Rotate / Issue New Tokens
       ↓
Flutter Update Secure Storage
```

**Logout**

```text
Flutter
   ↓
POST /api/auth/logout
   ↓
Backend Revoke Refresh Session
   ↓
Flutter Clear Local Session
```

**Google Sign-In**

```text
Flutter Google Sign-In
       ↓
Google ID Token
       ↓
Backend Verify ID Token
       ↓
Find or Create User
       ↓
Backend Issues Its Own JWT
       ↓
Flutter Uses Backend JWT
```

Google ID Token không được sử dụng thay thế JWT của Backend để gọi các API nội bộ.

Chốt thêm:

- Access Token và Refresh Token có thời hạn riêng.
- Refresh Token phải có khả năng thu hồi.
- Có cơ chế xử lý Refresh Token bị sử dụng lại hoặc hết hạn.
- Password được hash bằng BCrypt.
- Không lưu password dạng plaintext.
- Token phải được lưu trong vùng lưu trữ an toàn của thiết bị.
- Guest không có tài khoản chỉ sử dụng dữ liệu local; không được đồng bộ dữ liệu cá nhân lên tài khoản khi chưa xác định luồng chuyển đổi dữ liệu.

### 1.7.4 — Batch Sync Contract

Chốt một cơ chế đồng bộ thống nhất giữa Flutter và Backend.

Luồng mục tiêu:

```text
Local User Action
       ↓
SQLite Transaction
       ↓
Update Local Data
       ↓
Create Pending Sync Operation
       ↓
Connectivity Available
       ↓
Send Batch to Backend
       ↓
Backend Validate & Process
       ↓
Return Result Per Operation
       ↓
Client Mark Acknowledged Operations
       ↓
Pull Remote Changes
       ↓
Update SQLite
```

Mỗi operation tối thiểu cần:

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

Quy định:

- Mỗi operation có UUID riêng.
- Operation đã gửi nhưng chưa nhận xác nhận không được tự xóa khỏi queue.
- Gửi lại operation không được tạo dữ liệu trùng.
- Backend phải xử lý idempotency bằng `operationId`.
- Batch có thể chứa operation thành công và thất bại; phải trả kết quả riêng cho từng operation.
- Client chỉ đánh dấu đồng bộ khi nhận được xác nhận tương ứng.
- Lỗi mạng phải giữ nguyên pending operation.
- Retry phải có giới hạn và backoff.
- Đồng bộ phải xác định được thứ tự các thao tác liên quan cùng một entity.
- Dữ liệu của hai tài khoản không được trộn lẫn.

Cấu trúc JSON đề xuất:

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

Response đề xuất:

```json
{
  "batchId": "uuid",
  "results": [
    {
      "operationId": "uuid",
      "status": "APPLIED",
      "serverVersion": 1,
      "serverUpdatedAt": "2026-11-13T10:00:01Z",
      "data": {
        "id": "uuid"
      },
      "error": null
    }
  ]
}
```

Các trạng thái kết quả cần được chốt:

```text
APPLIED
DUPLICATE
CONFLICT
REJECTED
```

Đây là schema mục tiêu. Phải hiệu chỉnh tên trường và action theo requirement thực tế trước khi ghi vào API Contract.

### 1.7.5 — Conflict Resolution

Không áp dụng một quy tắc ghi đè chung cho mọi loại dữ liệu.

Phải chốt ma trận:

| Data | Conflict Rule đề xuất |
|---|---|
| User Profile | Kiểm tra version; trả conflict khi có cập nhật đồng thời |
| Playlist Metadata | Dùng version hoặc baseVersion để phát hiện xung đột |
| Playlist Songs | Xử lý add/remove theo operation có tính idempotent |
| Favorites | Dùng khóa User + Song và quy tắc xử lý trạng thái add/remove nhất quán |
| History | Append-only; dùng eventId để chống ghi trùng |
| Catalog | Backend là nguồn dữ liệu chính |
| Downloaded Audio | File local; không đồng bộ binary audio qua batch metadata |

Quy định thêm:

- Không sử dụng `last-write-wins` cho toàn bộ hệ thống một cách mặc định.
- Không tin tuyệt đối đồng hồ thiết bị để xác định bản ghi mới nhất.
- Xóa dữ liệu cần có tombstone hoặc cơ chế tương đương cho đến khi server xác nhận.
- Mỗi conflict phải có kết quả rõ ràng để Client biết xử lý tiếp.
- Những trường hợp chưa đủ thông tin phải ghi thành quyết định mở, không tự đoán.

### DONE

Có tài liệu xác định:

```text
User Model
Ownership Rules
Authentication Flow
JWT Lifecycle
UUID Strategy
Batch Sync Schema
Idempotency
Retry Policy
Conflict Resolution Matrix
Local / Cloud Data Ownership
```

---

## TASK 1.8 — CHỐT ARCHITECTURE VÀ IMPLEMENTATION ROADMAP

### 🎯 Mục tiêu

Kết hợp kết quả audit thành một kiến trúc thống nhất và phân chia chính xác công việc cho Phase 2–8.

### Cách làm

Tạo sơ đồ tổng thể:

```text
                    FLUTTER
                       |
        +--------------+--------------+
        |              |              |
      Auth          Library          Player
        |              |              |
        +--------------+--------------+
                       |
                Repository Layer
                       |
          +------------+------------+
          |                         |
       SQLite                 REST API Client
          |                         |
     Pending Sync             Spring Boot
     Local Metadata                |
          |                +-------+-------+
          |                |               |
     Local File         Auth / User     Music APIs
          |                |               |
     Audio Files           +-------+-------+
                                  |
                              PostgreSQL
                                  |
                             Media Storage
```

Kiến trúc phải thể hiện rõ:

- Flutter là Client.
- Spring Boot là Backend API mục tiêu.
- PostgreSQL là cloud relational database.
- SQLite là local database.
- Local File Storage lưu audio download.
- API Client chịu trách nhiệm giao tiếp Backend.
- Repository quản lý local và remote data.
- Sync Service quản lý pending operation và đồng bộ.
- JWT chịu trách nhiệm xác thực request.
- Backend chịu trách nhiệm kiểm tra quyền sở hữu dữ liệu.

Chốt quan hệ phụ thuộc giữa các nhóm Phase:

```text
PHASE 1 — Architecture & API Contract
              |
       +------+------+
       |             |
PHASE 2          PHASE 5
Backend Core     Flutter Auth Foundation
       |
PHASE 3
Authentication
       |
PHASE 4
Music Data API
       |
       +-------------+
                     |
              PHASE 5 Integration
                     |
             +-------+-------+
             |               |
          PHASE 6         PHASE 7
        Player/Download   Offline/Sync
             |               |
             +-------+-------+
                     |
                  PHASE 8
                E2E Testing
```

Đây là quan hệ phụ thuộc logic. Những phần audit, viết test case hoặc chuẩn bị khung độc lập có thể thực hiện song song, nhưng không được tích hợp theo một API contract chưa chốt.

Tạo:

```text
docs/IMPLEMENTATION_ROADMAP.md
```

Phải ghi rõ:

| Phase | Requirement IDs | Main Scope | Dependencies | Acceptance Criteria |
|---|---|---|---|---|
| Phase 2 | H02–H04 | Spring Boot, PostgreSQL Core | Phase 1 | Backend và database hoạt động |
| Phase 3 | H05–H09 | JWT, Auth, Profile, Google, Validation | Phase 2 | Auth API hoạt động |
| Phase 4 | AQ01–AQ09 | Music Data API, Batch Sync | Phase 2–3 | Music APIs và Sync API sẵn sàng |
| Phase 5 | MQ01–MQ11 | Flutter Auth và API Integration | Phase 1, 3, 4 | Flutter gọi Backend đúng contract |
| Phase 6 | AT01–AT11 | Player và Download | Audit Phase 1, các thành phần Flutter hiện có | Player và Download đạt yêu cầu |
| Phase 7 | QA01–QA10 | Offline-first và Synchronization | Phase 4, 5 | Sync và restore đúng |
| Phase 8 | H10 và tiêu chí nghiệm thu liên quan | E2E Testing | Phase 2–7 | Hệ thống được kiểm thử tổng thể |

Nếu requirement thuộc nhiều phase, phải ghi rõ phần nào thực hiện ở phase nào để không trùng công việc.

---

# 5. DELIVERABLES — ĐẦU RA BẮT BUỘC

## TASK 1.9 — GHI TÀI LIỆU PHASE 1

### 🎯 Mục tiêu

Tạo bộ tài liệu chính thức làm căn cứ triển khai các phase sau.

### File 1 — Architecture Audit Report

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
```

Nội dung:

```markdown
# PHASE 1 — ARCHITECTURE AUDIT REPORT

## 1. Project Overview
## 2. Source & Documentation Inventory
## 3. Excel Requirement Audit
## 4. Flutter Source Audit
## 5. Backend & Database Audit
## 6. Requirement Traceability Matrix
## 7. Architecture Conflicts
## 8. Data Storage Architecture
## 9. Authentication Architecture
## 10. UUID & Synchronization Architecture
## 11. Architecture Decisions
## 12. Unresolved Dependencies
## 13. Risks & Recommendations
## 14. Phase 1 Conclusion
```

## File 2 — API Contract

```text
docs/API_CONTRACT.md
```

Nội dung:

```markdown
# WAVEBOX API CONTRACT

## 1. API Standards
## 2. Authentication
## 3. User Profile
## 4. Music Catalog
## 5. Search & Filter
## 6. Album / Artist / Genre
## 7. Streaming
## 8. Playlist
## 9. Favorites
## 10. History
## 11. Batch Synchronization
## 12. UUID Rules
## 13. Request / Response Structures
## 14. HTTP Status Codes
## 15. Error Handling
## 16. Validation
## 17. Ownership Rules
## 18. Requirement Mapping
```

Mỗi endpoint phải có request, response và status cụ thể. Không để các endpoint mới dừng ở mức tên gọi.

## File 3 — Architecture Decision Log

```text
docs/architecture/DECISION_LOG.md
```

Nội dung:

```markdown
# ARCHITECTURE DECISION LOG

## ADR-001 — Backend Architecture
## ADR-002 — Cloud Database
## ADR-003 — Local Database
## ADR-004 — Data Storage Ownership
## ADR-005 — Authentication & JWT
## ADR-006 — User Model Without Roles
## ADR-007 — UUID Strategy
## ADR-008 — PUT & PATCH Convention
## ADR-009 — Batch Sync
## ADR-010 — Conflict Resolution
## ADR-011 — Firebase vs REST API
## ADR-012 — Audio & Download Storage
```

Mỗi quyết định ghi:

```text
Decision ID
Context
Options Considered
Chosen Option
Reason
Impact
Status
```

Status:

```text
DECIDED
PROPOSED
OPEN
BLOCKED
SUPERSEDED
```

Không đánh dấu `DECIDED` nếu vẫn còn mâu thuẫn chưa giải quyết.

## File 4 — Implementation Roadmap

```text
docs/IMPLEMENTATION_ROADMAP.md
```

Nội dung:

```markdown
# WAVEBOX IMPLEMENTATION ROADMAP

## Phase 2 — Backend Core & PostgreSQL
## Phase 3 — Authentication & Security
## Phase 4 — Backend Music Data
## Phase 5 — Flutter Authentication & API Integration
## Phase 6 — Flutter Player & Download
## Phase 7 — Offline-first & Synchronization
## Phase 8 — E2E & Acceptance
```

Mỗi Phase chỉ ghi:

```text
Objective
Requirement IDs
Scope
Dependencies
Deliverables
Acceptance Criteria
```

Không lặp lại nội dung thiết kế API, JWT hoặc Sync đã được mô tả đầy đủ trong `API_CONTRACT.md`.

---

# 6. PHASE 1 FINAL REVIEW

## 🎯 Mục tiêu

Kiểm tra toàn bộ đầu ra trước khi kết thúc Phase 1.

### DONE Checklist

```text
[ ] Đã tìm và đọc toàn bộ Excel Requirements
[ ] Đã đọc các sheet và đối chiếu đủ 51 requirement
[ ] Đã đọc tài liệu Use Case liên quan
[ ] Đã đối chiếu 44 Use Case chi tiết
[ ] Đã audit Flutter Source Code
[ ] Đã audit Backend Source Code nếu có
[ ] Đã audit SQLite và PostgreSQL nếu có
[ ] Đã kiểm tra API hiện tại
[ ] Đã xác định các chức năng đã có và còn thiếu
[ ] Đã lập Requirement Traceability Matrix
[ ] Đã xác định mâu thuẫn REST API và Firebase
[ ] Đã chốt kiến trúc lưu trữ Local / Cloud
[ ] Đã chốt mô hình User duy nhất, không có roles
[ ] Đã chốt Authentication Flow
[ ] Đã chốt UUID Strategy
[ ] Đã chốt PUT / PATCH Convention
[ ] Đã chốt Batch Sync Contract
[ ] Đã chốt Conflict Resolution
[ ] Đã hoàn thiện docs/API_CONTRACT.md
[ ] Đã hoàn thiện docs/architecture/DECISION_LOG.md
[ ] Đã hoàn thiện docs/IMPLEMENTATION_ROADMAP.md
[ ] Đã hoàn thiện docs/REPORT/PHASE-1-ARCHITECTURE.md
[ ] Đã kiểm tra tính thống nhất giữa các tài liệu
[ ] Đã kiểm tra git status sau khi hoàn tất
[ ] Không có thay đổi source code hoặc database
```

---

# 7. ĐIỀU KIỆN PHASE 1 DONE

Chỉ được đánh dấu hoàn thành khi đáp ứng tất cả điều kiện sau:

**1. Requirement**

```text
51 / 51 requirements đã được đối chiếu
```

Requirement thiếu dữ liệu phải có ghi chú và trạng thái cụ thể, không được tự điền.

**2. Architecture**

```text
Flutter Architecture: DECIDED
Backend Architecture: DECIDED
Database Architecture: DECIDED
Storage Ownership: DECIDED
Authentication Flow: DECIDED
User Model: DECIDED
UUID Strategy: DECIDED
Sync Strategy: DECIDED
Conflict Resolution: DECIDED
```

**3. API Contract**

```text
PUT / PATCH: DECIDED
JSON Structure: DECIDED
HTTP Status: DECIDED
Error Schema: DECIDED
Authentication Rules: DECIDED
Batch Sync: DECIDED
Ownership Rules: DECIDED
```

**4. Deliverables**

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/IMPLEMENTATION_ROADMAP.md
```

Tất cả file phải tồn tại, có nội dung thực tế và thống nhất với nhau.

Nếu thiếu Excel, thiếu source hoặc có quyết định chưa thể xác nhận, phải ghi `BLOCKED` hoặc `OPEN`, nêu rõ lý do và điều kiện cần thiết. Không được tuyên bố đã hoàn thành 100% khi chưa đủ bằng chứng.

---

# 8. STOP RULE

Sau khi hoàn thành Phase 1:

**DỪNG.**

Không tự chuyển sang viết code Phase 2.

Không tự tạo Entity, DTO, Repository, Controller, Migration hoặc cấu hình JWT.

Chỉ khi tài liệu đã hoàn chỉnh và được xác nhận bằng:

```text
PHASE 1 DONE
```

mới bắt đầu:

```text
PHASE 2 — BACKEND CORE & POSTGRESQL
```

---

# 9. TỔNG KẾT CẤU TRÚC PHASE 1

```text
PHASE 1 — PHÂN TÍCH, AUDIT VÀ CHỐT KIẾN TRÚC
│
├── TASK 1.1
│   └── Audit Excel Requirements
│
├── TASK 1.2
│   └── Audit Flutter Source Code
│
├── TASK 1.3
│   └── Audit Backend, API & Database
│
├── TASK 1.4
│   └── Requirement Mapping & Conflict Analysis
│
├── TASK 1.5
│   └── Chốt Data Storage Architecture
│
├── TASK 1.6
│   └── Chốt API Contract
│
├── TASK 1.7
│   └── Chốt User, Authentication, UUID & Sync
│
├── TASK 1.8
│   └── Chốt Architecture & Implementation Roadmap
│
├── TASK 1.9
│   └── Tạo bộ tài liệu Phase 1
│
└── TASK 1.10
    └── Final Review & Stop
```

---

# 10. THỨ TỰ THỰC THI

```text
READ EXCEL
    ↓
READ DOCUMENTATION & USE CASES
    ↓
AUDIT FLUTTER SOURCE
    ↓
AUDIT BACKEND & DATABASE
    ↓
MAP 51 REQUIREMENTS
    ↓
IDENTIFY CONFLICTS
    ↓
DECIDE STORAGE ARCHITECTURE
    ↓
DECIDE AUTHENTICATION & USER MODEL
    ↓
DECIDE UUID & SYNC
    ↓
WRITE API_CONTRACT.md
    ↓
WRITE DECISION_LOG.md
    ↓
WRITE IMPLEMENTATION_ROADMAP.md
    ↓
WRITE PHASE-1-ARCHITECTURE.md
    ↓
FINAL REVIEW
    ↓
PHASE 1 DONE
    ↓
STOP
```

---

## NGUYÊN TẮC QUAN TRỌNG NHẤT

Phase 1 không phải là giai đoạn viết code.

Phase 1 là giai đoạn xác định **dự án hiện có gì, yêu cầu thực tế là gì, phần nào còn thiếu và hệ thống sẽ được xây dựng theo kiến trúc nào**.

Không được để Phase 2–8 tự quyết định lại các vấn đề đã chốt ở Phase 1.

**Một API Contract thống nhất, một mô hình User, một nguồn dữ liệu cloud chính và một cơ chế đồng bộ được xác định rõ ràng là nền tảng để toàn bộ WaveBox hoạt động nhất quán.**