# PHASE 5 — FLUTTER AUTHENTICATION & API INTEGRATION

## 🎯 Mục tiêu Phase 5

Tích hợp ứng dụng Flutter WaveBox với Spring Boot Backend đã hoàn thành ở Phase 2–4, tập trung vào Authentication, quản lý phiên đăng nhập, API Client và các màn hình khai thác dữ liệu âm nhạc trực tuyến.

Phase 5 phải giữ nguyên các chức năng hiện có của ứng dụng, đặc biệt là thư viện nhạc local, Player, Playlist, Favorites, History và SQLite.

Luồng thực hiện:

```text
PHASE 1 — ARCHITECTURE & API CONTRACT
                  ↓
PHASE 2 — BACKEND CORE
                  ↓
PHASE 3 — AUTHENTICATION & SECURITY
                  ↓
PHASE 4 — MUSIC DATA API
                  ↓
AUDIT EXISTING FLUTTER SOURCE
                  ↓
IMPLEMENT API CLIENT
                  ↓
IMPLEMENT SESSION RESTORE
                  ↓
IMPLEMENT LOGIN / REGISTER
                  ↓
IMPLEMENT PROFILE
                  ↓
IMPLEMENT LOGOUT / GUEST / ACCOUNT ENTRY
                  ↓
IMPLEMENT GOOGLE SIGN-IN
                  ↓
IMPLEMENT LOCAL / ONLINE SEARCH
                  ↓
IMPLEMENT ALBUM / ARTIST / GENRE SCREENS
                  ↓
FLUTTER TESTS & API INTEGRATION TESTS
                  ↓
PHASE 5 DONE
```

**Phạm vi requirement:**

```text
MQ01 — Restore Login Session
MQ02 — ApiClient / Timeout / Refresh / PATCH / Batch
MQ03 — LoginScreen & Validation
MQ04 — RegisterScreen
MQ05 — ProfileScreen
MQ06 — Logout / Guest / Session Restore
MQ07 — Google Sign-In
MQ08 — AccountEntry
MQ09 — Authentication Tests
MQ10 — Local / Online Search
MQ11 — Album / Artist / Genre Screens
```

Đầu ra Phase 5 là ứng dụng Flutter có thể đăng nhập, đăng ký, khôi phục phiên, cập nhật hồ sơ, đăng xuất, tiếp tục sử dụng chế độ Guest và khai thác dữ liệu âm nhạc trực tuyến qua Backend thực tế.

Phase 5 **được phép tạo và sửa source code Flutter**, nhưng không viết lại Backend, không triển khai lại Authentication API và không thay đổi database schema Backend nếu không có yêu cầu được phê duyệt.

---

## 1. NGUYÊN TẮC TRIỂN KHAI

### 1.1 — Previous Phases Source of Truth Rule

Trước khi code, đọc:

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/IMPLEMENTATION_ROADMAP.md
docs/REPORT/PHASE-3-AUTH-SECURITY.md
docs/REPORT/PHASE-4-MUSIC-DATA.md
```

Kiểm tra các API đã được Backend triển khai:

```text
Register
Login
Refresh
Logout
Google Sign-In
Get Profile
Update Profile
Change Password (nếu có UI yêu cầu)

Music Catalog
Search
Album
Artist
Genre
```

Mọi request/response, HTTP method, endpoint, error code và authentication rule phải tuân theo `docs/API_CONTRACT.md`.

Không tự đổi `PUT` thành `PATCH`, không tự đổi JSON field và không tự thêm endpoint khi Backend chưa hỗ trợ.

### 1.2 — Existing Flutter Source First

Trước khi sửa code, kiểm tra source Flutter thực tế.

Ưu tiên rà soát:

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
│   │       ├── auth_viewmodel.dart
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
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

Đây là các đường dẫn đã được ghi nhận trong quá trình khảo sát trước đó. Phải kiểm tra source hiện tại để xác nhận đường dẫn, class và method thực tế.

Đặc biệt kiểm tra:

```text
ApiClient
ConnectivityService
AuthRepository
AuthViewModel
LoginScreen
RegisterScreen
SongRepository
SyncService
AppDatabase
main.dart
SharedPreferences
Secure Storage (nếu có)
```

Trong lần khảo sát source trước đây, đã ghi nhận:

- `ApiClient` sử dụng REST API, Bearer JWT và có base URL dạng `10.0.2.2:8080`.
- `AuthRepository` đã từng gọi Register, Login, Google và Profile.
- Profile từng sử dụng `PUT`.
- Token và profile từng được lưu bằng SharedPreferences.
- `SyncService` có pending queue và cơ chế retry riêng.
- `SongRepository` kết hợp local và remote data.

Đây là thông tin từ lần khảo sát trước, không được mặc định source hiện tại vẫn giữ nguyên. Phải kiểm tra lại trước khi thay đổi.

Phân loại từng thành phần:

```text
[EXISTING]
[IMPLEMENTED]
[PARTIAL]
[MISSING]
[BUG]
[DEPENDENCY]
[CONFLICT]
[OUT OF SCOPE]
```

### 1.3 — API Contract First Rule

Flutter chỉ giao tiếp với Backend thông qua API đã được xác định.

Mọi endpoint phải sử dụng đúng:

```text
HTTP Method
Endpoint
Request Body
Response Body
Authentication
HTTP Status
Error Code
Pagination
```

Không hardcode endpoint rải rác trong các Widget hoặc Screen.

Các màn hình phải gọi Repository hoặc ViewModel tương ứng.

Kiến trúc mục tiêu:

```text
Flutter UI
    ↓
ViewModel / State Management
    ↓
Repository
    ↓
ApiClient
    ↓
Spring Boot REST API
    ↓
PostgreSQL
```

Không để Widget trực tiếp xử lý JWT, refresh token hoặc database request.

### 1.4 — Secure Token Storage Rule

Access Token và Refresh Token phải được lưu bằng cơ chế lưu trữ bảo mật của hệ điều hành, ví dụ:

```text
flutter_secure_storage
```

Hoặc giải pháp secure storage tương đương đã được dự án lựa chọn.

Không lưu token dạng plaintext trong SharedPreferences.

Quy tắc:

```text
Access Token:
- Secure Storage
- Dùng Authorization Bearer

Refresh Token:
- Secure Storage
- Chỉ dùng gọi Refresh API

Password:
- Không lưu lại sau đăng nhập

Google ID Token:
- Chỉ sử dụng trong luồng xác thực Google
```

Nếu source hiện tại đang lưu token trong SharedPreferences:

- Kiểm tra cấu trúc key cũ.
- Thiết kế chuyển token sang secure storage.
- Chỉ xóa key token cũ sau khi ghi secure storage thành công và đã xác minh dữ liệu.
- Không xóa các preference khác.
- Không xóa local music library hoặc dữ liệu người dùng.

Không log token hoặc password trong Debug Console.

### 1.5 — Single User Model, No Roles

Ứng dụng chỉ sử dụng một loại tài khoản:

```text
User
```

Không triển khai phân biệt:

```text
ADMIN
MODERATOR
CUSTOMER
VENDOR
```

Authentication State chỉ cần quản lý các trạng thái phù hợp:

```text
RESTORING
AUTHENTICATED
GUEST
UNAUTHENTICATED
```

Không dùng role để quyết định điều hướng hoặc hiển thị giao diện.

Các quyền truy cập dữ liệu cá nhân phải do Backend kiểm tra dựa trên JWT.

Không tự truyền User ID từ Client để thay thế thông tin User đã xác thực.

### 1.6 — Preserve Existing Features Rule

Trong Phase 5, bắt buộc giữ nguyên các chức năng Flutter đã hoạt động.

```text
✅ Giữ local music library
✅ Giữ SQLite database
✅ Giữ SongRepository đang hoạt động
✅ Giữ Player
✅ Giữ Playlist local
✅ Giữ Favorites local
✅ Giữ History local
✅ Giữ Download và file audio
✅ Giữ background audio
✅ Giữ navigation hiện có
✅ Mở rộng API theo kiến trúc hiện tại
```

Không được:

```text
❌ Xóa màn hình hoặc Widget hiện có
❌ Xóa tính năng Player
❌ Xóa audio_handler.dart khi chưa xác minh dependency
❌ Xóa database hoặc bảng SQLite
❌ Reset local data để tích hợp Backend
❌ Thay toàn bộ state management không cần thiết
❌ Rewrite toàn bộ ApiClient nếu chỉ cần mở rộng
❌ Thay Repository đang hoạt động bằng code mới không tương thích
❌ Làm hỏng Guest Mode
❌ Tự đồng bộ toàn bộ dữ liệu local lên tài khoản
```

Việc đồng bộ dữ liệu Local ↔ Cloud thực tế thuộc Phase 7.

### 1.7 — Environment Configuration Rule

Không hardcode API URL trong nhiều file.

Cấu hình theo môi trường:

```text
Development
Testing
Production
```

Ví dụ:

```text
API_BASE_URL
```

Với Android Emulator:

```text
http://10.0.2.2:8080
```

Đây chỉ là địa chỉ development tham khảo khi Backend chạy trên máy host.

Không sử dụng `localhost` một cách mặc định khi Flutter chạy trên thiết bị hoặc Emulator khác môi trường.

Với thiết bị Android thực tế, phải sử dụng địa chỉ mạng phù hợp hoặc domain Backend.

Production phải sử dụng HTTPS.

Không đưa API Secret, password hoặc credentials vào source Flutter.

### 1.8 — Safe Modification Rule

Được phép tạo và sửa code Flutter trong phạm vi MQ01–MQ11.

```text
✅ Sửa ApiClient
✅ Sửa AuthRepository
✅ Sửa AuthViewModel
✅ Tạo Secure Token Storage
✅ Sửa LoginScreen
✅ Sửa RegisterScreen
✅ Tạo / hoàn thiện ProfileScreen
✅ Hoàn thiện AccountEntry
✅ Tích hợp Google Sign-In
✅ Tích hợp Search API
✅ Tạo Album / Artist / Genre Screens
✅ Viết tests
```

Không được:

```text
❌ Xóa file hoặc thư mục
❌ Xóa class, method hoặc feature
❌ Viết lại Backend
❌ Thay đổi PostgreSQL schema
❌ Thay đổi JWT Contract
❌ Sửa logic Player và Download ngoài phạm vi
❌ Triển khai toàn bộ Offline Sync của Phase 7
❌ Tạo thêm Firebase Sync song song khi chưa được quyết định
❌ Commit / push khi chưa được yêu cầu
```

---

## 2. ĐIỀU KIỆN BẮT ĐẦU

Phase 5 được phép bắt đầu khi:

```text
PHASE 1 — API CONTRACT DONE
             +
PHASE 3 — AUTHENTICATION API DONE
             +
Flutter Source Code sẵn sàng
             +
Auth API đã được kiểm thử
             +
Secure Storage có thể sử dụng
```

Để hoàn thành đầy đủ MQ10–MQ11, cần thêm:

```text
PHASE 4 — MUSIC DATA API DONE
             +
Catalog API hoạt động
             +
Search API hoạt động
             +
Album / Artist / Genre API hoạt động
```

Có thể triển khai MQ01–MQ09 trước khi Phase 4 hoàn tất, nhưng không được đánh dấu toàn bộ Phase 5 DONE khi các API Catalog cần thiết chưa sẵn sàng.

### Kiểm tra môi trường

```bash
flutter --version
```

```bash
flutter doctor
```

```bash
flutter pub get
```

Kiểm tra Android Emulator hoặc thiết bị thực tế.

Kiểm tra Backend:

```text
GET /actuator/health
```

Kiểm tra Git:

```bash
git status --short
```

Nếu thiếu OAuth Client ID:

```text
[DEPENDENCY — GOOGLE OAUTH CONFIGURATION]
```

Có thể triển khai giao diện và logic gọi Google Sign-In trước, nhưng không được ghi Google Sign-In thực tế PASS nếu chưa có cấu hình hợp lệ.

---

## 3. PHẠM VI PHASE 5

### CHỈ LÀM

```text
MQ01 — Restore Login Session
MQ02 — ApiClient / Timeout / Refresh / PATCH / Batch
MQ03 — LoginScreen & Validation
MQ04 — RegisterScreen
MQ05 — ProfileScreen
MQ06 — Logout / Guest / Session Restore
MQ07 — Google Sign-In
MQ08 — AccountEntry
MQ09 — Authentication Tests
MQ10 — Local / Online Search
MQ11 — Album / Artist / Genre Screens
```

### KHÔNG ĐƯỢC LÀM

```text
Backend JWT Implementation
Backend Register / Login
Backend Google Token Verification
Backend Music Catalog
Backend Search API
PostgreSQL Schema Changes
Full Offline Queue Implementation
Full Batch Sync Integration
Player Rewrite
Background Audio Rewrite
Download Service Rewrite
Sleep Timer
Notification / MediaSession Changes
SQLite Full Refactor
Full E2E System Acceptance
```

Các chức năng Background Audio, Download, Offline Sync và E2E thuộc Phase 6–8.

---

# 4. CÁC TASK THỰC HIỆN

## TASK 5.1 — AUDIT FLUTTER AUTHENTICATION & API SOURCE

### 🎯 Mục tiêu

Xác định chính xác code Flutter hiện có trước khi tích hợp Backend, tránh tạo class trùng hoặc làm hỏng các chức năng đang hoạt động.

### Cách làm

Đọc toàn bộ thành phần:

```text
ApiClient
AuthRepository
AuthViewModel
LoginScreen
RegisterScreen
ProfileScreen (nếu có)
SongRepository
ConnectivityService
AppDatabase
main.dart
```

Ghi nhận:

```text
File Path
Class / Method
Current Responsibility
Current API Endpoint
Current HTTP Method
Request / Response Format
Token Storage
Authentication State
Navigation Flow
Missing Requirement
Potential Conflict
```

Đặc biệt kiểm tra:

**Authentication**

- Login đang gọi Backend hay chỉ xử lý local?
- Register đang hoạt động không?
- Google Sign-In đã có chưa?
- Token được lưu ở đâu?
- Có tự refresh token không?
- Logout có gọi Backend không?
- Guest Mode hoạt động thế nào?

**API Client**

- Base URL hiện tại.
- HTTP library đang dùng.
- Timeout.
- Interceptors.
- Authorization Header.
- Error Handling.
- PATCH support.
- Batch request support.

**Local Data**

- SQLite đang lưu các bảng nào?
- SongRepository kết hợp local và remote ra sao?
- Đăng xuất có làm mất local music không?
- Có dữ liệu nào đang phụ thuộc Auth State không?

### DONE

Có bảng:

| Component | Existing State | Current Behavior | Required Action |
|---|---|---|---|
| ApiClient | EXISTING / PARTIAL | Theo source | MQ02 |
| AuthRepository | EXISTING / PARTIAL | Theo source | MQ01–MQ08 |
| AuthViewModel | EXISTING / PARTIAL | Theo source | MQ01–MQ06 |
| LoginScreen | EXISTING / PARTIAL | Theo source | MQ03 |
| RegisterScreen | EXISTING / PARTIAL | Theo source | MQ04 |
| SongRepository | EXISTING / PARTIAL | Local / Remote | MQ10–MQ11 |
| AppDatabase | EXISTING | SQLite | Preserve |
| SyncService | EXISTING / PARTIAL | Theo source | Chưa triển khai lại, thuộc Phase 7 |

Không xóa code chỉ vì chức năng đã được triển khai một phần.

---

## TASK 5.2 — API CLIENT & NETWORK INTEGRATION (MQ02)

### 🎯 Mục tiêu

Chuẩn hóa một API Client dùng chung để Flutter giao tiếp với Spring Boot Backend.

### 5.2.1 — API Base Configuration

Sử dụng một cấu hình Base URL tập trung.

Ví dụ:

```text
lib/core/network/
    ├── api_client.dart
    ├── api_config.dart
    ├── api_exception.dart
    ├── auth_interceptor.dart
    └── ...
```

Không bắt buộc tạo tất cả file nếu project đã có cấu trúc phù hợp.

Yêu cầu:

- Base URL lấy từ environment configuration.
- Không hardcode URL trong từng screen.
- Hỗ trợ Development / Testing / Production.
- Có cấu hình HTTPS cho production.
- Không làm thay đổi endpoint đã chốt.

### 5.2.2 — HTTP Methods

ApiClient phải hỗ trợ:

```text
GET
POST
PUT
PATCH
DELETE
```

Các method phải nhận được:

```text
Path
Query Parameters
Request Body
Headers
Authentication Policy
Timeout
```

Chính xác phương thức HTTP phải tuân thủ API Contract.

Không tự thay PUT thành PATCH.

### 5.2.3 — Timeout

Cấu hình:

```text
Connect Timeout
Receive Timeout
Send Timeout
```

Timeout phải cấu hình được và phù hợp từng loại request.

Không dùng một timeout quá dài cho toàn bộ API.

Không xem Timeout là lỗi Authentication.

Không tự logout chỉ vì mất kết nối hoặc Backend không phản hồi.

### 5.2.4 — Authorization Header

Với API yêu cầu đăng nhập:

```http
Authorization: Bearer <accessToken>
```

ApiClient tự lấy Access Token từ Secure Storage.

Không yêu cầu từng màn hình tự đọc và tự gắn token.

Với API công khai, không được ép gửi token nếu contract không yêu cầu.

### 5.2.5 — Automatic Refresh Token

Đây là phần quan trọng nhất của MQ02.

Luồng:

```text
Flutter API Request
       ↓
Attach Access Token
       ↓
Send Backend Request
       ↓
Receive Response
       ↓
Is Token Expired?
       |
    +--+--+
    |     |
    NO    YES
    |     |
Return  Refresh API
Result     ↓
        New Token Pair
             ↓
        Save Securely
             ↓
        Retry Original Request Once
             ↓
          Return Result
```

Quy tắc:

- Chỉ xử lý refresh khi Backend trả lỗi xác thực đúng trường hợp theo API Contract.
- Không refresh khi gặp `403`, lỗi validation hoặc lỗi nghiệp vụ.
- Không refresh request Refresh Token.
- Không tạo vòng lặp refresh.
- Sau khi refresh thành công, cập nhật cả token pair theo contract.
- Request ban đầu chỉ được retry một lần.
- Khi Refresh Token hết hạn hoặc bị thu hồi, chuyển Authentication State về `UNAUTHENTICATED`.
- Không retry vô hạn.

**Concurrent Refresh Handling**

Khi nhiều API cùng gặp Access Token hết hạn:

```text
Request A ----+
Request B ----+----> One Refresh Operation
Request C ----+              |
                              ↓
                       New Token Pair
                              |
                 +------------+------------+
                 |            |            |
              Request A    Request B    Request C
                 Retry        Retry        Retry
```

Chỉ thực hiện một refresh operation đồng thời. Các request khác chờ kết quả để tránh Refresh Token Rotation bị gọi nhiều lần.

Không retry request có khả năng tạo side effect nếu chưa bảo đảm request có thể gửi lại an toàn. Với các thao tác batch hoặc POST không idempotent, phải dùng `operationId` hoặc cơ chế idempotency đã quy định trong contract.

### 5.2.6 — Error Handling

Chuẩn hóa:

```text
400 — Validation Error
401 — Unauthorized
403 — Forbidden
404 — Not Found
409 — Conflict
429 — Too Many Requests
500 — Internal Server Error
503 — Service Unavailable
Timeout
No Internet
Connection Error
Invalid JSON
```

Tạo hoặc mở rộng lỗi ứng dụng:

```text
ApiException
AuthenticationException
ValidationException
NetworkException
TimeoutException
ServerException
```

Không nhất thiết phải tách class cho mọi lỗi nếu dự án đã có cơ chế phù hợp.

UI chỉ nhận lỗi đã được chuyển đổi sang dạng dễ xử lý.

Không hiển thị stack trace hoặc thông tin kỹ thuật nội bộ cho người dùng.

### 5.2.7 — Batch Request Support

ApiClient phải có khả năng gửi request Batch theo API Contract.

Ví dụ:

```text
POST /api/sync/batch
```

Chỉ là endpoint minh họa; sử dụng endpoint thực tế đã được chốt.

Yêu cầu:

- Gửi JSON batch đúng schema.
- Nhận kết quả theo từng operation.
- Parse trạng thái `APPLIED`, `DUPLICATE`, `CONFLICT`, `REJECTED`.
- Trả kết quả rõ ràng cho Repository/Service sử dụng.
- Có thể dùng `operationId` để bảo đảm idempotency.

**Phạm vi giới hạn:** MQ02 chỉ chuẩn bị năng lực giao tiếp Batch của ApiClient. Không triển khai pending queue, retry đồng bộ offline, pull/restore hay tự động trigger sync. Những phần đó thuộc Phase 7.

### DONE

```text
[ ] Base URL được cấu hình tập trung
[ ] GET / POST / PUT / PATCH / DELETE hoạt động
[ ] Timeout hoạt động
[ ] Authorization Header tự động
[ ] Secure Token Storage được tích hợp
[ ] Automatic Refresh hoạt động
[ ] Concurrent Refresh được xử lý
[ ] Request chỉ retry một lần
[ ] Không refresh khi gặp lỗi ngoài authentication
[ ] Error Mapping hoạt động
[ ] Batch Request được hỗ trợ
[ ] Không hardcode endpoint trong Widget
```

---

## TASK 5.3 — RESTORE LOGIN SESSION (MQ01)

### 🎯 Mục tiêu

Khôi phục phiên đăng nhập khi người dùng mở lại ứng dụng, không bắt buộc đăng nhập lại nếu Refresh Token còn hợp lệ.

### Cách làm

#### 1. Authentication State

Xây dựng hoặc mở rộng state hiện tại:

```text
RESTORING
AUTHENTICATED
GUEST
UNAUTHENTICATED
```

Không tạo state trùng lặp nếu ViewModel đã có cơ chế tương ứng.

#### 2. App Startup

Luồng:

```text
Open WaveBox
      ↓
Initialize Dependencies
      ↓
Read Secure Storage
      ↓
Access Token Exists?
      |
   +--+--+
   |     |
  YES    NO
   |     |
Check   Check Guest
Token   State / Default
   |     |
   ↓     ↓
Valid?  GUEST or UNAUTHENTICATED
   |
+--+---+
|      |
YES    NO
|      |
Restore Refresh Token
Authenticated
       |
       ↓
   Refresh Result
       |
    +--+--+
    |     |
   PASS  FAIL
    |     |
Update  Clear Invalid
Tokens  Auth Tokens
    |     |
Authenticated  UNAUTHENTICATED
```

Thực tế có thể sử dụng Access Token còn hạn mà không cần gọi Refresh ngay, nếu Backend không yêu cầu kiểm tra session mỗi lần mở ứng dụng.

#### 3. Restore Profile

Sau khi xác định phiên hợp lệ:

- Gọi Profile API nếu cần để lấy dữ liệu mới nhất.
- Khôi phục User Profile.
- Không yêu cầu người dùng nhập lại mật khẩu.
- Nếu lỗi mạng, không tự kết luận Refresh Token không hợp lệ.
- Phân biệt Offline và Unauthorized.

Nếu Backend không thể xác minh token trong lúc mất mạng, phải sử dụng chính sách đã chốt trong Phase 1: giữ trạng thái phù hợp hoặc yêu cầu kết nối lại, không tự giả định phiên vẫn hợp lệ vô thời hạn.

#### 4. Startup Navigation

Điều hướng:

```text
RESTORING
    ↓
AUTHENTICATED → Main App
    ↓
GUEST → Guest Mode
    ↓
UNAUTHENTICATED → AccountEntry / Login
```

Không hiển thị LoginScreen trước khi hoàn tất kiểm tra trạng thái phiên nếu điều đó gây hiện tượng nháy màn hình.

### DONE

```text
[ ] Khôi phục Access Token
[ ] Refresh khi cần
[ ] Khôi phục User Profile
[ ] Khôi phục Authentication State
[ ] Mở lại ứng dụng không phải đăng nhập lại
[ ] Token hết hạn được xử lý đúng
[ ] Token bị thu hồi được xử lý đúng
[ ] Không có mạng không bị nhầm là sai mật khẩu
[ ] Điều hướng đúng theo Authentication State
```

---

## TASK 5.4 — LOGINSCREEN & REGISTER SCREEN (MQ03–MQ04)

### 🎯 Mục tiêu

Tích hợp màn hình Login và Register với Backend thực tế, sử dụng validation và trạng thái giao diện phù hợp.

### 5.4.1 — LoginScreen (MQ03)

Endpoint theo API Contract:

```text
POST /api/auth/login
```

Request phải dùng đúng cấu trúc Backend đã công bố.

Luồng:

```text
User Input
    ↓
Validate Form
    ↓
Call AuthRepository
    ↓
Call Backend Login API
    ↓
Receive User + Tokens
    ↓
Save Tokens Securely
    ↓
Update Auth State
    ↓
Navigate Main App
```

Yêu cầu giao diện:

- Email Input.
- Password Input.
- Show / Hide Password.
- Validation.
- Loading State.
- Error Message.
- Login Button.
- Google Sign-In Entry.
- Link sang Register.

Validation:

```text
Email:
- Không được rỗng
- Đúng định dạng
- Không có khoảng trắng không hợp lệ

Password:
- Không được rỗng
- Kiểm tra theo password policy đã thống nhất
```

Không hiển thị lỗi khác nhau khiến người dùng biết email có tồn tại hay không nếu Backend sử dụng lỗi đăng nhập thống nhất.

Không cho nhấn Login liên tục khi request đang xử lý.

### 5.4.2 — RegisterScreen (MQ04)

Endpoint theo API Contract:

```text
POST /api/auth/register
```

Luồng:

```text
User Input
    ↓
Validate Form
    ↓
Submit Register Request
    ↓
Backend Validate
    ↓
Create Account
    ↓
Receive Authentication Result
    ↓
Save Tokens Securely (nếu Register tự đăng nhập)
    ↓
Navigate Main App / Login
```

Các trường nhập liệu phải lấy theo Register Contract.

Có thể gồm:

```text
Email
Password
Confirm Password
Display Name
```

Không tự thêm trường không có trong requirement.

Validation:

- Email hợp lệ.
- Password đáp ứng policy.
- Confirm Password trùng.
- Trường bắt buộc không được rỗng.
- Hiển thị lỗi field tương ứng.
- Không gửi request khi form không hợp lệ.

Không lưu password sau khi đăng ký.

#### 5.4.3 — Authentication UI State

Cả hai màn hình phải xử lý:

```text
IDLE
VALIDATING
LOADING
SUCCESS
ERROR
```

Yêu cầu:

- Không gửi nhiều request trùng do nhấn nút liên tục.
- Hiển thị lỗi Backend dễ hiểu.
- Không để loading vô hạn.
- Không xóa input khi xảy ra lỗi không cần thiết.
- Không điều hướng khi request thất bại.

Không thay toàn bộ UI hiện tại nếu giao diện đã hoạt động và chỉ cần tích hợp logic.

### DONE

```text
[ ] LoginScreen gọi Backend thực tế
[ ] RegisterScreen gọi Backend thực tế
[ ] Form Validation hoạt động
[ ] Loading State hoạt động
[ ] Backend Error được hiển thị
[ ] Không gửi request trùng
[ ] Token được lưu an toàn
[ ] Login thành công điều hướng đúng
[ ] Register thành công đúng contract
[ ] Không lưu Password
```

---

## TASK 5.5 — PROFILE SCREEN (MQ05)

### 🎯 Mục tiêu

Tích hợp ProfileScreen với Backend, cho phép xem và cập nhật thông tin User hiện tại.

### Cách làm

#### 1. Get Profile

Sử dụng endpoint thực tế đã chốt.

Ví dụ:

```text
GET /api/auth/profile
```

Hoặc:

```text
GET /api/users/me
```

Không tự chọn một trong hai nếu API Contract đã định nghĩa cụ thể.

Luồng:

```text
Open ProfileScreen
       ↓
Get Authenticated State
       ↓
Call Profile API
       ↓
Parse Profile DTO
       ↓
Display Profile
```

#### 2. Update Profile

Sử dụng đúng HTTP Method theo API Contract.

```text
PUT hoặc PATCH
```

Không tự chuyển đổi method.

Hỗ trợ các trường được Backend cho phép cập nhật, ví dụ:

```text
Display Name
Avatar
Profile Information
```

Không cho Flutter gửi các trường:

```text
User ID để thay đổi chủ sở hữu
Password Hash
Role
Internal Account Status
```

trừ khi contract định nghĩa rõ.

#### 3. UI State

Phải có:

```text
Loading
Loaded
Editing
Saving
Success
Error
```

Xử lý:

- Loading Profile.
- Chế độ chỉnh sửa.
- Validation.
- Save.
- Hiển thị kết quả.
- Retry khi lỗi mạng.
- Refresh thông tin khi cần.

Nếu có ảnh đại diện:

- Sử dụng đúng cách lưu trữ đã được Backend hỗ trợ.
- Không tự gửi file ảnh qua một endpoint chưa tồn tại.
- Không lưu URL giả hoặc đường dẫn file local như ảnh đại diện cloud.

#### 4. Account Data Safety

Không xóa dữ liệu local khi cập nhật Profile.

Không tự động chuyển playlist, favorites hoặc history từ Guest sang User trong Phase 5.

### DONE

```text
[ ] ProfileScreen gọi Backend
[ ] Get Profile hoạt động
[ ] Update Profile hoạt động
[ ] HTTP Method đúng Contract
[ ] Validation hoạt động
[ ] Loading / Error State hoạt động
[ ] Không thay đổi User ID
[ ] Không gửi trường nhạy cảm
[ ] Không ảnh hưởng local music library
```

---

## TASK 5.6 — LOGOUT, GUEST & SESSION MANAGEMENT (MQ06)

### 🎯 Mục tiêu

Hoàn thiện đăng xuất, tiếp tục sử dụng ứng dụng ở chế độ Guest và quản lý quá trình chuyển đổi giữa các trạng thái tài khoản.

### 5.6.1 — Logout

Luồng:

```text
User Select Logout
        ↓
Call Backend Logout API
        ↓
Attempt Refresh Session Revocation
        ↓
Clear Local Authentication Tokens
        ↓
Clear User Session State
        ↓
Navigate AccountEntry
```

Yêu cầu:

- Gọi Backend Logout theo API Contract.
- Thu hồi Refresh Token khi Backend có thể kết nối.
- Luôn xóa credential local sau thao tác logout.
- Nếu mất mạng, vẫn phải đăng xuất phía Client.
- Ghi nhận kết quả thu hồi chưa xác nhận nếu cần xử lý retry theo thiết kế.
- Không tuyên bố Server đã thu hồi token nếu request không thành công.
- Không xóa thư viện nhạc local hoặc downloaded audio.
- Không reset SQLite.

Lưu ý: Nếu logout phía Server thất bại do mất mạng, token có thể còn hiệu lực trên Server đến khi hết hạn hoặc được thu hồi bằng biện pháp khác. Không được giả định gọi logout local đồng nghĩa đã thu hồi session phía Server.

### 5.6.2 — Guest Mode

Guest là trạng thái sử dụng ứng dụng không có tài khoản Backend.

Luồng:

```text
AccountEntry
     ↓
Continue as Guest
     ↓
Set GUEST State
     ↓
Open Main App
     ↓
Use Local Features
```

Guest có thể sử dụng các chức năng local mà ứng dụng đã hỗ trợ, theo giới hạn nghiệp vụ.

Guest không được:

- Gọi API yêu cầu JWT như User đã đăng nhập.
- Tạo dữ liệu cá nhân trên Cloud khi chưa có tài khoản.
- Sử dụng Refresh Token.
- Truy cập dữ liệu cá nhân của tài khoản khác.

Không cần giả lập một User Backend cho Guest.

### 5.6.3 — Session Switching

Khi chuyển từ User A sang User B:

- Xóa session token của User A.
- Khôi phục session User B.
- Cập nhật Authentication State.
- Không sử dụng token User A cho request của User B.
- Không tự ý gộp dữ liệu local của hai tài khoản.

Cách phân vùng và đồng bộ dữ liệu local theo User sẽ được hoàn thiện trong Phase 7.

### DONE

```text
[ ] Logout gọi Backend
[ ] Local tokens được xóa
[ ] Auth State được cập nhật
[ ] Logout vẫn thực hiện được khi mất mạng
[ ] Guest Mode hoạt động
[ ] Guest không gọi API cá nhân cần JWT
[ ] Chuyển tài khoản không dùng nhầm token
[ ] Không xóa Local Music Library
[ ] Không reset SQLite
[ ] Không tự merge dữ liệu Guest
```

---

## TASK 5.7 — ACCOUNT ENTRY (MQ08)

### 🎯 Mục tiêu

Hoàn thiện màn hình hoặc luồng AccountEntry làm điểm vào cho các trạng thái tài khoản.

### Cách làm

AccountEntry cần hỗ trợ:

```text
LOGIN
REGISTER
GOOGLE SIGN-IN
CONTINUE AS GUEST
```

Nếu sản phẩm có luồng khác theo Use Case, phải tuân thủ Use Case tương ứng.

Luồng:

```text
App Startup
      ↓
Restore Authentication State
      |
   +--+---------+----------------+
   |            |                |
Authenticated  Guest       Unauthenticated
   |            |                |
Main App     Main App       AccountEntry
                                |
                  +-------------+-------------+
                  |             |             |
                Login        Register       Guest
                  |             |             |
                  +-------------+-------------+
                                |
                            Main App
```

Yêu cầu:

- Chỉ có một điểm điều hướng Authentication chính.
- Tránh tạo nhiều LoginScreen hoặc RegisterScreen trùng lặp.
- Điều hướng đúng theo trạng thái hiện tại.
- Không tự đăng xuất khi ứng dụng chỉ chuyển màn hình.
- Không yêu cầu đăng nhập lại khi phiên hợp lệ.
- Không có Role Selection.

### DONE

```text
[ ] AccountEntry hoạt động
[ ] Login Navigation hoạt động
[ ] Register Navigation hoạt động
[ ] Google Entry hoạt động
[ ] Guest Entry hoạt động
[ ] Session Restore không bị trùng luồng
[ ] Không tạo màn hình Authentication trùng lặp
[ ] Không có Role Selection
```

---

## TASK 5.8 — GOOGLE SIGN-IN (MQ07)

### 🎯 Mục tiêu

Tích hợp Google Sign-In từ Flutter với Backend Google Authentication đã hoàn thành ở Phase 3.

### Cách làm

#### 1. Google Sign-In Configuration

Kiểm tra:

```text
Android package name
Google OAuth Client ID
Server Client ID / Audience
SHA-1 / SHA-256 (nếu cần theo cấu hình Android)
Google Sign-In dependency
Backend GOOGLE_CLIENT_ID
```

Không hardcode secret.

Cấu hình Client ID phải phù hợp giữa Flutter và Backend.

#### 2. Google Sign-In Flow

```text
User Select Google Sign-In
          ↓
Google Authentication UI
          ↓
Google ID Token
          ↓
Flutter Receives ID Token
          ↓
Send ID Token to Backend
          ↓
POST /api/auth/google
          ↓
Backend Verifies Google ID Token
          ↓
Backend Returns WaveBox Tokens
          ↓
Save WaveBox Tokens Securely
          ↓
Update Authentication State
          ↓
Navigate Main App
```

Flutter không tự tạo WaveBox JWT.

Không sử dụng Google Access Token thay cho JWT Backend.

#### 3. User Experience

Xử lý:

```text
User Cancelled
Google Sign-In Success
Google Sign-In Failed
No Internet
Backend Rejects ID Token
Google Configuration Missing
```

Không báo lỗi đăng nhập khi người dùng chủ động hủy Google Sign-In.

#### 4. Security

- Gửi Google ID Token đến Backend.
- Không tự tin email hoặc display name do Client cung cấp.
- Chỉ dùng User Profile từ Backend sau khi xác thực.
- Lưu WaveBox Access Token và Refresh Token bằng Secure Storage.
- Không lưu Google ID Token như Backend Access Token.

#### 5. Configuration Dependency

Nếu chưa có OAuth Client ID:

```text
[DEPENDENCY — GOOGLE OAUTH CLIENT ID]
```

Có thể hoàn thiện code gọi Backend và xử lý state bằng mock hoặc test token.

Chỉ được đánh dấu tích hợp thực tế PASS khi xác thực thành công bằng cấu hình Google hợp lệ.

### DONE

```text
[ ] Google Sign-In UI hoạt động
[ ] Google ID Token được nhận
[ ] ID Token gửi đúng Backend
[ ] Backend trả WaveBox JWT
[ ] WaveBox Tokens được lưu an toàn
[ ] Auth State được cập nhật
[ ] Cancel Flow hoạt động
[ ] Invalid Token được xử lý
[ ] Không dùng Google Token làm Backend Token
[ ] OAuth Real Integration Test PASS hoặc ghi DEPENDENCY
```

---

## TASK 5.9 — LOCAL / ONLINE SEARCH (MQ10)

### 🎯 Mục tiêu

Tích hợp tìm kiếm nhạc Local và Online, kết hợp dữ liệu đang có trên thiết bị với dữ liệu từ Backend.

### Cách làm

#### 1. Audit Existing SongRepository

Trước tiên đọc:

```text
SongRepository
AppDatabase
Search ViewModel
Search Screen
Current Search Logic
```

Giữ lại khả năng tìm kiếm nhạc local đã hoạt động.

Không thay toàn bộ SongRepository bằng API repository mới nếu có thể mở rộng code hiện tại.

#### 2. Local Search

Tìm kiếm các bài hát có metadata trong SQLite hoặc nguồn local hiện tại.

Luồng:

```text
User Search
     ↓
Search Local Repository
     ↓
Query SQLite / Existing Local Data
     ↓
Return Local Results
```

Search Local phải hoạt động khi mất mạng.

#### 3. Online Search

Sử dụng API Search của Phase 4.

Endpoint và query phải theo API Contract.

Luồng:

```text
User Search
      ↓
Validate Query
      ↓
Search API
      ↓
Spring Boot
      ↓
PostgreSQL
      ↓
Return Online Results
      ↓
Display Online Results
```

Nếu Backend yêu cầu JWT thì ApiClient tự gắn token.

Nếu API Catalog công khai theo contract thì không ép xác thực.

#### 4. Search Modes

Giao diện có thể tổ chức:

```text
ALL
LOCAL
ONLINE
```

Hoặc theo thiết kế Search hiện tại.

Yêu cầu:

- Local Search luôn hoạt động khi offline.
- Online Search chỉ thực hiện khi có mạng.
- Hiển thị trạng thái Online/Offline.
- Không chặn tìm kiếm local khi Backend không hoạt động.
- Có Loading State.
- Có Empty State.
- Có Error State.
- Có Retry.
- Có debounce để hạn chế gửi request liên tục.
- Hạn chế gửi request khi query rỗng.
- Hỗ trợ pagination nếu Backend hỗ trợ.

#### 5. Local & Online Result Separation

Khi hiển thị kết quả:

```text
LOCAL RESULTS
ONLINE RESULTS
```

Không mặc định hai bản ghi cùng tên là một bài hát.

Nếu cần gộp kết quả, phải có quy tắc nhận diện rõ ràng dựa trên ID hoặc mapping đã xác định.

Không tự động tải file online về thiết bị chỉ vì người dùng tìm thấy bài hát.

Không tự động phát online song song với local mà không theo hành vi sản phẩm đã chốt.

#### 6. Preserve Existing Player

Search chỉ có trách nhiệm tìm và điều hướng đến nội dung.

Không viết lại:

```text
Player
Playback Queue
Background Audio
Notification
Download
Offline Playback
```

Các phần này thuộc Phase 6.

### DONE

```text
[ ] Local Search hoạt động
[ ] Local Search không cần Internet
[ ] Online Search gọi Backend
[ ] Search API đúng Contract
[ ] Search Mode hoạt động
[ ] Loading / Empty / Error State
[ ] Debounce hoạt động
[ ] Pagination nếu có
[ ] Local / Online Results phân biệt rõ
[ ] Không gây ảnh hưởng Player
```

---

## TASK 5.10 — ALBUM / ARTIST / GENRE SCREENS (MQ11)

### 🎯 Mục tiêu

Tích hợp dữ liệu Album, Artist và Genre từ Backend Music Catalog vào Flutter.

### Cách làm

#### 1. Data Integration

Sử dụng:

```text
Album API
Artist API
Genre API
Song API
```

Các endpoint phải theo Phase 4 và `API_CONTRACT.md`.

Tổ chức Repository:

```text
AlbumRepository
ArtistRepository
GenreRepository
```

Nếu project có Repository tổng hợp phù hợp, có thể mở rộng thay vì tạo các lớp trùng chức năng.

#### 2. Album Screen

Hiển thị thông tin theo Backend Response:

```text
Album Artwork
Album Name
Artist
Release Date (nếu có)
Song List
```

Luồng:

```text
Open Album
    ↓
Get Album ID
    ↓
Call Album API
    ↓
Get Album Detail
    ↓
Load Album Songs
    ↓
Display Screen
```

#### 3. Artist Screen

Hiển thị:

```text
Artist Avatar
Artist Name
Biography (nếu có)
Albums
Songs
```

#### 4. Genre Screen

Hiển thị:

```text
Genre Name
Description (nếu có)
Songs thuộc Genre
```

#### 5. UI States

Mỗi màn hình cần có:

```text
LOADING
SUCCESS
EMPTY
ERROR
```

Yêu cầu:

- Không hiển thị dữ liệu giả khi API lỗi.
- Không crash khi artwork null.
- Có placeholder phù hợp.
- Có retry.
- Có pagination nếu dữ liệu lớn.
- Xử lý trường hợp ID không tồn tại.
- Hạn chế gọi API lặp lại khi Widget rebuild.
- Không tạo duplicate navigation route.

#### 6. Navigation

Từ các màn hình liên quan:

```text
Song → Album Detail
Song → Artist Detail
Song → Genre Detail
Album → Artist
Album → Song
Artist → Album
Artist → Song
Genre → Song
```

Chỉ tạo liên kết khi dữ liệu Backend có đủ quan hệ tương ứng.

#### 7. Offline Behavior

Nếu dữ liệu Album/Artist/Genre đã có trong local cache thì có thể hiển thị theo chính sách hiện tại.

Không tự triển khai một cơ chế cache và đồng bộ hoàn chỉnh mới nếu chưa được phân công; phần Offline-first thuộc Phase 7.

### DONE

```text
[ ] Album List hoạt động
[ ] Album Detail hoạt động
[ ] Artist List hoạt động
[ ] Artist Detail hoạt động
[ ] Genre List hoạt động
[ ] Genre Detail hoạt động
[ ] Data lấy từ Backend
[ ] Artwork null được xử lý
[ ] Loading / Empty / Error State
[ ] Retry hoạt động
[ ] Navigation đúng
[ ] Không gây ảnh hưởng Local Player
```

---

## TASK 5.11 — FLUTTER TESTS & API INTEGRATION TESTS (MQ09)

### 🎯 Mục tiêu

Kiểm chứng Flutter Authentication và API Integration hoạt động đúng, không làm hỏng các chức năng đã tồn tại.

### Cách làm

#### 1. Unit Tests

Kiểm tra:

```text
ApiClient
AuthRepository
AuthViewModel
Token Storage
Session Restore
Search Repository
Album Repository
Artist Repository
Genre Repository
```

#### 2. Widget Tests

Kiểm tra:

```text
LoginScreen
RegisterScreen
ProfileScreen
AccountEntry
Search Screen
Album Screen
Artist Screen
Genre Screen
```

Không yêu cầu tạo lại giao diện nếu chỉ cần kiểm thử Widget hiện có.

#### 3. Authentication Tests

Các tình huống:

```text
Register Success
Register Duplicate
Register Invalid Input
Login Success
Login Wrong Password
Refresh Success
Refresh Expired
Refresh Revoked
Logout Success
Restore Session Success
Restore Session Failed
Guest Mode
```

#### 4. API Client Tests

Kiểm tra:

```text
Base URL
Timeout
GET / POST / PUT / PATCH / DELETE
Bearer Token
401 Handling
Automatic Refresh
Concurrent Refresh
Retry Once
Refresh Failure
Network Error
Batch Request
```

Đặc biệt phải kiểm tra request chỉ retry một lần để không tạo vòng lặp.

#### 5. Profile Tests

```text
Get Profile
Update Profile
Invalid Input
Expired Token
Network Error
```

#### 6. Google Sign-In Tests

```text
Google Success (mock)
Google Cancelled
Invalid ID Token
Backend Rejects Token
Missing OAuth Configuration
```

Kiểm thử thực tế cần OAuth configuration hợp lệ.

#### 7. Search & Catalog Tests

```text
Local Search Online
Local Search Offline
Online Search Success
Online Search Failed
Album Detail
Artist Detail
Genre Detail
Empty Result
Pagination
```

#### 8. Regression Tests

Bắt buộc kiểm tra lại các chức năng cũ:

```text
Local Music Library
SQLite
SongRepository
Player
Playlist Local
Favorites Local
History Local
Download
Background Audio
```

Phase 5 không được làm các chức năng đang hoạt động bị lỗi chỉ vì thay đổi Authentication hoặc ApiClient.

#### 9. Commands

```bash
flutter pub get
```

```bash
flutter analyze
```

```bash
flutter test
```

Build Android theo cấu hình dự án:

```bash
flutter build apk --debug
```

Không chỉ kiểm tra bằng Mock. Phải có kiểm thử tích hợp với Backend thực tế cho các luồng quan trọng.

### DONE

```text
[ ] Unit Tests PASS
[ ] Widget Tests PASS
[ ] Authentication Tests PASS
[ ] ApiClient Tests PASS
[ ] Refresh Tests PASS
[ ] Profile Tests PASS
[ ] Google Tests PASS hoặc DEPENDENCY rõ ràng
[ ] Search Tests PASS
[ ] Catalog Screen Tests PASS
[ ] Regression Tests PASS
[ ] flutter analyze không có lỗi nghiêm trọng
[ ] Android Build thành công
```

---

## TASK 5.12 — DOCUMENTATION & PHASE 5 REPORT

### 🎯 Mục tiêu

Ghi lại những thay đổi Flutter, cấu hình Backend và kết quả tích hợp để Phase 6–7 có thể tiếp tục mà không phải phân tích lại.

Tạo:

```text
docs/REPORT/PHASE-5-FLUTTER-AUTH-API.md
```

Cập nhật nếu cần:

```text
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
```

Chỉ cập nhật khi có thay đổi API được thống nhất.

Báo cáo tối thiểu:

```markdown
# PHASE 5 — FLUTTER AUTHENTICATION & API INTEGRATION REPORT

## 1. Flutter Environment
- Flutter Version
- Dart Version
- Existing Architecture
- HTTP Library

## 2. Source Audit
- Existing Components
- Modified Components
- New Components

## 3. ApiClient
- Base URL
- Timeout
- HTTP Methods
- Interceptors
- Error Mapping
- Batch Request Support

## 4. Secure Token Storage
- Access Token
- Refresh Token
- Legacy Token Migration

## 5. Session Management
- Session Restore
- Authentication State
- Guest Mode
- Logout

## 6. Login / Register
- Request / Response
- Form Validation
- Test Results

## 7. Profile
- Get Profile
- Update Profile

## 8. Google Sign-In
- OAuth Configuration
- Backend Integration
- Test Results

## 9. AccountEntry
- Navigation
- Guest Entry
- Authentication Routing

## 10. Search & Catalog Screens
- Local Search
- Online Search
- Album
- Artist
- Genre

## 11. Unit / Widget / Integration Tests

## 12. Regression Test Results

## 13. Known Issues & Dependencies

## 14. Phase 5 Acceptance
- Completed Tasks
- Pending Tasks
- Final Status
```

### DONE

```text
[ ] Phase 5 Report hoàn chỉnh
[ ] API Contract không bị sai lệch
[ ] Decision Log được cập nhật nếu có
[ ] Cấu hình môi trường được mô tả
[ ] Không lộ token hoặc credentials
[ ] Kết quả kiểm thử có bằng chứng
```

---

# 5. PHASE 5 FINAL REVIEW

## 🎯 Mục tiêu

Kiểm tra toàn bộ MQ01–MQ11 trước khi bàn giao Flutter cho Phase 6 và Phase 7.

### DONE Checklist

```text
[ ] TASK 5.1 — Audit Existing Flutter Source
[ ] Existing Code đã được kiểm tra
[ ] Không tạo class trùng lặp
[ ] Không xóa tính năng cũ

[ ] TASK 5.2 — ApiClient (MQ02)
[ ] Base URL tập trung
[ ] GET / POST / PUT / PATCH / DELETE
[ ] Timeout hoạt động
[ ] Bearer Token tự động
[ ] Secure Storage
[ ] Automatic Refresh
[ ] Concurrent Refresh
[ ] Retry Once
[ ] Error Mapping
[ ] Batch Request Support

[ ] TASK 5.3 — Restore Session (MQ01)
[ ] Khôi phục Token
[ ] Khôi phục Profile
[ ] Refresh khi cần
[ ] Điều hướng theo Auth State

[ ] TASK 5.4 — Login / Register (MQ03–MQ04)
[ ] LoginScreen gọi Backend
[ ] RegisterScreen gọi Backend
[ ] Validation hoạt động
[ ] Loading / Error State
[ ] Token được lưu an toàn

[ ] TASK 5.5 — ProfileScreen (MQ05)
[ ] Get Profile
[ ] Update Profile
[ ] HTTP Method đúng Contract
[ ] Không lộ dữ liệu nhạy cảm

[ ] TASK 5.6 — Logout / Guest (MQ06)
[ ] Logout gọi Backend
[ ] Local Token được xóa
[ ] Guest Mode hoạt động
[ ] Không xóa Local Music Library
[ ] Session Switching đúng

[ ] TASK 5.7 — Google Sign-In (MQ07)
[ ] Google ID Token nhận được
[ ] Gửi đúng Backend
[ ] Nhận WaveBox JWT
[ ] OAuth Real Test PASS hoặc BLOCKED rõ ràng

[ ] TASK 5.8 — AccountEntry (MQ08)
[ ] Login Entry
[ ] Register Entry
[ ] Google Entry
[ ] Guest Entry
[ ] Navigation đúng

[ ] TASK 5.9 — Local / Online Search (MQ10)
[ ] Local Search
[ ] Online Search
[ ] Offline Behavior
[ ] Search API Integration
[ ] Loading / Empty / Error State

[ ] TASK 5.10 — Album / Artist / Genre (MQ11)
[ ] Album Screens
[ ] Artist Screens
[ ] Genre Screens
[ ] Backend Data Integration
[ ] Navigation đúng

[ ] TASK 5.11 — Tests (MQ09)
[ ] Unit Tests
[ ] Widget Tests
[ ] API Integration Tests
[ ] Regression Tests
[ ] Flutter Analyze
[ ] Android Build

[ ] TASK 5.12 — Documentation
[ ] Phase 5 Report
[ ] Environment Configuration
[ ] API Contract Consistency

[ ] Không làm hỏng Phase 1–4
[ ] Không thay đổi Backend ngoài phạm vi
[ ] Không làm hỏng Player / Download
[ ] Không mất SQLite Data
[ ] Git status đã được kiểm tra
```

---

# 6. ĐIỀU KIỆN PHASE 5 DONE

Chỉ được đánh dấu hoàn thành khi có bằng chứng:

**1. Flutter API Integration**

```text
Backend Reachability: PASS
API Client: PASS
Timeout Handling: PASS
Error Mapping: PASS
HTTP Methods: PASS
```

**2. Authentication**

```text
Register: PASS
Login: PASS
Secure Token Storage: PASS
Session Restore: PASS
Automatic Refresh: PASS
Logout: PASS
Guest Mode: PASS
```

**3. Profile & Google**

```text
Get Profile: PASS
Update Profile: PASS
Google Sign-In: PASS
```

Nếu thiếu OAuth configuration:

```text
Google Code Integration: COMPLETED
Google Real Integration: BLOCKED
Dependency: GOOGLE_OAUTH_CONFIGURATION
```

Không đánh dấu toàn bộ Phase 5 DONE nếu Google là requirement bắt buộc và chưa kiểm thử thực tế, trừ khi trạng thái hoàn thành có ngoại lệ được chấp thuận.

**4. Search & Music Catalog**

```text
Local Search: PASS
Online Search: PASS
Album Screen: PASS
Artist Screen: PASS
Genre Screen: PASS
```

**5. Regression**

```text
Local Library: PASS
SQLite: PASS
Player: PASS
Playlist Local: PASS
Favorites Local: PASS
History Local: PASS
Download: PASS
Background Audio: PASS
```

**6. Build & Tests**

```text
Flutter Analyze: PASS
Flutter Tests: PASS
Android Build: PASS
Backend Integration Tests: PASS
```

Nếu một phần chưa kiểm thử:

```text
[PASS]
[FAILED]
[NOT TESTED]
[BLOCKED]
```

Không tuyên bố Phase 5 hoàn tất khi vẫn còn lỗi nghiêm trọng khiến người dùng không thể đăng nhập, mất phiên hoặc không sử dụng được những tính năng cũ.

---

# 7. STOP RULE

Sau khi hoàn thành Phase 5:

**DỪNG.**

Không tự chuyển sang sửa đổi cơ chế Background Audio hoặc Download.

Không tự triển khai:

```text
Background Audio Handler Rewrite
Notification / MediaSession
Artwork Engine Changes
Volume Slider
Download Service
Sleep Timer
Offline Playback Refactor
Video Player Seekbar / Fullscreen
Full Offline Synchronization
Automatic Retry Queue
Cloud Restore
```

Các nội dung này thuộc Phase 6 và Phase 7.

Chỉ khi người dùng xác nhận:

```text
PHASE 5 DONE
```

mới chuyển sang:

```text
PHASE 6 — FLUTTER PLAYER & DOWNLOAD
```

---

# 8. TỔNG KẾT CẤU TRÚC PHASE 5

```text
PHASE 5 — FLUTTER AUTHENTICATION & API INTEGRATION
│
├── TASK 5.1
│   └── Audit Flutter Source
│
├── TASK 5.2
│   └── ApiClient / Timeout / Refresh / PATCH / Batch (MQ02)
│
├── TASK 5.3
│   └── Restore Login Session (MQ01)
│
├── TASK 5.4
│   └── LoginScreen & RegisterScreen (MQ03–MQ04)
│
├── TASK 5.5
│   └── ProfileScreen (MQ05)
│
├── TASK 5.6
│   └── Logout / Guest / Session Management (MQ06)
│
├── TASK 5.7
│   └── Google Sign-In (MQ07)
│
├── TASK 5.8
│   └── AccountEntry (MQ08)
│
├── TASK 5.9
│   └── Local / Online Search (MQ10)
│
├── TASK 5.10
│   └── Album / Artist / Genre Screens (MQ11)
│
├── TASK 5.11
│   └── Flutter Tests & Integration Tests (MQ09)
│
├── TASK 5.12
│   └── Documentation & Report
│
└── TASK 5.13
    └── Final Review & Stop
```

---

# 9. THỨ TỰ THỰC THI

```text
READ PHASE 1–4 DOCUMENTS
             ↓
AUDIT EXISTING FLUTTER SOURCE
             ↓
CONFIGURE API ENVIRONMENT
             ↓
IMPLEMENT / UPDATE APICLIENT
             ↓
IMPLEMENT SECURE TOKEN STORAGE
             ↓
IMPLEMENT AUTOMATIC REFRESH
             ↓
IMPLEMENT SESSION RESTORE
             ↓
INTEGRATE LOGIN / REGISTER
             ↓
INTEGRATE PROFILE
             ↓
IMPLEMENT LOGOUT / GUEST
             ↓
IMPLEMENT ACCOUNT ENTRY
             ↓
INTEGRATE GOOGLE SIGN-IN
             ↓
INTEGRATE LOCAL / ONLINE SEARCH
             ↓
IMPLEMENT ALBUM / ARTIST / GENRE SCREENS
             ↓
RUN UNIT / WIDGET / INTEGRATION TESTS
             ↓
RUN REGRESSION TESTS
             ↓
WRITE PHASE 5 REPORT
             ↓
FINAL REVIEW
             ↓
PHASE 5 DONE
             ↓
STOP
```

---

## NGUYÊN TẮC QUAN TRỌNG NHẤT

Phase 5 là giai đoạn đưa Backend WaveBox vào sử dụng thực tế từ ứng dụng Flutter.

Các màn hình không được tự xử lý Authentication hoặc gọi API riêng lẻ. Mọi request phải đi qua ApiClient và Repository; token phải được lưu an toàn; phiên đăng nhập phải được khôi phục đúng; Guest Mode phải tiếp tục sử dụng được dữ liệu local.

Đồng thời, Local Search và Online Search phải hoạt động độc lập để mất mạng không làm mất khả năng tìm nhạc trên thiết bị.

**Không đánh đổi các chức năng hiện có của WaveBox để tích hợp Backend.** Phase 5 phải bổ sung khả năng đăng nhập và khai thác dữ liệu trực tuyến mà vẫn giữ nguyên nền tảng nghe nhạc offline hiện tại.