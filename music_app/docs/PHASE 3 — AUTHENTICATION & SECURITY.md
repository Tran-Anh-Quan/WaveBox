# PHASE 3 — AUTHENTICATION & SECURITY

## 🎯 Mục tiêu Phase 3

Triển khai hệ thống xác thực và bảo mật cho Backend WaveBox bằng Spring Security và JWT, sử dụng nền tảng User, PostgreSQL và BCrypt đã hoàn thành ở Phase 2.

Phase 3 tập trung hoàn thiện:

```text
PHASE 1 — ARCHITECTURE & API CONTRACT
                 ↓
PHASE 2 — BACKEND CORE & POSTGRESQL
                 ↓
Configure Spring Security
                 ↓
Implement JWT Access Token
                 ↓
Implement Register / Login
                 ↓
Implement Refresh / Logout
                 ↓
Implement Profile & Password Change
                 ↓
Implement Google Sign-In
                 ↓
Validation & Error Handling
                 ↓
Postman & Security Testing
                 ↓
PHASE 3 DONE
```

**Phạm vi requirement:**

```text
H05 — Spring Security & JWT
H06 — Register / Login / Refresh / Logout
H07 — Profile / Update Profile / Change Password
H08 — Google Sign-In
H09 — Validation / Error Handler / Postman
```

Đầu ra Phase 3 là Backend Authentication hoàn chỉnh, có thể xác thực User bằng tài khoản mật khẩu hoặc Google, cấp và thu hồi token, bảo vệ API bằng JWT và kiểm soát quyền truy cập dữ liệu cá nhân.

Phase 3 **được phép tạo và sửa code Backend**, bổ sung migration cần thiết và triển khai các API xác thực.

Không triển khai Flutter Authentication Integration trong Phase này. Việc tích hợp Flutter thuộc Phase 5.

---

## 1. NGUYÊN TẮC TRIỂN KHAI

### 1.1 — Phase 1 & Phase 2 Source of Truth Rule

Trước khi code, bắt buộc đọc:

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/IMPLEMENTATION_ROADMAP.md
docs/REPORT/PHASE-2-BACKEND-CORE.md
```

Kiểm tra source Backend Phase 2:

```text
WaveBoxApplication.java
User.java
UserRepository.java
UserService.java
PasswordConfig.java
application.yml
Flyway migrations
Health Check
Base Error Handler
```

Các quy tắc phải tuân thủ:

```text
Java Version: 17
Framework: Spring Boot
Database: PostgreSQL
ORM: Spring Data JPA
Migration: Flyway
Password Hashing: BCrypt
User ID: UUID
User Model: Single User Model
Authorization: No Roles
Authentication: JWT
```

`docs/API_CONTRACT.md` là chuẩn cho endpoint, request, response và HTTP status.

Không tự ý định nghĩa lại endpoint hoặc thay đổi cấu trúc JSON đã chốt.

Nếu có điểm chưa được Phase 1 quyết định, ghi nhận và cập nhật Decision Log trước khi triển khai.

### 1.2 — Single User Model, No Roles

Hệ thống chỉ có một loại tài khoản:

```text
User
```

Không tạo:

```text
ADMIN
MODERATOR
CUSTOMER
VENDOR
ROLE_USER
ROLE_ADMIN
ROLE_BASED_ACCESS_CONTROL
```

Phải phân biệt:

```text
Authentication = Xác định User là ai

Ownership = Kiểm tra User có sở hữu dữ liệu hay không

Authorization = Kiểm tra request có được phép thực hiện hay không
```

Backend phải xác định `userId` từ JWT đã xác thực.

Không sử dụng `userId` do Client gửi trong request body hoặc query parameter để cấp quyền truy cập dữ liệu cá nhân.

Ví dụ:

```text
User A đăng nhập
       ↓
JWT chứa User A ID
       ↓
Request truy cập Playlist
       ↓
Backend lấy User A ID từ SecurityContext
       ↓
Kiểm tra Playlist thuộc User A
       ↓
Cho phép hoặc từ chối
```

Không được tin User ID mà Client tự truyền lên.

### 1.3 — Security-First Rule

Tất cả API phải được bảo vệ theo nguyên tắc:

```text
Default Deny
```

Chỉ các endpoint thực sự cần công khai mới được `permitAll()`.

Nguyên tắc:

- Không có JWT hợp lệ: từ chối API yêu cầu xác thực.
- JWT hết hạn: trả `401`.
- JWT sai chữ ký hoặc không hợp lệ: trả `401`.
- JWT hợp lệ nhưng không sở hữu dữ liệu: từ chối.
- Không cho phép User A truy cập dữ liệu cá nhân của User B.
- Không trả thông tin nhạy cảm trong response.
- Không log password, access token hoặc refresh token.

Không dùng role-based authorization để xử lý quyền sở hữu dữ liệu.

### 1.4 — Safe Modification Rule

Được phép tạo mới và sửa các thành phần thuộc H05–H09.

```text
✅ Tái sử dụng User Entity từ Phase 2
✅ Tái sử dụng PasswordEncoder
✅ Tạo Security Configuration
✅ Tạo JWT Service và Authentication Filter
✅ Tạo Auth Controller / Service
✅ Tạo Refresh Session Repository
✅ Tạo Profile API
✅ Tạo Google Token Verifier
✅ Tạo Flyway Migration mới nếu cần
✅ Tạo Validation và Error Handler
✅ Tạo Postman Collection
✅ Viết Unit / Integration Tests
```

Không được:

```text
❌ Xóa file hoặc thư mục hiện có
❌ Xóa class, method hoặc feature
❌ Tạo User Entity trùng lặp
❌ Tạo database mới thay thế database Phase 2
❌ Sửa migration đã được áp dụng
❌ DROP / TRUNCATE dữ liệu
❌ Reset Flyway history
❌ Xóa hoặc làm hỏng BCrypt đã triển khai
❌ Tự ý thay đổi API Contract
❌ Thay đổi Flutter source
❌ Triển khai Music API trong Phase 3
❌ Hardcode JWT Secret hoặc Google Client ID
❌ Commit / push khi chưa được yêu cầu
```

Mọi thay đổi database phải sử dụng Flyway migration mới, không phá hủy dữ liệu cũ.

### 1.5 — Token Security Rule

Sử dụng mô hình:

```text
Access Token:
Signed JWT
Thời hạn ngắn
Dùng gọi API được bảo vệ

Refresh Token:
Random Opaque Token
Thời hạn dài hơn
Dùng cấp Access Token mới
Có thể thu hồi
Được lưu dưới dạng hash ở Backend
```

Nếu `DECISION_LOG.md` đã chốt một cơ chế khác, phải tuân thủ quyết định đó.

Các nguyên tắc bắt buộc:

- Không lưu refresh token dạng plaintext trong database.
- Không đưa password vào JWT.
- Không đưa thông tin nhạy cảm vào JWT payload.
- Access Token phải kiểm tra chữ ký và thời hạn.
- Refresh Token phải được kiểm tra trạng thái và thời hạn.
- Refresh Token phải có khả năng thu hồi.
- Sử dụng HTTPS trong môi trường triển khai thực tế.
- Không ghi token vào log.

---

## 2. ĐIỀU KIỆN BẮT ĐẦU

Phase 3 được phép bắt đầu khi:

```text
PHASE 2 đã được xác nhận DONE
               +
Spring Boot khởi động thành công
               +
PostgreSQL kết nối thành công
               +
Flyway hoạt động
               +
User Entity / Repository / Service có sẵn
               +
BCrypt PasswordEncoder hoạt động
               +
API_CONTRACT.md đã được chốt
               +
Google OAuth Client ID đã được xác định
hoặc được ghi nhận là dependency riêng
```

Kiểm tra:

```bash
java -version
```

```bash
mvn test
```

```bash
git status --short
```

Nếu project dùng Gradle, sử dụng Gradle Wrapper thay cho Maven.

Nếu Phase 2 chưa hoàn thành, chỉ tiếp tục những việc không phụ thuộc phần còn thiếu và ghi nhận:

```text
[BLOCKED — PHASE 2 DEPENDENCY]
```

Google Sign-In có thể triển khai phần code xác minh trước khi có Client ID thực tế. Tuy nhiên, không được tuyên bố kiểm thử Google Sign-In hoàn chỉnh khi chưa có cấu hình OAuth hợp lệ.

---

## 3. PHẠM VI PHASE 3

### CHỈ LÀM

```text
H05 — Spring Security & JWT
H06 — Register / Login / Refresh / Logout
H07 — Profile / Update Profile / Change Password
H08 — Google Sign-In
H09 — Validation / Error Handler / Postman

JWT Access Token
Refresh Token Rotation
Refresh Token Revocation
Security Filter Chain
User Authentication
User Ownership Verification
Google ID Token Verification
Security Tests
Authentication Documentation
```

### KHÔNG ĐƯỢC LÀM

```text
Spring Boot Initialization
PostgreSQL Core Setup
User Entity Core (đã thuộc Phase 2)
Music Catalog
Songs / Albums / Artists / Genres
Playlist CRUD
Favorites
History
Streaming Audio
Batch Sync
Flutter Login/Register Integration
Flutter Token Storage
Flutter Google Sign-In UI
Player / Download Changes
Full End-to-End Testing (Phase 8)
```

---

# 4. CÁC TASK THỰC HIỆN

## TASK 3.1 — SPRING SECURITY CONFIGURATION (H05)

### 🎯 Mục tiêu

Thiết lập Spring Security để bảo vệ Backend bằng JWT, không sử dụng session đăng nhập phía Server và không triển khai roles.

### Cách làm

#### 1. Cấu trúc Security

Tạo hoặc hoàn thiện:

```text
config/security/
├── SecurityConfig.java
├── JwtAuthenticationFilter.java
├── JwtAuthenticationEntryPoint.java
├── JwtAccessDeniedHandler.java
└── CustomUserPrincipal.java
```

Các class có thể được tổ chức khác nếu project đã có convention riêng.

Trách nhiệm:

```text
SecurityConfig
    └── Cấu hình SecurityFilterChain

JwtAuthenticationFilter
    └── Đọc và xác minh Access Token

CustomUserPrincipal
    └── Đại diện User đã xác thực

JwtAuthenticationEntryPoint
    └── Xử lý lỗi 401

JwtAccessDeniedHandler
    └── Xử lý lỗi 403
```

Không tạo các class trùng chức năng với class đã có.

#### 2. SecurityFilterChain

Cấu hình:

```text
Session Creation Policy: STATELESS
CSRF: Theo mô hình Bearer Token
Authentication: JWT
Password Encoder: BCrypt
```

Với API sử dụng Bearer Token stateless trong Authorization Header, CSRF có thể được tắt cho API này. Nếu có sử dụng cookie tự động gửi kèm request, phải đánh giá CSRF riêng, không được tắt một cách máy móc.

Không tạo HttpSession để duy trì đăng nhập.

#### 3. Public Endpoints

Các endpoint có thể công khai:

```text
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
POST /api/auth/google
GET  /actuator/health
```

Danh sách chính thức phải khớp `API_CONTRACT.md`.

Logout có thể được xử lý bằng refresh token hợp lệ để thu hồi phiên ngay cả khi Access Token đã hết hạn. Nếu sử dụng cách này, Backend phải xác minh refresh token trước khi thu hồi session.

Không mở công khai những API chỉ vì việc cấu hình bảo mật gây khó khăn.

#### 4. Protected Endpoints

Các API cá nhân phải yêu cầu xác thực:

```text
/api/users/me
/api/auth/profile
/api/auth/change-password
```

Các API khác sẽ được bổ sung theo Phase 4 và phải tuân thủ nguyên tắc bảo vệ mặc định.

#### 5. CORS

Cấu hình CORS theo môi trường:

```text
Development Origins
Production Origins
Allowed Methods
Allowed Headers
Exposed Headers (nếu cần)
Credentials Policy
```

Không sử dụng wildcard origin trong môi trường production cùng chế độ cho phép credentials.

#### 6. Single User Authentication

Không cấu hình:

```text
hasRole()
hasAnyRole()
ROLE_USER
ROLE_ADMIN
```

SecurityContext chỉ cần xác định User đã đăng nhập.

Mỗi request đã xác thực phải có thể truy xuất:

```text
authenticatedUserId
```

### DONE

```text
[ ] SecurityFilterChain hoạt động
[ ] Stateless authentication
[ ] JWT Filter được đăng ký đúng vị trí
[ ] Public endpoints đúng contract
[ ] Protected endpoints yêu cầu JWT
[ ] Không có role-based authorization
[ ] Không tạo HttpSession
[ ] CORS đúng môi trường
[ ] 401 và 403 được xử lý riêng
[ ] Không làm hỏng Health Check
```

---

## TASK 3.2 — JWT ACCESS TOKEN & TOKEN SERVICE (H05)

### 🎯 Mục tiêu

Xây dựng cơ chế phát hành, ký và xác minh Access Token để Backend nhận diện User trong mỗi request.

### Cách làm

#### 1. JWT Service

Tạo:

```text
features/auth/service/JwtService.java
```

Hoặc vị trí tương đương theo cấu trúc project.

Chức năng:

```text
Generate Access Token
Validate Access Token
Extract User ID
Check Expiration
Check Issuer
Check Audience (nếu contract yêu cầu)
Verify Signature
```

#### 2. JWT Claims

Access Token nên chứa tối thiểu:

```text
iss — Issuer
sub — User UUID
iat — Issued At
exp — Expiration
jti — JWT ID
```

Có thể bổ sung `aud` nếu kiến trúc triển khai yêu cầu.

Không đưa vào JWT:

```text
Password
Password Hash
Refresh Token
Sensitive Profile Data
Database Information
Role Claims
```

`sub` phải đại diện cho UUID User.

Không sử dụng email hoặc username làm định danh chính thay cho User UUID.

#### 3. Signing Key

Thuật toán ký phải theo Decision Log và cấu hình môi trường.

Ví dụ:

```text
JWT_SECRET
JWT_ISSUER
JWT_AUDIENCE
JWT_ACCESS_TOKEN_TTL
```

Yêu cầu:

- Secret hoặc private key lấy từ environment/secret manager.
- Không hardcode secret.
- Không commit secret thực tế.
- Không sử dụng thuật toán `none`.
- Chỉ chấp nhận thuật toán ký đã cấu hình.
- Có kiểm tra chữ ký, issuer và expiration.
- Có kế hoạch thay đổi khóa khi triển khai production.

Nếu dùng HMAC, phải bảo đảm secret đủ mạnh và đồng nhất giữa các instance Backend.

Nếu dùng RSA/EC, private key dùng ký và public key dùng xác minh phải được cấu hình an toàn.

#### 4. Token Lifetime

Thời hạn Access Token và Refresh Token phải theo API Contract.

Nếu Phase 1 chưa chốt, ghi rõ đề xuất trước khi áp dụng. Có thể dùng cấu hình development ban đầu:

```text
ACCESS_TOKEN_TTL = 15 minutes
REFRESH_TOKEN_TTL = 30 days
```

Đây là giá trị đề xuất có thể cấu hình, không được hardcode trong logic.

#### 5. Authentication Filter

Luồng:

```text
Client Request
      ↓
Read Authorization Header
      ↓
Extract Bearer Token
      ↓
Verify JWT Signature
      ↓
Check Expiration / Claims
      ↓
Extract User UUID
      ↓
Load User
      ↓
Create Authentication
      ↓
Set SecurityContext
      ↓
Continue Request
```

Nếu token không có hoặc không hợp lệ:

- Public endpoint tiếp tục xử lý theo cấu hình.
- Protected endpoint phải trả lỗi theo API Contract.
- Không được bỏ qua lỗi xác minh để cho phép truy cập.

### DONE

```text
[ ] JWT được ký đúng
[ ] JWT được xác minh đúng
[ ] User UUID trong sub đúng
[ ] Token hết hạn bị từ chối
[ ] Token sai chữ ký bị từ chối
[ ] Token không hợp lệ bị từ chối
[ ] Secret không hardcode
[ ] JWT không chứa password hoặc thông tin nhạy cảm
[ ] User được nhận diện qua SecurityContext
```

---

## TASK 3.3 — REGISTER & LOGIN (H06)

### 🎯 Mục tiêu

Triển khai đăng ký và đăng nhập bằng email/password, sử dụng User và BCrypt đã xây dựng ở Phase 2.

### 3.3.1 — Register API

Endpoint theo API Contract.

Ví dụ:

```text
POST /api/auth/register
```

Request minh họa:

```json
{
  "email": "user@example.com",
  "password": "StrongPassword123",
  "displayName": "WaveBox User"
}
```

Các field thực tế phải theo contract đã chốt.

Luồng:

```text
Register Request
      ↓
Validate Input
      ↓
Normalize Email
      ↓
Check Existing User
      ↓
Encode Password with BCrypt
      ↓
Create User
      ↓
Save PostgreSQL
      ↓
Issue Access Token
      ↓
Issue Refresh Token
      ↓
Return Authentication Response
```

Yêu cầu:

- Email đúng định dạng.
- Password tuân theo password policy đã chốt.
- Kiểm tra dữ liệu bắt buộc.
- Không cho tạo tài khoản trùng email.
- Không lưu plaintext password.
- Không cho Client tự truyền User ID để quyết định ID tài khoản.
- Không tạo role.
- Xử lý trường hợp nhiều request đăng ký cùng email.
- Unique constraint trong database vẫn là lớp bảo vệ cuối cùng.

Nếu Register API được thiết kế tự đăng nhập sau khi đăng ký, phải trả token theo đúng API Contract.

### 3.3.2 — Login API

Ví dụ:

```text
POST /api/auth/login
```

Request:

```json
{
  "email": "user@example.com",
  "password": "StrongPassword123"
}
```

Luồng:

```text
Login Request
      ↓
Validate Input
      ↓
Normalize Email
      ↓
Find User
      ↓
BCrypt Password Matches
      ↓
Create Refresh Session
      ↓
Generate Access JWT
      ↓
Return Tokens & User Data
```

Yêu cầu:

- Không xác thực bằng password plaintext trong database.
- Không trả password hash.
- Không trả thông tin nhạy cảm.
- Không tiết lộ tài khoản có tồn tại hay không thông qua thông báo lỗi khác nhau.
- Sai email hoặc password phải trả lỗi xác thực thống nhất theo contract.
- Không cho đăng nhập nếu tài khoản ở trạng thái bị khóa, nếu Phase 1 đã xác định có trạng thái tài khoản.

### 3.3.3 — Authentication Response

Cấu trúc minh họa:

```json
{
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "displayName": "WaveBox User"
    },
    "accessToken": "access-token",
    "refreshToken": "refresh-token",
    "tokenType": "Bearer",
    "expiresIn": 900
  }
}
```

Response thực tế phải thống nhất với `API_CONTRACT.md`.

Không trả:

```text
password
passwordHash
databaseId nội bộ
JWT Signing Secret
Refresh Token Hash
```

### DONE

```text
[ ] Register thành công
[ ] Login thành công
[ ] Duplicate Email bị từ chối
[ ] Invalid Email bị từ chối
[ ] Weak Password bị từ chối theo policy
[ ] Wrong Password bị từ chối
[ ] BCrypt được sử dụng
[ ] User UUID được tạo đúng
[ ] Access Token được phát hành
[ ] Refresh Token được phát hành
[ ] Không có role trong User Model
```

---

## TASK 3.4 — REFRESH TOKEN & LOGOUT (H06)

### 🎯 Mục tiêu

Quản lý phiên đăng nhập, làm mới Access Token và thu hồi Refresh Token.

Đây là phần bắt buộc để hỗ trợ đăng nhập lâu dài trên Flutter mà không phải yêu cầu người dùng nhập lại mật khẩu liên tục.

### 3.4.1 — Refresh Session Storage

Kiểm tra database hiện tại.

Nếu chưa có nơi lưu phiên refresh, tạo Flyway migration mới:

```text
Vx__create_refresh_sessions.sql
```

Không chỉnh sửa migration đã chạy.

Bảng đề xuất:

```text
refresh_sessions
----------------
id
user_id
token_hash
token_family_id
issued_at
expires_at
revoked_at
replaced_by
last_used_at
```

Cấu trúc thực tế phải tuân thủ Decision Log và database convention.

Yêu cầu:

- `user_id` là Foreign Key tới User.
- `token_hash` lưu hash, không lưu raw token.
- Có thời điểm hết hạn.
- Có trạng thái thu hồi.
- Có thông tin liên kết các token trong cùng một phiên hoặc token family.
- Có index phục vụ tra cứu.
- Không làm mất dữ liệu bảng User.

Refresh Token nên là chuỗi ngẫu nhiên có entropy cao. Vì token được tạo ngẫu nhiên với độ khó đoán lớn, có thể dùng SHA-256 để lưu hash và so sánh; không cần dùng BCrypt như password người dùng.

### 3.4.2 — Refresh Token Generation

Luồng:

```text
Generate Secure Random Token
          ↓
Create Token Hash
          ↓
Save Hash to PostgreSQL
          ↓
Return Raw Token to Client
```

Raw Refresh Token chỉ được trả về Client khi cấp phát.

Không lưu raw token trong database, log hoặc báo cáo.

### 3.4.3 — Refresh API

Ví dụ:

```text
POST /api/auth/refresh
```

Request:

```json
{
  "refreshToken": "current-refresh-token"
}
```

Luồng:

```text
Receive Refresh Token
        ↓
Hash Incoming Token
        ↓
Find Stored Token Hash
        ↓
Check Expiration
        ↓
Check Revoked Status
        ↓
Verify Session / Token Family
        ↓
Revoke Current Refresh Token
        ↓
Generate New Access Token
        ↓
Generate New Refresh Token
        ↓
Save New Refresh Session
        ↓
Return New Token Pair
```

Yêu cầu:

- Mỗi lần refresh thành công phải xoay refresh token nếu contract sử dụng rotation.
- Token cũ không được sử dụng lại.
- Refresh Token hết hạn phải bị từ chối.
- Refresh Token đã thu hồi phải bị từ chối.
- Không tạo refresh token trùng.
- Cập nhật việc thu hồi và phát token mới trong transaction phù hợp.
- Phải xử lý trường hợp hai request refresh đồng thời.
- Nếu phát hiện token cũ đã bị sử dụng lại sau khi rotation, áp dụng chính sách thu hồi token family đã chốt để hạn chế replay attack.

### 3.4.4 — Logout API

Ví dụ:

```text
POST /api/auth/logout
```

Request minh họa:

```json
{
  "refreshToken": "current-refresh-token"
}
```

Luồng:

```text
Receive Logout Request
        ↓
Validate Refresh Token
        ↓
Find Refresh Session
        ↓
Revoke Session
        ↓
Return Logout Result
```

Yêu cầu:

- Thu hồi Refresh Token của session cần đăng xuất.
- Không ảnh hưởng session của User khác.
- Không cho sử dụng lại Refresh Token đã thu hồi.
- Xử lý logout lặp lại theo contract một cách an toàn.
- Không yêu cầu Client gửi User ID để quyết định session cần thu hồi.

Nếu chính sách là đăng xuất tất cả thiết bị, phải có thao tác riêng hoặc quy tắc rõ ràng; không tự động thu hồi toàn bộ session khi người dùng chỉ logout một thiết bị.

### 3.4.5 — Access Token Revocation

Cần phân biệt:

```text
Revoke Refresh Token
         ≠
Immediately Revoke Existing Access JWT
```

Với JWT stateless, thu hồi Refresh Token ngăn việc cấp token mới nhưng Access Token đã phát hành vẫn có thể hợp lệ đến khi hết hạn.

Phương án mặc định:

- Access Token có thời hạn ngắn.
- Refresh Token được thu hồi khi logout.
- Không cần truy vấn database mỗi request chỉ để kiểm tra JWT còn trong denylist hay không.

Nếu requirement bắt buộc logout phải vô hiệu hóa Access Token ngay lập tức, cần thiết kế token version, denylist hoặc session validation phù hợp. Phải ghi rõ chi phí và tác động hiệu năng trước khi triển khai.

### DONE

```text
[ ] Refresh Session được lưu trong PostgreSQL
[ ] Refresh Token chỉ lưu dạng hash
[ ] Refresh Token có thời hạn
[ ] Refresh Token Rotation hoạt động
[ ] Token cũ bị từ chối sau rotation
[ ] Token hết hạn bị từ chối
[ ] Token bị thu hồi không sử dụng lại được
[ ] Logout thu hồi đúng session
[ ] Reuse Detection được kiểm tra
[ ] Không làm hỏng các session khác
```

---

## TASK 3.5 — PROFILE & CHANGE PASSWORD (H07)

### 🎯 Mục tiêu

Cho phép User xem và cập nhật thông tin cá nhân, thay đổi mật khẩu an toàn.

### 3.5.1 — Get Profile API

Endpoint theo API Contract.

Ví dụ:

```text
GET /api/auth/profile
```

Hoặc endpoint `/api/users/me` nếu contract đã chốt như vậy.

Luồng:

```text
Request
   ↓
Verify Access JWT
   ↓
Extract User UUID
   ↓
Load User
   ↓
Map to Profile DTO
   ↓
Return Profile
```

Không nhận User ID từ Client để truy vấn hồ sơ của người khác.

### 3.5.2 — Update Profile API

Sử dụng HTTP method theo API Contract.

Ví dụ nếu dùng PATCH:

```text
PATCH /api/auth/profile
```

Request minh họa:

```json
{
  "displayName": "New Display Name",
  "avatarUrl": "https://example.com/avatar.png"
}
```

Các field phải theo đúng User Model đã chốt.

Yêu cầu:

- Chỉ cập nhật các trường được phép.
- Không cho phép cập nhật `id` hoặc `passwordHash`.
- Không cho phép thêm `role`.
- Không cho sửa các trường quản trị nội bộ.
- Xử lý null và field bị bỏ qua đúng theo contract.
- Nếu cho phép đổi email, phải có quy trình xác minh email trước khi thay đổi định danh tài khoản.
- User chỉ được cập nhật profile của chính mình.

### 3.5.3 — Change Password API

Endpoint minh họa:

```text
PUT /api/auth/change-password
```

Request:

```json
{
  "currentPassword": "OldPassword123",
  "newPassword": "NewPassword123"
}
```

Luồng:

```text
Verify Access JWT
       ↓
Load Authenticated User
       ↓
Verify Current Password
       ↓
Validate New Password
       ↓
BCrypt Encode New Password
       ↓
Update Password Hash
       ↓
Revoke Relevant Refresh Sessions
       ↓
Return Success
```

Yêu cầu:

- Không trả password hash.
- Không log password.
- Xác thực current password đối với tài khoản đăng nhập bằng mật khẩu.
- Password mới phải tuân theo policy.
- Không cho phép mật khẩu mới không hợp lệ.
- Thực hiện update trong transaction phù hợp.
- Thu hồi các Refresh Session theo chính sách đã chốt, mặc định nên yêu cầu đăng nhập lại trên các thiết bị sau khi đổi mật khẩu.

Đối với tài khoản chỉ dùng Google, không được giả định rằng tài khoản có current password. Phải có quy trình xác minh lại Google hoặc thiết lập mật khẩu phù hợp nếu requirement cho phép.

### DONE

```text
[ ] Get Profile hoạt động
[ ] Update Profile hoạt động
[ ] Không cập nhật được trường nhạy cảm ngoài phạm vi
[ ] Không truy cập profile User khác
[ ] Change Password hoạt động
[ ] Current Password được kiểm tra
[ ] Password mới được BCrypt
[ ] Password cũ không còn xác thực được
[ ] Refresh Session được xử lý theo chính sách
[ ] Không lộ thông tin nhạy cảm
```

---

## TASK 3.6 — GOOGLE SIGN-IN (H08)

### 🎯 Mục tiêu

Cho phép User đăng nhập hoặc đăng ký bằng Google, nhưng Backend vẫn là nơi phát hành JWT nội bộ cho các API WaveBox.

### Nguyên tắc bắt buộc

```text
Flutter Google Sign-In
          ↓
Google ID Token
          ↓
Backend Verify Google ID Token
          ↓
Find or Create WaveBox User
          ↓
Issue WaveBox Access JWT
          ↓
Issue WaveBox Refresh Token
          ↓
Flutter Uses WaveBox Tokens
```

Google ID Token không được dùng thay thế Access Token của Backend để gọi API WaveBox.

### Cách làm

#### 1. Google Configuration

Cấu hình qua environment variables:

```text
GOOGLE_CLIENT_ID
GOOGLE_ALLOWED_AUDIENCES (nếu cần)
```

Không hardcode Client ID hoặc Client Secret.

Với Android, phải đối chiếu đúng cấu hình OAuth của ứng dụng và luồng token được gửi về Backend. Audience phải khớp Client ID mà Backend được cấu hình để chấp nhận.

#### 2. Google Token Verifier

Tạo:

```text
features/auth/service/GoogleTokenVerifier.java
```

Sử dụng thư viện xác minh Google ID Token phù hợp, không tự giải mã payload rồi tin dữ liệu Client gửi lên.

Backend phải kiểm tra:

```text
Token Signature
Issuer
Audience
Expiration
Subject (sub)
Email
Email Verified
```

Yêu cầu:

- Token hợp lệ.
- Token chưa hết hạn.
- Issuer đúng Google.
- Audience đúng Client ID được phép.
- Google subject `sub` có giá trị.
- Email phải được xác minh theo chính sách.
- Không tin email hoặc display name do Client tự gửi.
- Không chỉ decode JWT để kết luận token hợp lệ.

#### 3. User Lookup & Account Linking

Dùng Google `sub` làm định danh liên kết tài khoản ngoài.

Luồng:

```text
Receive Google ID Token
          ↓
Verify Google Token
          ↓
Extract Google Subject
          ↓
Find Linked Google Identity
          |
      +---+---+
      |       |
    Found   Not Found
      |       |
      |    Check Email
      |       |
      |   +---+---+
      |   |       |
      | Existing  New
      |   |       |
      | Linking  Create User
      | Policy   + Google Identity
      |   |       |
      +---+-------+
          ↓
Issue WaveBox Tokens
```

Quy tắc quan trọng:

- Không dùng display name làm định danh tài khoản.
- Không tự động liên kết tài khoản chỉ vì email trùng nếu chưa có chính sách an toàn.
- Nếu email Google đã tồn tại trong một tài khoản password, cần xử lý theo chính sách account linking đã chốt.
- Không tạo hai User trùng một email.
- Một Google identity không được liên kết với nhiều User.
- Không tạo User mới nếu token Google không hợp lệ.

Ưu tiên mô hình liên kết identity riêng nếu kiến trúc Phase 1 đã chọn mô hình đó.

Nếu Phase 2 đang bắt buộc `password_hash NOT NULL`, phải kiểm tra khả năng tạo tài khoản chỉ dùng Google. Không lưu password giả hoặc plaintext để né constraint. Nếu cần, tạo Flyway migration mới để hỗ trợ tài khoản OAuth-only theo đúng mô hình đã quyết định.

#### 4. Google Authentication API

Endpoint theo API Contract.

Ví dụ:

```text
POST /api/auth/google
```

Request minh họa:

```json
{
  "idToken": "google-id-token"
}
```

Response phải trả cùng loại token nội bộ của WaveBox như Register/Login.

### DONE

```text
[ ] Google Client ID được cấu hình
[ ] Google ID Token được xác minh ở Backend
[ ] Sai signature bị từ chối
[ ] Sai audience bị từ chối
[ ] Token hết hạn bị từ chối
[ ] Issuer không hợp lệ bị từ chối
[ ] Email chưa xác minh được xử lý đúng policy
[ ] Google sub được liên kết chính xác
[ ] Không tạo User trùng
[ ] Google Sign-In cấp WaveBox JWT
[ ] Không dùng Google Token trực tiếp cho API nội bộ
```

Nếu thiếu OAuth Client ID, đánh dấu:

```text
[DEPENDENCY — GOOGLE OAUTH CLIENT ID]
```

Code có thể hoàn thành và test bằng mock hoặc test token không hợp lệ, nhưng không được đánh dấu Google Sign-In thực tế PASS khi chưa có cấu hình hợp lệ.

---

## TASK 3.7 — VALIDATION & ERROR HANDLING (H09)

### 🎯 Mục tiêu

Chuẩn hóa validation và xử lý lỗi cho tất cả API Authentication.

### Cách làm

#### 1. Request Validation

Sử dụng Jakarta Bean Validation hoặc cơ chế tương ứng.

Kiểm tra các trường:

```text
Register:
- Email
- Password
- Display Name (nếu bắt buộc)

Login:
- Email
- Password

Refresh:
- Refresh Token

Profile:
- Các trường được phép cập nhật

Change Password:
- Current Password
- New Password

Google:
- Google ID Token
```

Validation phải theo requirement và API Contract.

Không tự ý đưa ra password policy khác với tài liệu đã chốt.

#### 2. Global Exception Handler

Tạo hoặc mở rộng:

```text
common/exception/GlobalExceptionHandler.java
```

Xử lý tối thiểu:

```text
Validation Error
Invalid Credentials
Duplicate Email
Invalid / Expired JWT
Invalid / Expired Refresh Token
Revoked Session
Forbidden Access
User Not Found
Google Token Verification Error
Database Constraint Violation
Unexpected Internal Error
```

#### 3. HTTP Status

Tuân thủ `docs/API_CONTRACT.md`.

Bảng tham khảo:

| Status | Ý nghĩa | Trường hợp |
|---|---|---|
| 200 | OK | Login, Refresh, Profile hoặc Update thành công |
| 201 | Created | Register tạo User mới |
| 204 | No Content | Logout thành công nếu contract quy định |
| 400 | Bad Request | Validation lỗi |
| 401 | Unauthorized | Sai thông tin xác thực hoặc JWT không hợp lệ |
| 403 | Forbidden | Không đủ quyền truy cập |
| 404 | Not Found | Resource không tồn tại |
| 409 | Conflict | Email trùng hoặc conflict dữ liệu |
| 429 | Too Many Requests | Vượt giới hạn request nếu rate limiting được triển khai |
| 500 | Internal Server Error | Lỗi hệ thống |

Không sử dụng `403` thay thế `401` cho trường hợp chưa xác thực.

#### 4. Error Response

Sử dụng cấu trúc đã thống nhất ở `API_CONTRACT.md`.

Response minh họa:

```json
{
  "timestamp": "2026-11-13T10:00:00Z",
  "status": 401,
  "code": "INVALID_CREDENTIALS",
  "message": "Authentication failed",
  "path": "/api/auth/login"
}
```

Yêu cầu:

- Không trả stack trace.
- Không trả SQL exception thô.
- Không tiết lộ password hash.
- Không tiết lộ JWT secret.
- Không ghi token vào error log.
- Error code phải ổn định để Flutter xử lý.

### DONE

```text
[ ] Register Validation
[ ] Login Validation
[ ] Refresh Validation
[ ] Profile Validation
[ ] Change Password Validation
[ ] Google Token Validation
[ ] Global Exception Handler
[ ] 400 / 401 / 403 / 409 đúng nghĩa
[ ] Response đúng API Contract
[ ] Không lộ thông tin nhạy cảm
```

---

## TASK 3.8 — POSTMAN COLLECTION & AUTHENTICATION TESTING (H09)

### 🎯 Mục tiêu

Tạo Postman Collection để kiểm thử đầy đủ API Authentication và Security mà không cần phụ thuộc Flutter.

### Cách làm

Tạo:

```text
postman/
├── WaveBox-Auth.postman_collection.json
└── WaveBox-Local.postman_environment.json.example
```

Tên và vị trí thực tế phải tuân theo cấu trúc repository.

#### 1. Postman Variables

```text
baseUrl
accessToken
refreshToken
userId
googleIdToken
```

Không đưa token hoặc thông tin đăng nhập thật vào file được commit.

#### 2. Collection Requests

```text
AUTHENTICATION
│
├── Register
├── Register Duplicate Email
├── Register Invalid Email
├── Register Invalid Password
├── Login
├── Login Wrong Password
├── Refresh Token
├── Refresh Expired Token
├── Refresh Reused Token
├── Logout
├── Logout Revoked Token
└── Google Sign-In

PROFILE
│
├── Get Profile
├── Update Profile
├── Change Password
└── Change Password Wrong Current Password

SECURITY
│
├── Access Without Token
├── Access Invalid Token
├── Access Expired Token
├── Access Malformed Token
├── Access Revoked Session
└── Cross-User Access Test
```

Các request phải sử dụng đúng endpoint và method trong API Contract.

#### 3. Test Scripts

Postman tự động:

- Lưu `accessToken` sau Register/Login.
- Lưu `refreshToken`.
- Lưu `userId`.
- Gửi Authorization Bearer.
- Gửi Refresh Token.
- Cập nhật token mới sau Refresh.
- Kiểm tra HTTP status.
- Kiểm tra JSON structure.
- Kiểm tra error code.

Không hardcode token trong từng request.

#### 4. Security Test — Two Users

Tạo hai tài khoản kiểm thử:

```text
User A
User B
```

Thực hiện:

```text
1. Register User A
2. Login User A
3. Register User B
4. Login User B
5. Gửi Access Token User A
6. Thử truy cập dữ liệu cá nhân của User B
7. Kiểm tra Backend từ chối
8. Kiểm tra User A vẫn truy cập được dữ liệu của chính mình
```

Trong Phase 3 có thể dùng User/Profile làm đối tượng kiểm thử. Kiểm thử Playlist/Favorites/History thực tế sẽ được bổ sung khi Phase 4 tạo các API tương ứng.

#### 5. Test Matrix

| Test Case | Expected Result |
|---|---|
| Register hợp lệ | PASS |
| Register email trùng | 409 hoặc theo contract |
| Register dữ liệu sai | 400 |
| Login hợp lệ | 200 |
| Login sai password | 401 |
| Login sai email | 401 |
| Access không token | 401 |
| Access JWT sai | 401 |
| Access JWT hết hạn | 401 |
| Refresh hợp lệ | Cấp token mới |
| Refresh token cũ | Bị từ chối |
| Refresh token bị thu hồi | Bị từ chối |
| Logout | Session bị thu hồi |
| Get Profile | 200 |
| Update Profile | 200 |
| Change Password sai current password | Bị từ chối |
| User A truy cập Profile B | Bị từ chối |
| Google token sai audience | Bị từ chối |
| Google token hết hạn | Bị từ chối |

### DONE

```text
[ ] Postman Collection đầy đủ
[ ] Environment Template có sẵn
[ ] Không chứa secret thật
[ ] Register/Login hoạt động
[ ] Refresh/Logout hoạt động
[ ] Profile hoạt động
[ ] Change Password hoạt động
[ ] JWT Security Test PASS
[ ] Two-User Ownership Test PASS
[ ] Google Token Verification Test PASS hoặc có dependency ghi rõ
```

---

## TASK 3.9 — DOCUMENTATION & PHASE 3 REPORT

### 🎯 Mục tiêu

Ghi lại cách sử dụng Authentication API, cấu hình môi trường và kết quả kiểm thử.

Tạo:

```text
docs/REPORT/PHASE-3-AUTH-SECURITY.md
```

Tài liệu cấu hình:

```text
backend/.env.example
postman/WaveBox-Auth.postman_collection.json
postman/WaveBox-Local.postman_environment.json.example
```

Cập nhật:

```text
docs/API_CONTRACT.md
```

chỉ khi có thay đổi đã được thống nhất và ghi nhận trong Decision Log. Không tự ý sửa contract đã chốt.

Báo cáo tối thiểu:

```markdown
# PHASE 3 — AUTHENTICATION & SECURITY REPORT

## 1. Environment
- Java
- Spring Boot
- PostgreSQL
- Security Dependencies

## 2. Spring Security
- SecurityFilterChain
- Stateless Configuration
- Public / Protected Endpoints

## 3. JWT
- Signing Algorithm
- Claims
- Token Expiration
- Validation Rules

## 4. Authentication APIs
- Register
- Login
- Refresh
- Logout

## 5. Refresh Session
- Database Schema
- Token Hashing
- Rotation
- Revocation

## 6. Profile & Password
- Get Profile
- Update Profile
- Change Password

## 7. Google Sign-In
- OAuth Configuration
- ID Token Verification
- Account Linking Policy

## 8. Validation & Error Handling

## 9. Postman Test Results

## 10. Security Test Results

## 11. Known Issues & Dependencies

## 12. Phase 3 Acceptance
- Completed Tasks
- Pending Tasks
- Final Status
```

Báo cáo phải ghi kết quả thực tế, không ghi PASS khi chưa chạy test.

### DONE

```text
[ ] PHASE-3-AUTH-SECURITY.md tồn tại
[ ] API Contract được cập nhật nếu có thay đổi
[ ] Decision Log được cập nhật
[ ] Postman Collection hoạt động
[ ] Environment Template đầy đủ
[ ] Không lộ credentials
[ ] Kết quả test có bằng chứng
```

---

# 5. PHASE 3 FINAL REVIEW

## 🎯 Mục tiêu

Kiểm tra H05–H09 trước khi bàn giao Authentication API cho Phase 4 và Phase 5.

### DONE Checklist

```text
[ ] TASK 3.1 — Spring Security được cấu hình
[ ] SecurityFilterChain hoạt động
[ ] Stateless Authentication
[ ] Không sử dụng Roles
[ ] Public / Protected Endpoints đúng contract

[ ] TASK 3.2 — JWT Access Token
[ ] JWT được ký và xác minh đúng
[ ] JWT Expiration hoạt động
[ ] JWT chứa User UUID
[ ] JWT Secret không hardcode

[ ] TASK 3.3 — Register / Login
[ ] Register hoạt động
[ ] Login hoạt động
[ ] Duplicate Email bị từ chối
[ ] BCrypt được sử dụng
[ ] Access Token được cấp
[ ] Refresh Token được cấp

[ ] TASK 3.4 — Refresh / Logout
[ ] Refresh Session được lưu
[ ] Refresh Token lưu dạng hash
[ ] Rotation hoạt động
[ ] Token cũ không sử dụng lại được
[ ] Logout thu hồi đúng session
[ ] Reuse Detection được kiểm tra

[ ] TASK 3.5 — Profile & Change Password
[ ] Get Profile hoạt động
[ ] Update Profile hoạt động
[ ] Change Password hoạt động
[ ] Không chỉnh sửa được dữ liệu nhạy cảm ngoài phạm vi
[ ] Không truy cập dữ liệu User khác

[ ] TASK 3.6 — Google Sign-In
[ ] Google ID Token Verification được triển khai
[ ] Signature được xác minh
[ ] Audience được kiểm tra
[ ] Issuer được kiểm tra
[ ] Expiration được kiểm tra
[ ] Google Account Linking đúng policy
[ ] WaveBox JWT được cấp sau Google Sign-In

[ ] TASK 3.7 — Validation & Error Handling
[ ] Request Validation hoạt động
[ ] Global Exception Handler hoạt động
[ ] HTTP Status đúng
[ ] Error Response đúng contract
[ ] Không lộ thông tin nhạy cảm

[ ] TASK 3.8 — Postman
[ ] Collection đầy đủ
[ ] Register/Login Test PASS
[ ] Refresh/Logout Test PASS
[ ] JWT Security Test PASS
[ ] Two-User Ownership Test PASS
[ ] Google Verification Test PASS hoặc DEPENDENCY rõ ràng

[ ] TASK 3.9 — Documentation
[ ] Phase 3 Report hoàn chỉnh
[ ] API Contract đồng bộ
[ ] Decision Log cập nhật
[ ] Environment Template đầy đủ

[ ] Git status đã được kiểm tra
[ ] Không có thay đổi ngoài phạm vi
[ ] Không ảnh hưởng Phase 2
[ ] Không sửa Flutter source
```

---

# 6. ĐIỀU KIỆN PHASE 3 DONE

Chỉ được đánh dấu hoàn thành khi có bằng chứng:

**1. Authentication**

```text
Register: PASS
Login: PASS
Refresh: PASS
Logout: PASS
```

**2. JWT Security**

```text
Valid JWT: ACCEPTED
Invalid JWT: REJECTED
Expired JWT: REJECTED
Invalid Signature: REJECTED
Protected API Without Token: REJECTED
```

**3. User Ownership**

```text
User A → Access Own Data: ALLOWED
User A → Access User B Data: DENIED
User B → Access Own Data: ALLOWED
```

**4. Refresh Session**

```text
Refresh Token Hash: STORED
Refresh Rotation: PASS
Old Token Reuse: REJECTED
Revoked Token: REJECTED
Logout: REVOKED
```

**5. Profile & Password**

```text
Get Profile: PASS
Update Profile: PASS
Change Password: PASS
Password Hashing: BCrypt
```

**6. Google Sign-In**

```text
Google Token Verification: PASS
Audience Validation: PASS
Issuer Validation: PASS
Expiration Validation: PASS
WaveBox JWT Issuance: PASS
```

Nếu chưa có OAuth Client ID hoặc cấu hình Google hợp lệ:

```text
Google Implementation: COMPLETED
Google Real Integration Test: BLOCKED
Dependency: GOOGLE_OAUTH_CONFIGURATION
```

Không được ghi Google Sign-In PASS toàn bộ chỉ vì đã viết xong code.

**7. Deliverables**

```text
docs/REPORT/PHASE-3-AUTH-SECURITY.md
postman/WaveBox-Auth.postman_collection.json
postman/WaveBox-Local.postman_environment.json.example
```

Nếu có phần chưa kiểm thử được, phải ghi rõ:

```text
[PASS]
[FAILED]
[NOT TESTED]
[BLOCKED]
```

Không tuyên bố Phase 3 DONE khi còn lỗi bảo mật nghiêm trọng hoặc API xác thực chưa hoạt động.

---

# 7. STOP RULE

Sau khi hoàn thành Phase 3:

**DỪNG.**

Không tự chuyển sang xây dựng Music Data API.

Không tự triển khai:

```text
Songs
Albums
Artists
Genres
Search
Streaming
Playlists
Favorites
History
Batch Sync
```

Không tự tích hợp các màn hình Login/Register/Profile vào Flutter.

Chỉ khi người dùng xác nhận:

```text
PHASE 3 DONE
```

mới chuyển sang:

```text
PHASE 4 — BACKEND MUSIC DATA
```

---

# 8. TỔNG KẾT CẤU TRÚC PHASE 3

```text
PHASE 3 — AUTHENTICATION & SECURITY
│
├── TASK 3.1
│   └── Spring Security Configuration (H05)
│
├── TASK 3.2
│   └── JWT Access Token (H05)
│
├── TASK 3.3
│   └── Register & Login (H06)
│
├── TASK 3.4
│   └── Refresh Token & Logout (H06)
│
├── TASK 3.5
│   └── Profile & Change Password (H07)
│
├── TASK 3.6
│   └── Google Sign-In (H08)
│
├── TASK 3.7
│   └── Validation & Error Handling (H09)
│
├── TASK 3.8
│   └── Postman & Authentication Testing (H09)
│
├── TASK 3.9
│   └── Documentation & Report
│
└── TASK 3.10
    └── Final Review & Stop
```

---

# 9. THỨ TỰ THỰC THI

```text
READ PHASE 1 & PHASE 2 DOCUMENTS
              ↓
AUDIT EXISTING AUTHENTICATION CODE
              ↓
CONFIGURE SPRING SECURITY
              ↓
IMPLEMENT JWT SERVICE
              ↓
IMPLEMENT JWT FILTER
              ↓
IMPLEMENT REGISTER / LOGIN
              ↓
IMPLEMENT REFRESH SESSION
              ↓
IMPLEMENT REFRESH / LOGOUT
              ↓
IMPLEMENT PROFILE / CHANGE PASSWORD
              ↓
IMPLEMENT GOOGLE SIGN-IN
              ↓
IMPLEMENT VALIDATION / ERROR HANDLER
              ↓
CREATE POSTMAN COLLECTION
              ↓
RUN AUTHENTICATION & SECURITY TESTS
              ↓
WRITE PHASE 3 REPORT
              ↓
FINAL REVIEW
              ↓
PHASE 3 DONE
              ↓
STOP
```

---

## NGUYÊN TẮC QUAN TRỌNG NHẤT

Phase 3 là giai đoạn xây dựng **lớp xác thực và bảo mật cho toàn bộ Backend WaveBox**.

Backend phải xác định chính xác User đang đăng nhập, kiểm tra JWT trong mỗi request được bảo vệ, quản lý Refresh Session an toàn và bảo đảm người dùng chỉ truy cập dữ liệu thuộc tài khoản của mình.

**Một User Model duy nhất, không có roles; một cơ chế JWT thống nhất; Refresh Token có rotation và revocation; Google ID Token được xác minh tại Backend.**

Đây là nền tảng để Phase 4 xây dựng Music Data API an toàn và Phase 5 tích hợp Authentication vào Flutter mà không phải viết lại cơ chế bảo mật.