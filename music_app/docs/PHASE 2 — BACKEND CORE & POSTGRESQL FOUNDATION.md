# PHASE 2 — BACKEND CORE & POSTGRESQL FOUNDATION

## 🎯 Mục tiêu Phase 2

Xây dựng nền tảng Backend cho WaveBox bằng Spring Boot Java 17 và PostgreSQL, tạo cơ sở để Phase 3 triển khai Authentication và Phase 4 triển khai Music Data API.

Phase 2 tập trung hoàn thiện:

```text
PHASE 1 ARCHITECTURE & API CONTRACT
              ↓
Initialize Spring Boot
              ↓
Configure Environment
              ↓
Connect PostgreSQL
              ↓
Setup Flyway Migration
              ↓
Create Core User Schema
              ↓
Implement Entity / DTO / Repository / Service
              ↓
Configure BCrypt Password Encoder
              ↓
Implement Health Check
              ↓
Test Database & Persistence
              ↓
PHASE 2 DONE
```

**Phạm vi requirement:**

```text
H02 — Khởi tạo Spring Boot
H03 — PostgreSQL Schema & Flyway Migration
H04 — Entity, DTO, Repository, Service & BCrypt
```

Đầu ra Phase 2 là Backend Core có thể khởi động, kết nối PostgreSQL, tự động quản lý schema bằng Flyway và lưu/truy vấn User an toàn.

Phase 2 **được phép tạo và sửa code Backend**, nhưng không triển khai các tính năng thuộc Phase 3–8.

---

## 1. NGUYÊN TẮC TRIỂN KHAI

### 1.1 — Phase 1 Source of Truth Rule

Trước khi code, bắt buộc đọc các tài liệu Phase 1:

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/IMPLEMENTATION_ROADMAP.md
```

Sử dụng các tài liệu này làm căn cứ cho:

```text
Java / Spring Boot Version
Project Structure
Database Naming Convention
User Data Model
UUID Strategy
Database Architecture
Environment Configuration
Password Policy
API Convention
```

Không tự ý thay đổi quyết định kiến trúc đã chốt ở Phase 1.

Nếu tài liệu Phase 1 chưa có quyết định cần thiết, ghi nhận:

```text
[BLOCKED — ARCHITECTURE DECISION REQUIRED]
```

Chỉ chọn phương án mặc định khi không làm thay đổi contract hoặc kiến trúc đã thống nhất. Ghi quyết định bổ sung vào Decision Log.

### 1.2 — Existing Source First

Trước khi khởi tạo Backend mới, phải kiểm tra toàn bộ repository hiện tại.

Tối thiểu:

```text
pom.xml / build.gradle
settings.gradle (nếu có)
src/main/java/
src/main/resources/
src/test/java/
application.yml
application.properties
Dockerfile (nếu có)
docker-compose.yml (nếu có)
.gitignore
```

Xác định:

```text
[EXISTING]       File hoặc module đã tồn tại
[IMPLEMENTED]   Đã triển khai và hoạt động
[PARTIAL]       Mới triển khai một phần
[MISSING]       Chưa có
[BUG]           Có lỗi
[DEPENDENCY]    Phụ thuộc chưa đáp ứng
[CONFLICT]      Không thống nhất với Phase 1
[OUT OF SCOPE]  Không thuộc Phase 2
```

Nếu Backend đã tồn tại, phải tái sử dụng và mở rộng cấu trúc phù hợp.

Nếu chưa có Backend, mới được khởi tạo Spring Boot project.

**Không tạo một Backend thứ hai nếu project đã có Backend phù hợp.**

### 1.3 — Safe Modification Rule

Được phép đọc, tạo và chỉnh sửa source code Backend để hoàn thành H02–H04.

Tuy nhiên, bắt buộc tuân thủ:

```text
✅ Đọc source trước khi sửa
✅ Kiểm tra Git status
✅ Tái sử dụng code có sẵn
✅ Chỉ sửa các thành phần thuộc Phase 2
✅ Tạo migration mới theo thứ tự
✅ Giữ tương thích với dữ liệu hiện có
✅ Kiểm tra ảnh hưởng của mỗi thay đổi

❌ Không xóa file hoặc thư mục
❌ Không xóa class, method hoặc feature hiện có
❌ Không rewrite toàn bộ project khi không cần thiết
❌ Không xóa migration cũ
❌ Không sửa migration đã được áp dụng
❌ Không DROP DATABASE / DROP TABLE
❌ Không TRUNCATE dữ liệu
❌ Không xóa Docker volume
❌ Không reset database để né lỗi migration
❌ Không commit / push khi chưa được yêu cầu
```

Mọi thay đổi schema phải được thực hiện bằng Flyway migration mới, theo nguyên tắc additive và backward-compatible.

### 1.4 — Scope Separation Rule

Phase 2 chỉ xây dựng nền tảng dữ liệu và lớp xử lý User.

Không triển khai tính năng của Phase khác:

```text
PHASE 3:
JWT
Spring Security Authentication
Register / Login
Refresh Token
Logout
Profile API
Change Password API
Google Sign-In
Validation & Authentication Error Handling

PHASE 4:
Songs
Albums
Artists
Genres
Playlists
Playlist Songs
Favorites
History
Search API
Streaming
Batch Sync
```

Không tạo các module nghiệp vụ trên chỉ để làm trước Phase sau.

Được phép chuẩn bị schema hoặc dependency nền tảng khi Phase 1 đã xác định rõ cần thiết, nhưng phải giữ logic nghiệp vụ của chúng đúng phase được phân công.

### 1.5 — No Hardcoded Secret

Không hardcode thông tin nhạy cảm:

```text
Database Password
JWT Secret
Google Client Secret
Production Credentials
API Keys
```

Cấu hình thông qua environment variables.

Không đưa file `.env` chứa secret thực tế lên Git.

---

## 2. ĐIỀU KIỆN BẮT ĐẦU

Phase 2 được phép bắt đầu khi:

```text
Phase 1 đã được xác nhận DONE
              +
Backend repository đã được xác định
              +
Java 17 environment sẵn sàng
              +
PostgreSQL có thể khởi chạy
              +
API_CONTRACT.md đã có
              +
User Model đã được chốt
```

Nếu thiếu Backend, được phép khởi tạo mới.

Nếu PostgreSQL chưa cài đặt, có thể sử dụng Docker Compose nếu môi trường hỗ trợ.

Nếu thiếu thông tin cấu hình production, tiếp tục với cấu hình development an toàn và ghi nhận dependency.

Không tự ý sử dụng thông tin đăng nhập production giả định.

### Kiểm tra môi trường

```bash
java -version
```

```bash
mvn -version
```

Nếu project sử dụng Gradle thì kiểm tra Gradle Wrapper thay vì cài thêm Maven.

Kiểm tra PostgreSQL:

```bash
psql --version
```

Kiểm tra Git:

```bash
git status --short
```

Không chuyển sang Phase 3 chỉ vì Backend đã khởi động được.

---

## 3. PHẠM VI PHASE 2

### CHỈ LÀM

```text
H02 — Spring Boot Initialization
H03 — PostgreSQL Schema & Flyway
H04 — Entity / DTO / Repository / Service / BCrypt

Environment Configuration
Database Connection
Core User Persistence
Health Check
Base Error Handling
Backend Unit & Integration Tests
Run Documentation
```

### KHÔNG ĐƯỢC LÀM

```text
JWT Authentication
Register / Login API
Refresh Token API
Logout API
Google Sign-In
Profile API
Password Change API
Spring Security Authorization Rules
Music Catalog API
Search API
Streaming API
Playlist CRUD
Favorites API
History API
Batch Synchronization
Flutter Integration
Player / Download Changes
```

---

# 4. CÁC TASK THỰC HIỆN

## TASK 2.1 — INITIALIZE SPRING BOOT (H02)

### 🎯 Mục tiêu

Tạo nền tảng Spring Boot Java 17 có cấu trúc rõ ràng, chạy độc lập và có thể mở rộng cho các phase tiếp theo.

### Cách làm

#### 1. Kiểm tra project hiện tại

Nếu Backend đã có:

- Giữ nguyên Maven hoặc Gradle đang sử dụng.
- Kiểm tra Java version và Spring Boot version.
- Kiểm tra dependency hiện có.
- Kiểm tra cấu trúc package.
- Chỉ bổ sung thành phần còn thiếu.

Nếu Backend chưa có:

Khởi tạo Spring Boot project theo quyết định Phase 1.

Cấu hình cơ bản:

```text
Java: 17
Framework: Spring Boot
Build Tool: Theo kiến trúc đã chốt ở Phase 1
Packaging: JAR
Database: PostgreSQL
ORM: Spring Data JPA / Hibernate
Migration: Flyway
```

Không tự nâng cấp Spring Boot hoặc thay đổi Java version khi không có lý do tương thích rõ ràng.

#### 2. Dependencies

Tối thiểu cần các dependency tương ứng:

```text
Spring Boot Starter Web
Spring Boot Starter Data JPA
PostgreSQL Driver
Flyway Core
Flyway PostgreSQL Support
Spring Boot Actuator
Spring Security Crypto
Spring Boot Starter Test
```

Lưu ý:

- Chỉ thêm dependency chưa có.
- Sử dụng phiên bản tương thích với Spring Boot đã chọn.
- Nếu project đã quản lý dependency bằng BOM thì không tự pin phiên bản không cần thiết.
- Không thêm `spring-boot-starter-security` chỉ để sử dụng BCrypt nếu việc đó làm bật cơ chế bảo vệ mặc định trước Phase 3.
- Không thêm thư viện không có nhu cầu trong Phase 2.

#### 3. Package Structure

Ưu tiên cấu trúc phân tầng rõ ràng:

```text
src/main/java/
└── com/wavebox/
    ├── WaveBoxApplication.java
    │
    ├── config/
    │   └── PasswordConfig.java
    │
    ├── common/
    │   ├── exception/
    │   └── response/
    │
    ├── health/
    │
    └── features/
        └── user/
            ├── entity/
            ├── dto/
            ├── repository/
            └── service/

src/main/resources/
├── application.yml
├── application-local.yml
├── application-test.yml
└── db/
    └── migration/

src/test/java/
└── com/wavebox/
```

Đây là cấu trúc tham khảo. Nếu project đã có package convention khác thì phải giữ convention hiện tại và tổ chức tương ứng.

Không tạo sẵn hàng loạt package rỗng cho tất cả tính năng của Phase 3–8.

#### 4. Application Entry Point

Đảm bảo có Spring Boot main class:

```java
@SpringBootApplication
public class WaveBoxApplication {

    public static void main(String[] args) {
        SpringApplication.run(WaveBoxApplication.class, args);
    }
}
```

Kiểm tra:

```bash
mvn clean package
```

Hoặc lệnh Gradle tương ứng với project.

### DONE

```text
[ ] Project sử dụng Java 17
[ ] Spring Boot khởi động được
[ ] Maven / Gradle build thành công
[ ] Dependency tương thích
[ ] Package structure rõ ràng
[ ] Không tạo Backend trùng lặp
[ ] Không làm hỏng source code hiện có
```

---

## TASK 2.2 — CONFIGURE ENVIRONMENT & POSTGRESQL

### 🎯 Mục tiêu

Cấu hình các môi trường chạy Backend và kết nối PostgreSQL ổn định.

### Cách làm

#### 1. Cấu hình Environment

Tổ chức configuration theo môi trường:

```text
application.yml
application-local.yml
application-test.yml
```

Không bắt buộc tạo đầy đủ file nếu project đã có cấu hình tương đương.

Sử dụng các biến môi trường:

```text
DB_HOST
DB_PORT
DB_NAME
DB_USERNAME
DB_PASSWORD
```

Cấu hình datasource:

```yaml
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL}
    username: ${SPRING_DATASOURCE_USERNAME}
    password: ${SPRING_DATASOURCE_PASSWORD}
    driver-class-name: org.postgresql.Driver
```

Tên biến môi trường phải thống nhất giữa:

```text
application.yml
.env.example
docker-compose.yml
README.md
```

Có thể sử dụng các biến:

```text
SPRING_DATASOURCE_URL
SPRING_DATASOURCE_USERNAME
SPRING_DATASOURCE_PASSWORD
```

Không đặt username/password thực tế vào source code.

#### 2. PostgreSQL Configuration

Cấu hình:

```text
Database Name: Theo Phase 1
Schema: Theo Phase 1
Encoding: UTF-8
Timezone: UTC
Connection Pool: HikariCP
```

Yêu cầu:

- Backend kết nối được PostgreSQL.
- Có connection pool.
- Có cấu hình timeout phù hợp.
- Có xử lý trường hợp database chưa khả dụng.
- Không kết nối bằng tài khoản PostgreSQL superuser trong ứng dụng production nếu không cần thiết.

#### 3. Docker Compose

Nếu project chưa có môi trường PostgreSQL thuận tiện, tạo hoặc bổ sung `docker-compose.yml`.

Yêu cầu:

```text
PostgreSQL Service
Persistent Volume
Environment Variables
Port Mapping
Health Check
```

Quy tắc:

- Không ghi password thật vào file được commit.
- Có thể sử dụng `.env.example` làm mẫu cấu hình.
- Không xóa volume hoặc dữ liệu database hiện tại.
- Không ghi đè Docker Compose đang sử dụng nếu chưa phân tích ảnh hưởng.

#### 4. Persistence Configuration

Flyway là công cụ quản lý schema.

Hibernate không được tự ý tạo hoặc sửa schema.

Cấu hình mục tiêu:

```yaml
spring:
  jpa:
    hibernate:
      ddl-auto: validate
    open-in-view: false

  flyway:
    enabled: true
```

Không sử dụng:

```text
ddl-auto: create
ddl-auto: create-drop
ddl-auto: update
```

trong môi trường dùng chung hoặc production.

### DONE

```text
[ ] PostgreSQL khởi chạy được
[ ] Database được xác định đúng
[ ] Backend kết nối PostgreSQL thành công
[ ] Không hardcode credentials
[ ] Environment variables hoạt động
[ ] Persistent volume được bảo toàn
[ ] Hibernate không tự thay đổi schema
[ ] Database connection được kiểm tra thành công
```

---

## TASK 2.3 — POSTGRESQL SCHEMA & FLYWAY MIGRATION (H03)

### 🎯 Mục tiêu

Tạo database schema có version control bằng Flyway, bảo đảm quá trình nâng cấp database có thể kiểm soát và không làm mất dữ liệu.

### Cách làm

#### 1. Xác định Database Schema

Đối chiếu:

```text
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/REPORT/PHASE-1-ARCHITECTURE.md
```

Tạo schema User theo đúng User Model đã chốt.

Mô hình phải đáp ứng:

```text
User
 ├── UUID Primary Key
 ├── Email / Login Identifier
 ├── Password Hash
 ├── Profile Fields (theo contract)
 ├── Timestamps
 └── Other Fields (nếu Phase 1 yêu cầu)
```

Không tự thêm các trường không có căn cứ.

Quy tắc:

- `id` sử dụng PostgreSQL UUID.
- Email có unique constraint phù hợp với quy tắc chuẩn hóa đã chốt.
- Password chỉ lưu password hash.
- Các trường bắt buộc phải có `NOT NULL`.
- Các trường tùy chọn phải cho phép `NULL` phù hợp với contract.
- Có index cho trường được dùng để tra cứu.
- Có timestamp để quản lý thời gian tạo và cập nhật.
- Không có cột `role` hoặc mô hình phân quyền nhiều role.
- Không lưu password plaintext.

Nếu Phase 1 đã yêu cầu bảng lưu refresh session/token phục vụ Phase 3 và phân công schema đó cho H03, chỉ tạo cấu trúc cần thiết theo Decision Log. Chưa triển khai luồng xử lý token ở Phase 2.

Không triển khai schema Music Catalog, Playlist, Favorites và History ở Phase 2. Các schema này thuộc AQ01 — Phase 4.

#### 2. UUID Strategy

Tuân thủ chiến lược UUID trong Phase 1.

Đối với User:

```text
User ID: UUID
ID Generation: Theo API Contract
```

Nếu Backend là nơi tạo User, Backend phải tạo UUID theo quy tắc thống nhất.

Không sử dụng:

```text
Auto Increment ID
Email as Primary Key
Username as Primary Key
SQLite Row ID
Timestamp as ID
```

làm định danh User thay thế UUID đã chốt.

#### 3. Flyway Migration

Migration directory:

```text
src/main/resources/db/migration/
```

Tên migration:

```text
V1__create_users_table.sql
V2__add_user_indexes.sql
```

Tên và số version thực tế phải dựa trên migration hiện có.

Nếu project đã có migration:

- Kiểm tra bảng `flyway_schema_history`.
- Kiểm tra version đã được áp dụng.
- Không sửa migration đã chạy.
- Tạo migration tiếp theo.
- Không reset lịch sử Flyway để né lỗi.

Ví dụ migration minh họa:

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);
```

Đây chỉ là ví dụ cấu trúc tối thiểu. Migration thực tế phải dùng đầy đủ các trường đã chốt trong API Contract và kiến trúc dữ liệu Phase 1.

Nếu cần unique email không phân biệt chữ hoa/chữ thường, phải triển khai constraint/index theo đúng quy tắc chuẩn hóa email đã chốt; không tạo một index duy nhất mâu thuẫn với cách lưu email.

#### 4. Migration Safety

Bắt buộc:

```text
✅ Versioned migrations
✅ Additive schema changes
✅ Backward compatibility
✅ Foreign key constraints khi cần
✅ Unique constraints
✅ Indexes phù hợp
✅ NOT NULL đúng nghiệp vụ
✅ Migration history được giữ nguyên
```

Cấm:

```text
❌ DROP DATABASE
❌ DROP TABLE để tạo lại
❌ TRUNCATE
❌ Xóa dữ liệu hiện có
❌ Sửa migration đã áp dụng
❌ Reset Flyway history
❌ Tắt Flyway chỉ để ứng dụng chạy
```

Nếu migration thất bại, phải xác định nguyên nhân và tạo migration sửa chữa mới theo hướng an toàn; không xóa dữ liệu để chạy lại.

### DONE

```text
[ ] PostgreSQL Schema đúng thiết kế
[ ] User table tồn tại
[ ] UUID Primary Key hoạt động
[ ] Unique constraints hoạt động
[ ] Indexes được tạo đúng
[ ] Flyway nhận diện migration
[ ] Migration chạy thành công
[ ] flyway_schema_history được cập nhật
[ ] Hibernate validate thành công
[ ] Không mất dữ liệu hiện có
```

---

## TASK 2.4 — IMPLEMENT USER ENTITY / DTO / REPOSITORY / SERVICE & BCrypt (H04)

### 🎯 Mục tiêu

Xây dựng lớp xử lý dữ liệu User ở Backend để có thể tạo, lưu và truy vấn User một cách an toàn.

### 2.4.1 — User Entity

Tạo hoặc hoàn thiện:

```text
features/user/entity/User.java
```

Yêu cầu:

- Mapping đúng PostgreSQL `users` table.
- Primary key là UUID.
- Các trường khớp với API Contract.
- Không có `role` nếu kiến trúc Phase 1 đã chốt không sử dụng roles.
- Password field phải lưu hash.
- Không để Hibernate tự tạo schema.
- Không expose entity trực tiếp qua API.

Tên field Java sử dụng camelCase và tên column PostgreSQL theo convention đã chốt.

Không tạo thêm User Entity khác trong module authentication nếu không có kiến trúc phân tách rõ ràng.

### 2.4.2 — User DTO

Tạo DTO phục vụ lớp service và persistence theo nhu cầu thực tế.

Ví dụ:

```text
UserCreateRequest (nếu H04 cần)
UserResponse
UserProfileDto (nếu được chốt)
```

Quy tắc:

- Không trả `passwordHash` trong DTO response.
- Không trả thông tin nội bộ database.
- Không sử dụng Entity làm request body hoặc response body.
- Không tạo DTO trùng với DTO đã có.
- Các DTO Register/Login chính thức thuộc Phase 3, trừ khi cấu trúc đã được Phase 1 quy định rõ và Phase 2 chỉ tạo phần dùng chung.

### 2.4.3 — User Repository

Tạo:

```text
features/user/repository/UserRepository.java
```

Các thao tác tối thiểu:

```text
save()
findById()
findByEmail()
existsByEmail()
```

Phương thức thực tế phải phù hợp với yêu cầu truy vấn của service và API Contract.

Đảm bảo:

- Truy vấn theo UUID hoạt động.
- Kiểm tra email trùng hoạt động.
- Unique constraint của database vẫn là lớp bảo vệ cuối cùng.
- Không truy vấn User bằng dữ liệu định danh không đáng tin cậy.

### 2.4.4 — Password Encoder (BCrypt)

Tạo bean:

```text
config/PasswordConfig.java
```

Sử dụng:

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

Nếu project đã có `PasswordEncoder` bean tương đương, sử dụng lại và không tạo bean trùng lặp.

Yêu cầu:

```text
Raw Password
     ↓
BCryptPasswordEncoder
     ↓
Password Hash
     ↓
PostgreSQL
```

Quy tắc:

- Không lưu password dạng plaintext.
- Không log password.
- Không trả password hash qua DTO.
- Không sử dụng MD5 hoặc SHA-256 trực tiếp để thay thế password hashing.
- Không tự viết thuật toán BCrypt.
- Dùng `matches()` để kiểm tra mật khẩu khi cần.
- Salt được xử lý theo cơ chế của BCrypt.
- Không hash lại password nếu dữ liệu đã là hash mà không có yêu cầu nghiệp vụ.

Phase 2 chỉ xây dựng Password Encoder và khả năng mã hóa trong lớp service. Logic đăng ký, đăng nhập và xác thực thuộc Phase 3.

### 2.4.5 — User Service

Tạo:

```text
features/user/service/UserService.java
```

Nhiệm vụ:

- Tạo User theo dữ liệu hợp lệ.
- Chuẩn hóa identifier theo contract.
- Kiểm tra dữ liệu trùng.
- Mã hóa password trước khi lưu.
- Lưu User qua Repository.
- Truy vấn User theo UUID.
- Trả về DTO không chứa password hash.
- Sử dụng transaction phù hợp.

Ví dụ luồng tạo User nội bộ:

```text
Create User Request
       ↓
Normalize Input
       ↓
Check Duplicate Identifier
       ↓
Encode Password
       ↓
Create User Entity
       ↓
Save Through Repository
       ↓
Map To Response DTO
```

Không tạo API Register trong Phase 2.

Không cho phép service nhận và lưu password plaintext vào entity.

### 2.4.6 — Transaction & Data Integrity

Yêu cầu:

- Dùng `@Transactional` cho thao tác cần transaction.
- Có xử lý trường hợp email trùng.
- Không để trạng thái database không nhất quán.
- Không trả exception SQL thô ra bên ngoài.
- Không log dữ liệu nhạy cảm.
- Bảo đảm dữ liệu User được lưu đúng schema.

### DONE

```text
[ ] User Entity mapping chính xác
[ ] DTO không lộ password hash
[ ] UserRepository truy vấn được User
[ ] UserService tạo và lưu được User
[ ] UUID hoạt động đúng
[ ] Email uniqueness được bảo đảm
[ ] BCrypt encode hoạt động
[ ] BCrypt matches hoạt động
[ ] Không lưu plaintext password
[ ] Transaction hoạt động đúng
```

---

## TASK 2.5 — HEALTH CHECK & BASE ERROR HANDLING

### 🎯 Mục tiêu

Bảo đảm Backend có cơ chế kiểm tra trạng thái hoạt động và xử lý lỗi nền tảng.

### Cách làm

#### 1. Health Check

Sử dụng Spring Boot Actuator nếu phù hợp với project.

Endpoint mục tiêu:

```text
/actuator/health
```

Kiểm tra tối thiểu:

```text
Application Status
Database Connection Status
```

Ví dụ response:

```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP"
    }
  }
}
```

Response thực tế phụ thuộc cấu hình Actuator.

Quy tắc:

- Chỉ expose health information cần thiết.
- Không expose environment variables.
- Không expose database password.
- Không expose thông tin cấu hình nội bộ.
- Không trả stack trace ra health endpoint.
- Khi PostgreSQL không khả dụng, phải thể hiện trạng thái health phù hợp.

Nếu Phase 1 đã quy định đường dẫn health check khác, sử dụng contract đã chốt.

#### 2. Base Error Handling

Tạo hoặc hoàn thiện lớp xử lý exception nền tảng.

Có thể sử dụng:

```text
common/exception/
common/response/
```

Xử lý tối thiểu:

```text
Resource Not Found
Duplicate Data
Invalid Data
Database Constraint Violation
Unexpected Internal Error
```

Chú ý:

- Chỉ xây dựng cấu trúc nền tảng.
- Không triển khai toàn bộ Error Handler của Authentication và API nghiệp vụ.
- Không trả SQL statement, database credentials hoặc stack trace cho Client.
- Logging phải ghi đủ thông tin kỹ thuật cần thiết nhưng không ghi password hoặc token.

HTTP response chi tiết phải tuân thủ `docs/API_CONTRACT.md`.

### DONE

```text
[ ] Health endpoint hoạt động
[ ] Application health được kiểm tra
[ ] Database health được kiểm tra
[ ] Database unavailable được phát hiện
[ ] Không expose thông tin nhạy cảm
[ ] Base error response thống nhất
[ ] Exception không bị bỏ qua hoặc nuốt lỗi
```

---

## TASK 2.6 — TEST BACKEND CORE & POSTGRESQL

### 🎯 Mục tiêu

Kiểm chứng toàn bộ thành phần H02–H04 trên PostgreSQL thực tế, không chỉ kiểm tra bằng mock.

### Cách làm

#### 1. Build Test

```bash
mvn clean test
```

Hoặc Gradle Wrapper tương ứng.

#### 2. Application Startup Test

Kiểm tra:

```text
Spring Context
Application Startup
Configuration Loading
Dependency Injection
```

#### 3. Database Integration Test

Kiểm tra bằng PostgreSQL:

```text
Database Connection
Flyway Migration
User Table
Primary Key
Unique Constraint
Repository Save
Repository Find
Repository Update (nếu cần)
```

Ưu tiên integration test sử dụng PostgreSQL thật hoặc Testcontainers nếu project và môi trường hỗ trợ.

Không chỉ sử dụng H2 để thay thế toàn bộ kiểm thử PostgreSQL vì hành vi SQL, UUID và constraint có thể khác nhau.

#### 4. User Persistence Test

Kịch bản:

```text
1. Khởi tạo User hợp lệ
2. Mã hóa password bằng BCrypt
3. Lưu User
4. Truy vấn User theo UUID
5. Truy vấn User theo email
6. Kiểm tra dữ liệu trả về
7. Xác minh password hash
```

Kết quả cần xác minh:

```text
Raw Password != Stored Password
PasswordEncoder.matches(raw, hash) = true
```

#### 5. Duplicate User Test

Kịch bản:

```text
1. Tạo User với identifier hợp lệ
2. Lưu thành công
3. Tạo User thứ hai với identifier trùng
4. Database hoặc Service từ chối
5. Không tạo bản ghi trùng
```

#### 6. Migration Test

Kịch bản:

```text
1. Khởi động PostgreSQL
2. Khởi động Spring Boot
3. Flyway kiểm tra migration
4. Migration chạy
5. Schema được tạo
6. Hibernate validate
7. Application khởi động thành công
```

Phải kiểm tra trường hợp khởi động lại ứng dụng để bảo đảm migration cũ không chạy lại không cần thiết.

### DONE

| Test | Expected Result |
|---|---|
| Spring Boot Startup | PASS |
| PostgreSQL Connection | PASS |
| Flyway Migration | PASS |
| Hibernate Validation | PASS |
| User Save | PASS |
| User Query | PASS |
| UUID Mapping | PASS |
| Duplicate Constraint | PASS |
| BCrypt Encoding | PASS |
| BCrypt Matching | PASS |
| Health Check | PASS |

---

## TASK 2.7 — DOCUMENTATION & RUN INSTRUCTIONS

### 🎯 Mục tiêu

Bảo đảm Backend có hướng dẫn khởi chạy và cấu hình đầy đủ để có thể bàn giao cho Phase 3.

### Cách làm

Cập nhật hoặc tạo tài liệu:

```text
backend/README.md
backend/.env.example
```

Đường dẫn chính xác tùy theo cấu trúc repository thực tế.

README tối thiểu gồm:

```markdown
# WaveBox Backend

## 1. Requirements

## 2. Environment Variables

## 3. PostgreSQL Setup

## 4. Run With Docker Compose

## 5. Run Spring Boot

## 6. Flyway Migration

## 7. Health Check

## 8. Run Tests

## 9. Troubleshooting
```

Cung cấp lệnh chạy:

```bash
mvn spring-boot:run
```

Cung cấp lệnh kiểm tra:

```bash
mvn clean test
```

Cung cấp thông tin:

```text
Java Version
Spring Boot Version
Build Tool
Database Name
Database Port
Environment Variables
Health Endpoint
Migration Location
```

Không ghi password thật vào README.

### DONE

```text
[ ] README có hướng dẫn đầy đủ
[ ] Có .env.example nếu cần
[ ] Không lộ secret
[ ] Có lệnh khởi chạy
[ ] Có lệnh chạy test
[ ] Có hướng dẫn PostgreSQL
[ ] Có hướng dẫn migration
[ ] Có hướng dẫn Health Check
```

---

# 5. DELIVERABLES — ĐẦU RA BẮT BUỘC

## TASK 2.8 — PHASE 2 IMPLEMENTATION REPORT

Tạo:

```text
docs/REPORT/PHASE-2-BACKEND-CORE.md
```

Nội dung:

```markdown
# PHASE 2 — BACKEND CORE REPORT

## 1. Project Environment
- Java Version
- Spring Boot Version
- Maven / Gradle
- Dependencies

## 2. Project Structure
- Package Structure
- Existing Components
- New Components

## 3. PostgreSQL Configuration
- Database Connection
- Environment Variables
- Connection Pool

## 4. Flyway Migration
- Migration Files
- Applied Versions
- Schema Summary

## 5. User Data Model
- Entity
- DTO
- Repository
- Service

## 6. BCrypt
- Password Encoder
- Encoding Test
- Matching Test

## 7. Health Check
- Endpoint
- Database Health
- Application Health

## 8. Test Results
- Build
- Unit Tests
- Integration Tests
- Migration Tests

## 9. Issues & Dependencies
- Known Issues
- Unresolved Dependencies
- Limitations

## 10. Phase 2 Acceptance
- Completed Tasks
- Pending Tasks
- Final Status
```

Báo cáo phải ghi kết quả thực tế, không ghi PASS nếu chưa chạy kiểm thử.

---

# 6. PHASE 2 FINAL REVIEW

## 🎯 Mục tiêu

Kiểm tra toàn bộ H02–H04 trước khi bàn giao nền tảng cho Phase 3.

### DONE Checklist

```text
[ ] TASK 2.1 — Spring Boot được khởi tạo hoặc mở rộng đúng cách
[ ] Java 17 hoạt động
[ ] Maven / Gradle build thành công
[ ] Dependency tương thích
[ ] TASK 2.2 — Environment được cấu hình
[ ] PostgreSQL kết nối thành công
[ ] Credentials không bị hardcode
[ ] Hibernate ddl-auto được kiểm soát
[ ] TASK 2.3 — User Schema được tạo
[ ] Flyway migration chạy thành công
[ ] Migration history được giữ nguyên
[ ] UUID Primary Key hoạt động
[ ] Unique Constraint hoạt động
[ ] Không mất dữ liệu database
[ ] TASK 2.4 — User Entity hoàn chỉnh
[ ] DTO không để lộ password hash
[ ] User Repository hoạt động
[ ] User Service hoạt động
[ ] BCrypt Encoder hoạt động
[ ] Không lưu password plaintext
[ ] TASK 2.5 — Health Check hoạt động
[ ] Database Health được kiểm tra
[ ] Base Error Handling hoạt động
[ ] Không expose thông tin nhạy cảm
[ ] TASK 2.6 — Backend Tests PASS
[ ] PostgreSQL Integration Tests PASS
[ ] Flyway Migration Tests PASS
[ ] User Persistence Tests PASS
[ ] BCrypt Tests PASS
[ ] TASK 2.7 — README và Environment Template hoàn chỉnh
[ ] TASK 2.8 — Phase 2 Report hoàn chỉnh
[ ] Không triển khai chức năng ngoài Phase 2
[ ] Không làm thay đổi Flutter source
[ ] Kiểm tra Git status trước khi kết thúc
```

---

# 7. ĐIỀU KIỆN PHASE 2 DONE

Chỉ được đánh dấu hoàn thành khi có đủ bằng chứng:

**1. Backend**

```text
Spring Boot: RUNNING
Java 17: PASS
Build: PASS
```

**2. PostgreSQL**

```text
PostgreSQL: CONNECTED
Flyway: SUCCESS
Hibernate Validation: SUCCESS
```

**3. User Persistence**

```text
User Entity: READY
User Repository: PASS
User Service: PASS
User Save: PASS
User Query: PASS
UUID: PASS
```

**4. Password Security**

```text
BCrypt Bean: READY
BCrypt Encoding: PASS
BCrypt Matching: PASS
Plaintext Password Storage: NOT ALLOWED
```

**5. Health Check**

```text
Application Health: UP
Database Health: UP
Sensitive Information Exposure: NONE
```

**6. Documentation**

```text
docs/REPORT/PHASE-2-BACKEND-CORE.md
backend/README.md
```

Nếu một tiêu chí chưa thực hiện được, phải ghi rõ:

```text
[BLOCKED]
[FAILED]
[NOT TESTED]
```

Không được tuyên bố Phase 2 DONE chỉ vì ứng dụng khởi động thành công.

---

# 8. STOP RULE

Sau khi hoàn thành Phase 2:

**DỪNG.**

Không tự chuyển sang triển khai JWT hoặc Authentication API.

Không tự triển khai:

```text
Spring Security JWT
Register
Login
Refresh Token
Logout
Profile API
Google Sign-In
```

Chỉ khi người dùng xác nhận:

```text
PHASE 2 DONE
```

mới chuyển sang:

```text
PHASE 3 — AUTHENTICATION & SECURITY
```

---

# 9. TỔNG KẾT CẤU TRÚC PHASE 2

```text
PHASE 2 — BACKEND CORE & POSTGRESQL
│
├── TASK 2.1
│   └── Initialize Spring Boot (H02)
│
├── TASK 2.2
│   └── Configure Environment & PostgreSQL
│
├── TASK 2.3
│   └── PostgreSQL Schema & Flyway (H03)
│
├── TASK 2.4
│   └── User Entity / DTO / Repository
│       / Service / BCrypt (H04)
│
├── TASK 2.5
│   └── Health Check & Base Error Handling
│
├── TASK 2.6
│   └── Backend Core & PostgreSQL Tests
│
├── TASK 2.7
│   └── Documentation & Run Instructions
│
├── TASK 2.8
│   └── Phase 2 Implementation Report
│
└── TASK 2.9
    └── Final Review & Stop
```

---

# 10. THỨ TỰ THỰC THI

```text
READ PHASE 1 DOCUMENTS
          ↓
AUDIT EXISTING BACKEND
          ↓
CHECK JAVA & BUILD TOOL
          ↓
INITIALIZE SPRING BOOT
          ↓
CONFIGURE ENVIRONMENT
          ↓
CONNECT POSTGRESQL
          ↓
CREATE FLYWAY MIGRATIONS
          ↓
IMPLEMENT USER ENTITY
          ↓
IMPLEMENT DTO / REPOSITORY / SERVICE
          ↓
CONFIGURE BCrypt
          ↓
IMPLEMENT HEALTH CHECK
          ↓
RUN BUILD & INTEGRATION TESTS
          ↓
WRITE DOCUMENTATION
          ↓
WRITE PHASE 2 REPORT
          ↓
FINAL REVIEW
          ↓
PHASE 2 DONE
          ↓
STOP
```

---

## NGUYÊN TẮC QUAN TRỌNG NHẤT

Phase 2 là giai đoạn xây dựng **nền móng kỹ thuật của Backend**, không phải giai đoạn triển khai toàn bộ chức năng.

Kết quả cần đạt là một Spring Boot Backend có thể chạy ổn định, kết nối PostgreSQL, quản lý schema bằng Flyway và xử lý dữ liệu User an toàn.

**Không triển khai JWT, Login/Register hay Music API trong Phase 2.** Những chức năng đó sẽ được xây dựng trên nền tảng này ở các phase tiếp theo.