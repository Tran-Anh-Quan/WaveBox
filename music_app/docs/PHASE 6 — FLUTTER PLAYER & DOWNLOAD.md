# PHASE 6 — FLUTTER PLAYER & DOWNLOAD

## 🎯 Mục tiêu Phase 6

Hoàn thiện hệ thống phát nhạc, phát nhạc nền, điều khiển Playback, Download và Offline Playback của ứng dụng Flutter WaveBox.

Phase 6 tập trung cải thiện và thống nhất cơ chế Audio hiện có, bảo đảm người dùng có thể nghe nhạc liên tục khi chuyển màn hình, khóa màn hình hoặc sử dụng ứng dụng khác; đồng thời tải nhạc về thiết bị và phát lại khi không có Internet.

Phase 6 phải kế thừa source code hiện có, đặc biệt là `just_audio`, `audio_handler.dart`, `video_player` và các thành phần quản lý thư viện nhạc local.

Luồng thực hiện:

```text
PHASE 1–5 — ARCHITECTURE & API INTEGRATION
                   ↓
AUDIT EXISTING PLAYER ARCHITECTURE
                   ↓
SELECT ONE BACKGROUND AUDIO MECHANISM
                   ↓
INTEGRATE PLAYER & AUDIO SESSION
                   ↓
INTEGRATE NOTIFICATION & MEDIA SESSION
                   ↓
IMPLEMENT ARTWORK
                   ↓
IMPLEMENT VOLUME SLIDER
                   ↓
IMPLEMENT SONG FILE DETAILS
                   ↓
IMPLEMENT SAFE DOWNLOAD DELETION
                   ↓
IMPLEMENT SLEEP TIMER
                   ↓
IMPLEMENT DOWNLOAD SERVICE
                   ↓
IMPLEMENT OFFLINE PLAYBACK
                   ↓
VIDEO SEEK / FULLSCREEN (IF IN SCOPE)
                   ↓
PLAYER / DOWNLOAD TESTS
                   ↓
PHASE 6 DONE
```

**Phạm vi requirement:**

```text
AT01 — Select Background Audio Mechanism
AT02 — Notification & MediaSession
AT03 — Artwork
AT04 — Volume Slider
AT05 — Music File Details
AT06 — Safe Download Deletion
AT07 — Sleep Timer
AT08 — Download Service
AT09 — Offline Playback
AT10 — Player Tests
AT11 — Video Seekbar / Fullscreen (if in scope)
```

Đầu ra Phase 6 là hệ thống Player và Download hoạt động ổn định trên thiết bị thực tế, hỗ trợ phát nhạc foreground/background, điều khiển từ notification, hiển thị artwork, tải nhạc, xóa bản tải an toàn và phát lại nhạc khi offline.

Phase 6 **được phép tạo và sửa source code Flutter** trong phạm vi AT01–AT11.

Không triển khai lại Authentication, Music Catalog API hoặc cơ chế đồng bộ Local–Cloud đã thuộc các phase khác.

---

## 1. NGUYÊN TẮC TRIỂN KHAI

### 1.1 — Previous Phases Source of Truth Rule

Trước khi code, đọc:

```text
docs/REPORT/PHASE-1-ARCHITECTURE.md
docs/API_CONTRACT.md
docs/architecture/DECISION_LOG.md
docs/IMPLEMENTATION_ROADMAP.md
docs/REPORT/PHASE-5-FLUTTER-AUTH-API.md
```

Kiểm tra các thành phần Flutter hiện có:

```text
main.dart
SongRepository
AppDatabase
Audio Player Service
audio_handler.dart
just_audio
audio_service (nếu có)
video_player
file_picker
Download Service (nếu có)
Playback Queue
Player Screen
Mini Player
Notification / Media Session
```

Đây là các thành phần cần ưu tiên kiểm tra theo lịch sử source WaveBox. Không được mặc định tất cả vẫn tồn tại hoặc đang được cấu hình giống lần khảo sát trước.

Phải xác định:

- Player đang sử dụng engine nào.
- Có bao nhiêu instance Player.
- Cơ chế phát nhạc nền đang hoạt động như thế nào.
- Notification đang được quản lý ở đâu.
- Audio Session và Audio Focus đang xử lý thế nào.
- File nhạc được lưu ở đâu.
- Download có Service riêng hay đang nằm trong Repository.
- Metadata bài hát được lấy từ SQLite hay file metadata.
- Offline Playback đang sử dụng nguồn local nào.
- Video Player có còn thuộc phạm vi chức năng hay không.

### 1.2 — Single Playback Engine Rule

Chỉ chọn **một cơ chế phát nhạc chính thức** để quản lý Playback và Background Audio.

Mục tiêu:

```text
Player UI
    |
    v
Playback Controller
    |
    v
ONE Playback Engine
    |
    +---- Audio Source
    |
    +---- Playback Queue
    |
    +---- Audio Session
    |
    +---- Background Audio
    |
    +---- Notification / Media Session
```

Không để nhiều Player Service cùng quản lý một luồng nhạc, gây:

- Phát hai bài cùng lúc.
- Notification điều khiển nhầm Player.
- Playback State không đồng nhất.
- Queue bị tạo nhiều lần.
- Âm thanh không dừng khi chuyển bài.
- Lỗi khi ứng dụng chạy nền.

Có thể tiếp tục sử dụng `just_audio` kết hợp `audio_service` nếu audit và kiểm tra tương thích chứng minh đây là lựa chọn phù hợp.

Không mặc định phải thay toàn bộ thư viện hiện có.

### 1.3 — Preserve Existing Source Rule

**Không được xóa `audio_handler.dart` trước khi hoàn thành audit và lựa chọn cơ chế background audio chính thức.**

Bắt buộc:

```text
Read Existing Dependencies
        ↓
Trace Class References
        ↓
Trace Service Initialization
        ↓
Check Android Manifest
        ↓
Check Platform Configuration
        ↓
Select Canonical Audio Architecture
        ↓
Integrate / Migrate Safely
        ↓
Run Regression Tests
```

Nếu có nhiều cơ chế Player:

- Xác định class nào đang được gọi thực tế.
- Xác định class nào chỉ còn tồn tại nhưng không được sử dụng.
- Kiểm tra dependency của từng class.
- Kiểm tra notification và background service.
- Kiểm tra các màn hình đang gọi Player.
- Không xóa class hoặc file chỉ vì nó có vẻ trùng lặp.

Ưu tiên mở rộng hoặc chuyển đổi có kiểm soát thay vì xóa rồi viết lại toàn bộ.

### 1.4 — Local File Safety Rule

Phải phân biệt:

```text
USER IMPORTED MUSIC
    └── File nhạc gốc do người dùng chọn từ thiết bị

APP DOWNLOADED MUSIC
    └── File được WaveBox tải và quản lý

REMOTE MUSIC
    └── File được phát từ Backend / Media Storage
```

Quy tắc:

- Không xóa file gốc do người dùng nhập.
- Không xóa file nằm ngoài vùng lưu trữ Download do WaveBox quản lý.
- Chỉ xóa bản tải có metadata và nguồn quản lý xác định.
- Không xóa database hoặc toàn bộ SQLite khi xóa file.
- Không xóa một file nếu còn một bản ghi hoặc tính năng khác đang tham chiếu đến nó mà chưa xử lý quan hệ đó.
- Không dùng tên file hoặc đường dẫn không chuẩn hóa để quyết định quyền xóa.

### 1.5 — Download & Sync Separation Rule

Phải tách ba nghiệp vụ:

```text
DOWNLOAD
    └── Tải file audio về thiết bị

OFFLINE PLAYBACK
    └── Phát file đã có trên thiết bị

SYNCHRONIZATION
    └── Đồng bộ metadata và dữ liệu người dùng giữa Local / Cloud
```

Trong Phase 6:

```text
✅ Download Service
✅ Downloaded File Management
✅ Download Metadata
✅ Offline Audio Source
✅ Local Playback
✅ Safe File Deletion
```

Không triển khai lại:

```text
❌ Pending Sync Queue
❌ Batch Sync Retry Logic
❌ Cloud Restore
❌ Conflict Resolution
❌ Account Data Merge
❌ Full Local / Cloud Synchronization
```

Các chức năng đồng bộ thuộc Phase 7.

### 1.6 — Background & Platform Rule

Phải kiểm tra hoạt động thực tế trên nền tảng mục tiêu.

WaveBox ưu tiên Android theo định hướng dự án, nhưng nếu project có hỗ trợ iOS thì không được làm hỏng cấu hình iOS đang có.

Kiểm tra:

```text
AndroidManifest.xml
Android Permissions
Foreground Service Configuration
Notification Permission
Media Session
Audio Focus
Audio Session
Background Execution
App Lifecycle
```

Không mặc định rằng cấu hình chạy được trên Emulator đồng nghĩa sẽ chạy ổn định trên thiết bị thật.

Phải kiểm tra các trường hợp:

- Khóa màn hình.
- Chuyển sang ứng dụng khác.
- Mở notification shade.
- Cắm hoặc rút tai nghe.
- Có cuộc gọi đến.
- Ứng dụng mất quyền phát audio.
- Hệ điều hành dừng hoặc khởi động lại tiến trình.

Không yêu cầu giữ ứng dụng chạy nền bằng cách sử dụng cơ chế nền không phù hợp với chính sách hệ điều hành.

### 1.7 — Safe Modification Rule

Được phép:

```text
✅ Tạo hoặc mở rộng Playback Service
✅ Chọn và tích hợp Background Audio
✅ Tích hợp Notification / Media Session
✅ Hoàn thiện Artwork
✅ Hoàn thiện Volume Slider
✅ Tạo Song Detail / File Information
✅ Tạo Download Service
✅ Tạo Sleep Timer
✅ Tạo Local Audio Resolver
✅ Tích hợp Offline Playback
✅ Viết Player Tests
✅ Viết Download Tests
```

Không được:

```text
❌ Xóa file hoặc thư mục hiện có
❌ Xóa audio_handler.dart khi chưa audit
❌ Xóa Player hoặc Playback Queue đang hoạt động
❌ Xóa toàn bộ SQLite
❌ Xóa nhạc gốc của người dùng
❌ Xóa downloaded files hàng loạt để sửa lỗi
❌ Thay toàn bộ kiến trúc Flutter không cần thiết
❌ Sửa Backend Authentication
❌ Viết lại Music Catalog API
❌ Triển khai Full Synchronization của Phase 7
❌ Hardcode đường dẫn lưu trữ
❌ Commit / push khi chưa được yêu cầu
```

---

## 2. ĐIỀU KIỆN BẮT ĐẦU

Phase 6 được phép bắt đầu khi:

```text
PHASE 1 — ARCHITECTURE DONE
              +
PHASE 5 — FLUTTER API INTEGRATION DONE
              +
Flutter Source Code sẵn sàng
              +
Player hiện tại đã được audit
              +
Local Music Library đang hoạt động
              +
SQLite Database hoạt động
              +
Music Streaming API sẵn sàng (nếu dùng online audio)
```

Kiểm tra:

```bash
flutter --version
```

```bash
flutter doctor
```

```bash
flutter pub get
```

```bash
flutter analyze
```

Kiểm tra thiết bị:

```text
Android Emulator
Android Physical Device
iOS Device / Simulator (nếu thuộc phạm vi)
```

Kiểm tra Git:

```bash
git status --short
```

### Dependency cần ghi nhận

```text
[DEPENDENCY — BACKGROUND AUDIO CONFIGURATION]
[DEPENDENCY — ANDROID NOTIFICATION PERMISSION]
[DEPENDENCY — MEDIA STORAGE]
[DEPENDENCY — VALID AUDIO SOURCE]
[DEPENDENCY — ANDROID DEVICE TEST]
```

Nếu Backend Streaming chưa hoàn tất, vẫn có thể triển khai Playback và Download bằng file local hợp lệ. Tuy nhiên, không được đánh dấu online Download hoặc Streaming Integration PASS khi chưa kiểm thử được nguồn thực tế.

---

## 3. PHẠM VI PHASE 6

### CHỈ LÀM

```text
AT01 — Background Audio Architecture
AT02 — Notification & MediaSession
AT03 — Artwork
AT04 — Volume Slider
AT05 — Music File Details
AT06 — Safe Download Deletion
AT07 — Sleep Timer
AT08 — Download Service
AT09 — Offline Playback
AT10 — Player Tests
AT11 — Video Seekbar / Fullscreen nếu thuộc phạm vi
```

### KHÔNG ĐƯỢC LÀM

```text
JWT Authentication
Login / Register
Google Sign-In
Music Catalog API
Backend Audio Streaming Implementation
Full Offline Synchronization
Batch Sync Retry Queue
Cloud Restore
Conflict Resolution
Account Data Merge
Full E2E Acceptance
```

Không làm lại các tính năng đã hoàn thành ở Phase 5.

---

# 4. CÁC TASK THỰC HIỆN

## TASK 6.1 — AUDIT EXISTING PLAYER ARCHITECTURE

### 🎯 Mục tiêu

Xác định chính xác hệ thống Audio và Download hiện tại trước khi lựa chọn một cơ chế Background Audio chính thức.

### Cách làm

Đọc toàn bộ các thành phần:

```text
Player Screen
Mini Player
Playback Controller
Playback Queue
Audio Handler
Audio Service
just_audio
audio_service (nếu có)
Audio Session
video_player
SongRepository
AppDatabase
Download Service (nếu có)
```

Kiểm tra:

```text
File Path
Class / Method
Current Responsibility
Player Instance
Audio Engine
Background Capability
Notification Handling
Queue Management
Local Audio Source
Remote Audio Source
Download Source
Dependencies
```

Đặc biệt kiểm tra:

**Playback**

- Có bao nhiêu Player instance?
- Có một hay nhiều Audio Handler?
- State Playback được lưu ở đâu?
- Khi chuyển bài có tạo Player mới không?
- Khi đóng màn hình Player, nhạc có dừng không?
- Có lỗi phát hai bài cùng lúc không?

**Background**

- Có Background Service chưa?
- Có Notification chưa?
- Có Media Session chưa?
- Có điều khiển Play/Pause/Next/Previous?
- Có xử lý Audio Focus không?

**Local Audio**

- File được đọc trực tiếp từ thiết bị hay từ App Directory?
- Metadata được lấy từ SQLite hay file?
- Có Download Metadata chưa?
- Có phân biệt bản nhạc gốc và bản nhạc tải về không?

### DONE

Có bảng:

| Component | Existing State | Responsibility | Required Action |
|---|---|---|---|
| audio_handler.dart | EXISTING / MISSING | Theo source | AT01 |
| just_audio | EXISTING / MISSING | Audio Engine | AT01 |
| audio_service | EXISTING / MISSING | Background | AT01 |
| Player Screen | EXISTING / PARTIAL | UI | AT02–AT04 |
| Download Service | EXISTING / PARTIAL | Download | AT08 |
| AppDatabase | EXISTING | Local Metadata | AT05–AT09 |
| video_player | EXISTING / MISSING | Video Playback | AT11 |

Không xóa hoặc thay đổi file chỉ để hoàn thành bước audit.

---

## TASK 6.2 — SELECT ONE BACKGROUND AUDIO MECHANISM (AT01)

### 🎯 Mục tiêu

Chốt và triển khai một kiến trúc Player thống nhất để quản lý phát nhạc foreground và background.

### Cách làm

#### 1. Evaluate Existing Architecture

Đánh giá các tiêu chí:

```text
Playback Stability
Background Playback
Notification Integration
Media Session
Audio Focus
Queue Management
Seek / Position
Platform Compatibility
Existing Dependency Compatibility
Maintenance Complexity
```

Có thể lựa chọn:

```text
OPTION A:
just_audio
+ audio_service

OPTION B:
Cơ chế Audio hiện tại nếu đã ổn định và đáp ứng đầy đủ requirement

OPTION C:
Một kiến trúc khác đã được kiểm tra tương thích
```

Không chọn thư viện chỉ vì mới hơn hoặc có nhiều tính năng hơn.

Phải chứng minh lựa chọn phù hợp với kiến trúc source hiện tại.

#### 2. Select Canonical Playback Engine

Sau khi lựa chọn, chỉ định rõ:

```text
Main Playback Engine
Main Playback Controller
Audio Handler (nếu cần)
Audio Session Owner
Queue Owner
Playback State Source
```

Không để Player UI, Download Service hoặc các Widget tự tạo nhiều Player độc lập để phát cùng một nội dung.

#### 3. Playback State

Chuẩn hóa trạng thái:

```text
IDLE
LOADING
READY
PLAYING
PAUSED
BUFFERING
COMPLETED
ERROR
```

Quản lý:

```text
Current Song
Current Source
Playback Position
Duration
Buffered Position
Playing State
Repeat Mode
Shuffle Mode
Queue
Playback Error
```

Các màn hình phải lấy dữ liệu từ cùng một Playback State.

#### 4. Queue Management

Đảm bảo:

- Play Song.
- Pause.
- Resume.
- Next.
- Previous.
- Seek.
- Shuffle nếu đã có yêu cầu.
- Repeat nếu đã có yêu cầu.
- Không tạo Queue trùng.
- Chuyển bài không tạo Player instance mới không cần thiết.

#### 5. Audio Lifecycle

Xử lý:

- App vào background.
- App trở về foreground.
- Khóa màn hình.
- Tạm dừng khi hệ điều hành yêu cầu.
- Tiếp tục khi Audio Focus được cấp lại.
- Mất nguồn audio.
- File không tồn tại.
- Network source thất bại.

#### 6. Migration Safety

Nếu thay đổi cơ chế Player:

```text
Audit Dependencies
       ↓
Select New Canonical Engine
       ↓
Integrate Existing UI
       ↓
Preserve Existing Behavior
       ↓
Run Regression Tests
       ↓
Confirm Stable
```

Chỉ gỡ dependency hoặc code không còn sử dụng sau khi xác minh tất cả nơi tham chiếu và kiểm thử thành công.

Không xóa `audio_handler.dart` chỉ vì đã tạo class Player mới.

### DONE

```text
[ ] Đã audit các Player Engine hiện có
[ ] Chỉ chọn một Playback Engine chính
[ ] Không có hai Player cùng phát
[ ] Playback State thống nhất
[ ] Queue hoạt động đúng
[ ] Play / Pause / Next / Previous hoạt động
[ ] Seek hoạt động
[ ] Background Playback hoạt động
[ ] Audio Lifecycle được xử lý
[ ] Không xóa dependency khi chưa xác minh
```

---

## TASK 6.3 — NOTIFICATION & MEDIA SESSION (AT02)

### 🎯 Mục tiêu

Cho phép người dùng điều khiển nhạc từ notification và các giao diện điều khiển media của hệ điều hành.

### Cách làm

#### 1. Notification Integration

Notification phải hiển thị:

```text
Song Title
Artist
Artwork
Playback State
Playback Controls
```

Các thao tác:

```text
PLAY
PAUSE
NEXT
PREVIOUS
```

Có thể bổ sung:

```text
STOP
```

nếu kiến trúc và requirement yêu cầu.

#### 2. Media Session

Tích hợp với Media Session theo cơ chế Background Audio đã chọn.

Yêu cầu:

- Metadata đúng bài hát đang phát.
- Playback State đồng nhất với Player.
- Play/Pause điều khiển đúng Player.
- Next/Previous điều khiển Queue hiện tại.
- Seek cập nhật đúng vị trí.
- Notification không tồn tại nhiều bản trùng lặp.
- Notification cập nhật khi chuyển bài.

#### 3. Android Configuration

Kiểm tra:

```text
AndroidManifest.xml
Foreground Service Permission
Media Playback Service Configuration
Notification Permission
Service Declaration
Notification Channel
```

Cấu hình theo phiên bản Android và dependency thực tế.

Không thêm permission không cần thiết.

Nếu ứng dụng hỗ trợ Android version có quy định riêng cho notification hoặc foreground service, phải kiểm tra cấu hình tương ứng.

#### 4. Notification Lifecycle

Kiểm tra:

```text
App Foreground
App Background
Screen Locked
Playback Paused
Playback Completed
Playback Error
Player Stopped
```

Khi dừng Playback, notification và media session phải được cập nhật hoặc đóng đúng trạng thái.

#### 5. Physical Device Test

Bắt buộc thử:

```text
Play
Lock Screen
Press Pause
Press Next
Press Previous
Unlock Device
Return to App
```

Không đánh dấu DONE chỉ dựa trên UI notification trong Emulator nếu thiết bị thật có sẵn để kiểm thử.

### DONE

```text
[ ] Notification hiển thị đúng
[ ] Song Title đúng
[ ] Artist đúng
[ ] Artwork đúng
[ ] Play/Pause hoạt động
[ ] Next/Previous hoạt động
[ ] Media Session hoạt động
[ ] Seek hoạt động nếu hỗ trợ
[ ] Không có Notification trùng
[ ] Background Playback ổn định
[ ] Physical Device Test PASS
```

---

## TASK 6.4 — ARTWORK MANAGEMENT (AT03)

### 🎯 Mục tiêu

Hiển thị artwork thống nhất cho Player, Mini Player, Playlist và Notification.

### Cách làm

#### 1. Artwork Sources

Hỗ trợ các nguồn phù hợp với dự án:

```text
Local Embedded Metadata
Local Artwork File
Backend Artwork URL
Cached Artwork
Fallback Artwork
```

Không giả định bài hát nào cũng có artwork.

#### 2. Artwork Resolution

Luồng:

```text
Current Song
     ↓
Resolve Artwork Source
     |
     +---- Local Embedded Artwork
     |
     +---- Local Artwork File
     |
     +---- Backend Artwork URL
     |
     +---- Cached Artwork
     |
     +---- Default Placeholder
```

Thứ tự ưu tiên phải thống nhất giữa Player và Notification.

Không gọi mạng liên tục khi Widget rebuild.

#### 3. Artwork Cache

Yêu cầu:

- Cache artwork phù hợp.
- Không tải lặp cùng một ảnh.
- Có giới hạn cache hoặc chính sách làm sạch phù hợp.
- Không làm tăng bộ nhớ vô hạn.
- Không sử dụng URL sai hoặc ảnh không hợp lệ.
- Khi artwork thay đổi, cache phải được cập nhật phù hợp.

#### 4. UI Integration

Artwork cần đồng nhất tại:

```text
Full Player Screen
Mini Player
Notification
Media Session
Song Detail
Playlist (nếu có)
```

Nếu không có artwork:

```text
Default Artwork Placeholder
```

Không hiển thị icon lỗi hoặc ảnh vỡ.

### DONE

```text
[ ] Local Artwork hoạt động
[ ] Remote Artwork hoạt động
[ ] Artwork Cache hoạt động
[ ] Notification Artwork đúng
[ ] Mini Player Artwork đúng
[ ] Full Player Artwork đúng
[ ] Null Artwork được xử lý
[ ] Không tải ảnh lặp không cần thiết
[ ] Không làm tăng bộ nhớ vô hạn
```

---

## TASK 6.5 — VOLUME SLIDER (AT04)

### 🎯 Mục tiêu

Hoàn thiện Volume Slider để người dùng điều chỉnh âm lượng phát nhạc trong Player.

### Cách làm

#### 1. Volume Source

Volume Slider phải kết nối trực tiếp với Playback Engine đã chọn tại AT01.

Không tạo một biến volume UI riêng mà không cập nhật Player thực tế.

#### 2. Volume Range

Thiết lập phạm vi theo cơ chế Player:

```text
Minimum: 0.0
Maximum: 1.0
```

Nếu Playback Engine sử dụng thang đo khác, phải chuẩn hóa trước khi hiển thị.

#### 3. UI Behavior

Volume Slider cần:

- Hiển thị giá trị hiện tại.
- Kéo sang trái giảm âm lượng.
- Kéo sang phải tăng âm lượng.
- Cập nhật Player khi thay đổi.
- Cập nhật UI khi volume được thay đổi từ nguồn khác nếu có.
- Không làm gián đoạn Playback.

#### 4. Volume Semantics

Phân biệt rõ:

```text
APP PLAYER VOLUME
    └── Âm lượng đầu ra của Player trong ứng dụng

SYSTEM DEVICE VOLUME
    └── Âm lượng toàn thiết bị do hệ điều hành quản lý
```

Không tự thay đổi System Volume nếu requirement chỉ yêu cầu âm lượng trong Player.

### DONE

```text
[ ] Slider hiển thị đúng volume
[ ] Kéo Slider thay đổi âm lượng thực tế
[ ] Min / Max hoạt động
[ ] Mute hoạt động nếu có
[ ] Không gián đoạn Playback
[ ] UI đồng bộ với Player State
[ ] Không gây lỗi khi chuyển bài
```

---

## TASK 6.6 — MUSIC FILE DETAILS (AT05)

### 🎯 Mục tiêu

Hiển thị thông tin chi tiết của file nhạc trong ứng dụng.

### Cách làm

#### 1. Metadata

Tùy theo dữ liệu sẵn có, hiển thị:

```text
Title
Artist
Album
Genre
Duration
File Name
File Format
File Size
File Location (nếu được phép hiển thị)
Audio Source
Download Status
```

Không giả định tất cả trường đều có giá trị.

#### 2. Audio Source Classification

Phân loại:

```text
LOCAL_ORIGINAL
DOWNLOADED
REMOTE_STREAM
LOCAL_CACHE
```

Chỉ sử dụng những trạng thái phù hợp với kiến trúc thực tế.

Giúp người dùng phân biệt:

- File gốc được nhập từ thiết bị.
- File do WaveBox tải về.
- Bản nhạc đang được stream.
- Bản nhạc có cache local.

#### 3. Metadata Resolution

Luồng:

```text
Select Song
     ↓
Get Local Metadata
     ↓
Get SQLite Metadata
     ↓
Resolve File Information
     ↓
Build Song Detail Model
     ↓
Display Details
```

Ưu tiên sử dụng metadata đã có trong SQLite và dữ liệu được Repository quản lý.

Không đọc lại toàn bộ file audio mỗi lần mở màn hình nếu không cần thiết.

#### 4. File Location Safety

Đường dẫn file:

- Chỉ hiển thị nếu nghiệp vụ yêu cầu.
- Không dùng để tạo API request.
- Không trả physical path của Server cho người dùng.
- Không cho phép người dùng chỉnh sửa đường dẫn nội bộ nếu chưa có chức năng hỗ trợ rõ ràng.

#### 5. Missing Metadata

Xử lý:

```text
Unknown Artist
Unknown Album
Unknown Genre
Unknown Format
Unknown File Size
```

Không crash khi thiếu metadata hoặc file đã bị người dùng xóa khỏi thiết bị.

### DONE

```text
[ ] Song Detail hoạt động
[ ] Metadata được hiển thị đúng
[ ] File Name đúng
[ ] File Format đúng
[ ] File Size đúng
[ ] Audio Source được phân biệt
[ ] Download Status đúng
[ ] Metadata null được xử lý
[ ] File bị thiếu được xử lý
```

---

## TASK 6.7 — SAFE DOWNLOADED FILE DELETION (AT06)

### 🎯 Mục tiêu

Cho phép người dùng xóa bản nhạc đã tải về mà không làm mất file gốc hoặc làm hỏng database.

### 1. File Ownership Classification

Trước khi xóa, xác định file thuộc loại nào:

```text
ORIGINAL IMPORTED FILE
DOWNLOADED APP FILE
REMOTE STREAM
UNKNOWN FILE
```

Quy tắc:

```text
DOWNLOADED APP FILE
    → Có thể xóa nếu xác minh ownership

ORIGINAL IMPORTED FILE
    → Không xóa bằng chức năng xóa Download

REMOTE STREAM
    → Không xóa file server

UNKNOWN FILE
    → Không thực hiện xóa tự động
```

### 2. Safe Delete Flow

Luồng:

```text
User Select Delete Download
          ↓
Load Download Metadata
          ↓
Validate File Ownership
          ↓
Resolve Managed File Path
          ↓
Check App Storage Boundary
          ↓
Check File References
          ↓
Delete Download File
          ↓
Update Download Metadata
          ↓
Update Local Database
          ↓
Refresh UI
```

#### 3. Storage Boundary Validation

Bắt buộc:

- Đường dẫn phải nằm trong thư mục Download do ứng dụng quản lý.
- Chuẩn hóa đường dẫn trước khi kiểm tra.
- Ngăn Path Traversal.
- Không xóa file nằm ngoài vùng quản lý.
- Không dựa vào tên file để xác định ownership.
- Không xóa file gốc chỉ vì metadata có trường `isDownloaded`.

Nếu không xác minh được quyền sở hữu file:

```text
[DELETE BLOCKED — FILE OWNERSHIP UNKNOWN]
```

#### 4. Database Safety

Nếu file xóa thành công:

- Cập nhật Download Metadata.
- Đánh dấu bài hát không còn bản tải local.
- Giữ lại Song Metadata cần thiết.
- Không xóa Playlist.
- Không xóa Favorites.
- Không xóa History.
- Không xóa bản nhạc gốc.

Nếu file đã bị mất trước đó, cung cấp cách đồng bộ lại metadata thay vì gây lỗi ứng dụng.

Nếu xóa file thất bại, không được đánh dấu trạng thái Download là đã xóa hoàn toàn.

#### 5. User Confirmation

Có xác nhận trước khi xóa nếu UX yêu cầu.

Hiển thị rõ:

```text
Delete Downloaded Copy
```

Không ghi chung chung:

```text
Delete Song
```

vì có thể khiến người dùng hiểu rằng file gốc cũng sẽ bị xóa.

### DONE

```text
[ ] Chỉ xóa App Downloaded File
[ ] Không xóa Original Imported File
[ ] Path được xác minh
[ ] Path Traversal được ngăn chặn
[ ] Không xóa file ngoài App Storage
[ ] Metadata được cập nhật đúng
[ ] Playlist vẫn giữ nguyên
[ ] Favorites vẫn giữ nguyên
[ ] History vẫn giữ nguyên
[ ] Delete Failure được xử lý
[ ] UI phản ánh đúng trạng thái Download
```

---

## TASK 6.8 — SLEEP TIMER (AT07)

### 🎯 Mục tiêu

Cho phép người dùng thiết lập thời gian để Player tự dừng hoặc tạm dừng sau một khoảng thời gian nhất định.

### Cách làm

#### 1. Sleep Timer Options

Các lựa chọn thời gian phải theo UI và Use Case.

Ví dụ:

```text
5 Minutes
10 Minutes
15 Minutes
30 Minutes
45 Minutes
60 Minutes
Custom Duration (nếu yêu cầu)
```

Không bắt buộc triển khai toàn bộ các lựa chọn trên nếu yêu cầu gốc quy định khác.

#### 2. Sleep Timer Flow

```text
User Select Timer
       ↓
Validate Duration
       ↓
Start Timer Service
       ↓
Keep Playback Running
       ↓
Timer Reaches Zero
       ↓
Pause / Stop Player
       ↓
Update Playback State
       ↓
Notify UI
```

#### 3. Timer Management

Hỗ trợ:

```text
Start Timer
Pause Timer (nếu yêu cầu)
Resume Timer (nếu yêu cầu)
Cancel Timer
Reset Timer
Show Remaining Time
```

Timer phải được quản lý bởi một Service hoặc Controller phù hợp, không tạo timer mới mỗi khi Widget rebuild.

#### 4. Background Behavior

Sleep Timer phải hoạt động khi:

- Người dùng chuyển ứng dụng.
- Màn hình bị khóa.
- Player vẫn đang phát nhạc nền.

Sử dụng cơ chế tương thích với vòng đời ứng dụng và nền tảng đã chọn ở AT01.

Không phụ thuộc vào một Timer Widget chỉ tồn tại khi màn hình Player đang mở.

#### 5. Completion Behavior

Khi hết thời gian:

- Dừng hoặc tạm dừng Playback theo requirement.
- Cập nhật Player State.
- Notification phản ánh đúng trạng thái.
- Timer không tiếp tục chạy sau khi đã hết hạn.
- Không dừng một Player khác hoặc phiên phát không thuộc WaveBox.

Nếu có hiệu ứng giảm âm lượng dần (fade-out), chỉ triển khai khi requirement cho phép.

### DONE

```text
[ ] Start Timer hoạt động
[ ] Countdown chính xác
[ ] Cancel Timer hoạt động
[ ] Reset Timer hoạt động
[ ] Playback dừng đúng thời điểm
[ ] Timer hoạt động khi App Background
[ ] Timer hoạt động khi khóa màn hình
[ ] Không tạo Timer trùng
[ ] Notification cập nhật đúng
```

---

## TASK 6.9 — DOWNLOAD SERVICE (AT08)

### 🎯 Mục tiêu

Xây dựng Download Service để tải file nhạc từ nguồn được phép về thiết bị và quản lý trạng thái tải an toàn.

### 1. Download Architecture

Tổ chức theo kiến trúc:

```text
Download UI
    ↓
Download Controller
    ↓
Download Service
    ↓
HTTP Client / Download Manager
    ↓
Temporary File
    ↓
Validate Audio
    ↓
App Download Directory
    ↓
SQLite Download Metadata
```

Nếu project đã có Download Service, ưu tiên mở rộng thay vì tạo Service trùng lặp.

### 2. Download Source

Nguồn tải có thể là:

```text
Authorized Backend Streaming API
Authorized Download API
Authorized Media URL
```

Không tự tải từ URL bên ngoài nếu không được cho phép.

Không giả định mọi bài hát stream đều được phép tải về.

Backend/API Contract phải phân biệt quyền stream và quyền download nếu nghiệp vụ yêu cầu.

### 3. Download Directory

Tạo hoặc sử dụng thư mục thuộc quyền quản lý của ứng dụng.

Ví dụ:

```text
App Documents / Downloads
```

Tên thư mục thực tế phải thống nhất và lấy từ hệ điều hành, không hardcode đường dẫn tuyệt đối.

Yêu cầu:

- Không ghi trực tiếp lên file đang tồn tại.
- File tải về có tên an toàn.
- Không sử dụng title bài hát làm tên file mà không sanitize.
- Không cho filename traversal.
- Tránh trùng tên.
- Duy trì mapping giữa Song ID và Downloaded File.

### 4. Temporary File & Atomic Completion

Luồng:

```text
Start Download
      ↓
Write Temporary File
      ↓
Receive Audio Data
      ↓
Track Progress
      ↓
Validate Response
      ↓
Validate File
      ↓
Rename / Move to Final Path
      ↓
Save Download Metadata
      ↓
Mark Download Complete
```

Quy tắc:

- Download chưa hoàn tất không được hiển thị như file đã tải xong.
- Nếu tải thất bại, file tạm phải được xử lý an toàn.
- Chỉ đổi sang tên file chính thức sau khi kiểm tra dữ liệu thành công.
- Database chỉ đánh dấu Completed sau khi file đã được lưu ổn định.
- Không làm mất bản tải cũ khi tải lại thất bại.

### 5. Download State

Chuẩn hóa trạng thái:

```text
IDLE
QUEUED (nếu có)
DOWNLOADING
PAUSED (nếu hỗ trợ)
COMPLETED
FAILED
CANCELLED
```

Mỗi download nên quản lý:

```text
Song ID
Download URL
File Name
File Path
File Size
Downloaded Bytes
Progress
Status
Started At
Completed At
Error
```

Chỉ lưu metadata cần thiết, không lưu binary audio vào SQLite.

### 6. Download Actions

Hỗ trợ theo requirement:

```text
Start Download
Cancel Download
Retry Download
Pause Download (nếu có)
Resume Download (nếu có)
Get Download Progress
Check Download Status
```

Không bắt buộc hỗ trợ resume nếu Backend hoặc HTTP source không hỗ trợ Range đúng cách.

Nếu hỗ trợ resume, phải kiểm tra:

- `Accept-Ranges`.
- `Content-Range`.
- File hiện tại có đúng nguồn hay không.
- Server trả đúng đoạn dữ liệu tiếp theo.
- Không ghép nhầm hai file khác nhau.

### 7. Download Concurrency

Không tải không giới hạn số lượng file cùng lúc.

Thiết lập giới hạn đồng thời phù hợp với thiết bị và kiến trúc hiện tại.

Yêu cầu:

- Không tạo nhiều request cho cùng một Song ngoài chủ đích.
- Có thể hủy task.
- Không để hai tác vụ ghi cùng một file.
- Xử lý khi ứng dụng bị đóng.
- Có trạng thái rõ ràng khi mất kết nối.

### 8. SQLite Metadata

Download Metadata phải tham chiếu được Song ID và file local.

Ví dụ:

```text
song_id
local_file_name
local_file_path
file_size
mime_type
download_status
downloaded_at
```

Tên trường thực tế phải khớp schema SQLite hiện có.

Không tạo bảng mới trùng chức năng hoặc xóa metadata hiện tại.

### 9. Network & Error Handling

Xử lý:

```text
No Internet
Timeout
Unauthorized
Forbidden Download
Song Not Found
File Not Available
Insufficient Storage
Invalid Audio Response
HTTP Error
Cancelled Download
App Interrupted
```

Không tự logout khi Download gặp Timeout hoặc lỗi mạng.

Không lưu dữ liệu HTML lỗi dưới dạng file `.mp3`.

### DONE

```text
[ ] Download Service hoạt động
[ ] Tải từ nguồn được phép
[ ] File lưu đúng thư mục
[ ] Temporary File hoạt động
[ ] File được validate
[ ] Progress hoạt động
[ ] Cancel hoạt động
[ ] Retry hoạt động
[ ] Resume hoạt động nếu hỗ trợ
[ ] SQLite Metadata được cập nhật
[ ] Không tạo file trùng ngoài ý muốn
[ ] Download lỗi được xử lý
[ ] Không lưu audio binary vào SQLite
```

---

## TASK 6.10 — OFFLINE PLAYBACK (AT09)

### 🎯 Mục tiêu

Bảo đảm bài hát đã được tải về hoặc có file local hợp lệ có thể phát khi thiết bị không có Internet.

### 1. Audio Source Resolver

Tạo hoặc mở rộng cơ chế chọn nguồn phát.

Luồng mục tiêu:

```text
User Select Song
       ↓
Check Local Original File
       ↓
Check Downloaded File
       ↓
Validate Local File
       |
   +---+---+
   |       |
 Found   Not Found
   |       |
Play     Check Network
Local       |
        +--+--+
        |     |
      Online Offline
        |     |
      Stream  Unavailable
```

Thứ tự ưu tiên nguồn phải tuân thủ yêu cầu sản phẩm và trạng thái file thực tế.

Đề xuất:

- Ưu tiên bản local hợp lệ khi có và được phép sử dụng.
- Nếu không có bản local, phát stream khi có mạng và API cho phép.
- Nếu không có mạng và không có file local, hiển thị trạng thái không khả dụng.
- Không cố stream khi thiết bị offline.
- Không mặc định một metadata record đồng nghĩa file audio đã tồn tại.

### 2. Local File Validation

Trước khi phát:

- Kiểm tra file tồn tại.
- Kiểm tra đường dẫn.
- Kiểm tra file có thể đọc.
- Kiểm tra định dạng hoặc MIME phù hợp.
- Xử lý trường hợp file bị xóa bên ngoài ứng dụng.
- Không crash khi file bị hỏng.

Nếu file không tồn tại:

```text
DOWNLOADED FILE MISSING
```

Phải cập nhật UI và trạng thái Download cho đúng.

### 3. Offline Playback

Kiểm thử:

```text
Downloaded Song
       ↓
Disable Wi-Fi
       ↓
Disable Mobile Data
       ↓
Open WaveBox
       ↓
Load Local Song
       ↓
Play Audio
       ↓
Pause / Resume / Seek
       ↓
Next / Previous
```

Yêu cầu:

- Không gọi Backend khi phát file local đã có.
- Queue hoạt động khi offline.
- Seek hoạt động.
- Background Playback hoạt động theo cấu hình AT01.
- Notification vẫn điều khiển Player.
- Không tải lại file chỉ vì mở bài hát offline.

### 4. Offline Data Preservation

Không xóa các dữ liệu:

```text
SQLite Song Metadata
Playlist Local
Favorites Local
History Local
Downloaded Files
User Imported Music
```

Không triển khai quá trình Restore hoặc đồng bộ dữ liệu tài khoản trong Phase 6.

### 5. Playback Source State

UI cần phân biệt:

```text
LOCAL
DOWNLOADED
STREAMING
UNAVAILABLE
```

Trạng thái thực tế phải dựa trên nguồn phát đã được chọn, không chỉ dựa vào tên bài hát.

### DONE

```text
[ ] Phát file local khi offline
[ ] Phát file downloaded khi offline
[ ] Không cần Backend cho local playback
[ ] Queue hoạt động offline
[ ] Seek hoạt động offline
[ ] Background Playback offline
[ ] Missing File được xử lý
[ ] Corrupted File được xử lý
[ ] Không tự tải lại file khi offline
[ ] Không mất SQLite Data
```

---

## TASK 6.11 — VIDEO SEEKBAR & FULLSCREEN (AT11)

### 🎯 Mục tiêu

Hoàn thiện Video Seekbar và Fullscreen nếu chức năng Video vẫn thuộc phạm vi sản phẩm.

### Cách làm

Trước tiên xác minh:

```text
Video Player Requirement
video_player Dependency
Existing Video Screen
Current Seekbar
Fullscreen Navigation
Video Source
```

Nếu Video được xác nhận thuộc phạm vi:

#### 1. Video Seekbar

Hỗ trợ:

```text
Current Position
Total Duration
Buffered Position
Seek
Play / Pause
```

Yêu cầu:

- Slider đồng bộ với Video Controller.
- Kéo seek đến vị trí hợp lệ.
- Không gây nhảy liên tục ngoài ý muốn.
- Hiển thị thời gian hiện tại và tổng thời lượng.
- Xử lý Video chưa có duration.
- Xử lý lỗi nguồn Video.

#### 2. Fullscreen

Hỗ trợ:

- Vào Fullscreen.
- Thoát Fullscreen.
- Đồng bộ Playback State.
- Giữ đúng vị trí phát.
- Xử lý orientation theo cấu hình.
- Xử lý Back Navigation.
- Không tạo Video Controller trùng.
- Không làm hỏng Audio Player.

#### 3. Audio / Video Separation

Không dùng chung trạng thái Audio và Video một cách tùy tiện.

Phải xác định rõ:

```text
Audio Playback Controller
Video Playback Controller
```

Khi Audio và Video có thể cùng phát, phải có chính sách Audio Focus hoặc dừng nguồn không được phép.

#### 4. Out of Scope

Nếu Video không còn thuộc phạm vi sản phẩm:

```text
[OUT OF SCOPE — PRODUCT SCOPE DECISION]
```

Phải ghi lý do vào báo cáo và cập nhật Requirement Traceability.

Không tự bỏ AT11 mà không ghi nhận quyết định.

### DONE

Nếu In Scope:

```text
[ ] Video Seekbar hoạt động
[ ] Position đúng
[ ] Buffered Position đúng
[ ] Seek hoạt động
[ ] Fullscreen hoạt động
[ ] Back Navigation hoạt động
[ ] Không tạo Video Controller trùng
[ ] Không ảnh hưởng Audio Player
```

Nếu Out of Scope:

```text
[ ] Có quyết định phạm vi rõ ràng
[ ] Ghi nhận AT11 OUT OF SCOPE
[ ] Không xóa Video Code hiện có
```

---

## TASK 6.12 — PLAYER, DOWNLOAD & OFFLINE TESTS (AT10)

### 🎯 Mục tiêu

Kiểm chứng Player, Background Audio, Download và Offline Playback trên ứng dụng thực tế, bảo đảm không làm hỏng các chức năng cũ.

### 1. Unit Tests

Kiểm tra:

```text
Playback Controller
Audio Source Resolver
Download Service
Download State
Sleep Timer
Artwork Resolver
File Deletion Logic
```

### 2. Widget Tests

Kiểm tra:

```text
Player Screen
Mini Player
Volume Slider
Song Detail
Download UI
Sleep Timer UI
```

### 3. Playback Tests

Kịch bản:

```text
Play
Pause
Resume
Next
Previous
Seek
Queue
Repeat / Shuffle (nếu có)
Volume
```

Kiểm tra không phát trùng và Playback State luôn chính xác.

### 4. Background Audio Tests

```text
Play Song
Lock Screen
Control Notification
Switch App
Return to WaveBox
Interrupt Audio
Resume Playback
Stop Playback
```

### 5. Notification Tests

Kiểm tra:

```text
Notification Display
Artwork
Song Metadata
Play / Pause
Next / Previous
Media Session
```

### 6. Download Tests

```text
Download Success
Download Cancelled
Download Retry
Download Failed
Insufficient Storage
Invalid Audio Response
Duplicate Download
Partial File
```

Nếu hỗ trợ resume, phải test thêm việc tiếp tục tải đúng phần còn thiếu.

### 7. Safe Delete Tests

Bắt buộc thử:

```text
Delete Downloaded Copy
Original File Protection
Unknown Path Protection
Path Traversal Attempt
Missing File
Database Update Failure
File Deletion Failure
```

### 8. Offline Playback Tests

```text
Online Playback
Download Song
Disable Network
Play Downloaded Song
Seek Offline
Next / Previous Offline
Background Playback Offline
```

### 9. Sleep Timer Tests

```text
Start Timer
Cancel Timer
Reset Timer
Timer Expiration
App Background
Screen Locked
```

### 10. Video Tests

Chỉ thực hiện nếu AT11 được xác nhận In Scope.

### 11. Regression Tests

Bắt buộc kiểm tra lại:

```text
Local Music Library
SQLite
SongRepository
Playlist Local
Favorites Local
History Local
Authentication
Session Restore
Search Local
Search Online (nếu có)
```

Không được làm hỏng các chức năng đã tích hợp ở Phase 5.

### 12. Commands

```bash
flutter pub get
```

```bash
flutter analyze
```

```bash
flutter test
```

Build Android:

```bash
flutter build apk --debug
```

Nếu project có iOS:

```bash
flutter build ios --no-codesign
```

Lệnh build phải phù hợp với môi trường đã cài đặt.

Bắt buộc có kiểm thử trên thiết bị thật đối với Background Audio, Notification, Media Session và Offline Playback khi có thiết bị phù hợp.

### DONE

```text
[ ] Unit Tests PASS
[ ] Widget Tests PASS
[ ] Playback Tests PASS
[ ] Background Audio Tests PASS
[ ] Notification Tests PASS
[ ] Download Tests PASS
[ ] Safe Delete Tests PASS
[ ] Offline Playback Tests PASS
[ ] Sleep Timer Tests PASS
[ ] Video Tests PASS nếu In Scope
[ ] Regression Tests PASS
[ ] Flutter Analyze PASS
[ ] Android Build PASS
```

---

## TASK 6.13 — DOCUMENTATION & PHASE 6 REPORT

### 🎯 Mục tiêu

Ghi lại cơ chế Player chính thức, cấu hình Download và cách quản lý dữ liệu local để Phase 7 có thể tiếp tục mà không phải audit lại toàn bộ.

Tạo:

```text
docs/REPORT/PHASE-6-PLAYER-DOWNLOAD.md
```

Cập nhật nếu có quyết định kiến trúc mới:

```text
docs/architecture/DECISION_LOG.md
```

Nội dung báo cáo:

```markdown
# PHASE 6 — PLAYER & DOWNLOAD REPORT

## 1. Flutter Environment
- Flutter Version
- Android Configuration
- Dependencies

## 2. Existing Player Audit
- Existing Audio Handler
- Existing Player Engine
- Dependency Analysis

## 3. Background Audio Architecture
- Selected Playback Engine
- Playback Controller
- Audio Session
- Queue Management

## 4. Notification & Media Session
- Notification Configuration
- Controls
- Background Test Results

## 5. Artwork
- Artwork Sources
- Cache
- Fallback

## 6. Volume Slider

## 7. Music File Details

## 8. Safe Download Deletion
- Storage Boundary
- File Ownership
- Database Update

## 9. Sleep Timer

## 10. Download Service
- Download Directory
- Download State
- Temporary File
- Validation
- Error Handling

## 11. Offline Playback
- Local Source Resolver
- Missing File Handling
- Offline Test Results

## 12. Video Seekbar / Fullscreen
- IN SCOPE / OUT OF SCOPE

## 13. Test Results
- Unit Tests
- Widget Tests
- Device Tests
- Regression Tests

## 14. Known Issues & Dependencies

## 15. Phase 6 Acceptance
- Completed Tasks
- Pending Tasks
- Final Status
```

### DONE

```text
[ ] Phase 6 Report hoàn chỉnh
[ ] Playback Architecture được mô tả
[ ] Download Storage được mô tả
[ ] Offline Source được mô tả
[ ] AT11 Scope được xác nhận
[ ] Decision Log được cập nhật nếu cần
[ ] Test Results có bằng chứng
```

---

# 5. PHASE 6 FINAL REVIEW

## 🎯 Mục tiêu

Kiểm tra toàn bộ AT01–AT11 trước khi bàn giao ứng dụng cho Phase 7.

### DONE Checklist

```text
[ ] TASK 6.1 — Audit Existing Player
[ ] Đã kiểm tra audio_handler.dart
[ ] Đã kiểm tra just_audio
[ ] Đã kiểm tra audio_service nếu có
[ ] Đã kiểm tra video_player
[ ] Đã xác định Player instance
[ ] Không xóa dependency khi chưa xác minh

[ ] TASK 6.2 — Background Audio Mechanism (AT01)
[ ] Chọn một Playback Engine chính
[ ] Playback State thống nhất
[ ] Queue hoạt động đúng
[ ] Play / Pause / Next / Previous
[ ] Seek
[ ] Audio Lifecycle
[ ] Background Playback

[ ] TASK 6.3 — Notification / MediaSession (AT02)
[ ] Notification hoạt động
[ ] Media Session hoạt động
[ ] Metadata chính xác
[ ] Play / Pause / Next / Previous
[ ] Physical Device Test

[ ] TASK 6.4 — Artwork (AT03)
[ ] Local Artwork
[ ] Remote Artwork
[ ] Artwork Cache
[ ] Fallback Artwork
[ ] Notification Artwork

[ ] TASK 6.5 — Volume Slider (AT04)
[ ] Slider thay đổi Volume thực tế
[ ] Min / Max
[ ] Playback không bị gián đoạn

[ ] TASK 6.6 — File Details (AT05)
[ ] Metadata
[ ] File Name
[ ] Format
[ ] Size
[ ] Audio Source
[ ] Download Status

[ ] TASK 6.7 — Safe Delete (AT06)
[ ] Chỉ xóa bản tải do App quản lý
[ ] Không xóa file gốc
[ ] Không xóa file ngoài Storage Boundary
[ ] Không làm hỏng SQLite
[ ] Playlist / Favorites / History được giữ nguyên

[ ] TASK 6.8 — Sleep Timer (AT07)
[ ] Start
[ ] Cancel
[ ] Reset
[ ] Background Behavior
[ ] Timer Expiration

[ ] TASK 6.9 — Download Service (AT08)
[ ] Download Success
[ ] Progress
[ ] Cancel
[ ] Retry
[ ] File Validation
[ ] Temporary File
[ ] SQLite Metadata

[ ] TASK 6.10 — Offline Playback (AT09)
[ ] Phát downloaded audio khi offline
[ ] Queue offline
[ ] Seek offline
[ ] Background offline
[ ] Missing File Handling

[ ] TASK 6.11 — Video Seekbar / Fullscreen (AT11)
[ ] Đã xác định In Scope / Out of Scope
[ ] Nếu In Scope: chức năng hoạt động
[ ] Nếu Out of Scope: có quyết định và báo cáo

[ ] TASK 6.12 — Tests (AT10)
[ ] Unit Tests
[ ] Widget Tests
[ ] Player Tests
[ ] Download Tests
[ ] Offline Tests
[ ] Background Audio Tests
[ ] Regression Tests
[ ] Flutter Analyze
[ ] Android Build

[ ] TASK 6.13 — Documentation
[ ] Phase 6 Report
[ ] Decision Log cập nhật
[ ] Test Results có bằng chứng

[ ] Không làm hỏng Phase 1–5
[ ] Không mất dữ liệu Local
[ ] Không xóa nhạc gốc
[ ] Không xóa audio_handler.dart tùy tiện
[ ] Không triển khai trùng Sync của Phase 7
[ ] Git status đã được kiểm tra
```

---

# 6. ĐIỀU KIỆN PHASE 6 DONE

Chỉ được đánh dấu hoàn thành khi có bằng chứng:

**1. Playback**

```text
Play: PASS
Pause: PASS
Resume: PASS
Next: PASS
Previous: PASS
Seek: PASS
Queue: PASS
```

**2. Background Audio**

```text
Background Playback: PASS
Notification: PASS
Media Session: PASS
Audio Focus: PASS
Physical Device Test: PASS
```

**3. Artwork & Player Controls**

```text
Artwork: PASS
Volume Slider: PASS
Song Details: PASS
```

**4. Download**

```text
Download: PASS
Progress: PASS
Cancel: PASS
Retry: PASS
File Validation: PASS
SQLite Metadata: PASS
```

**5. Safe File Management**

```text
Delete Downloaded Copy: PASS
Original Imported File: PRESERVED
Storage Boundary Validation: PASS
Playlist / Favorites / History: PRESERVED
```

**6. Offline Playback**

```text
Downloaded Audio Offline: PASS
Local Queue: PASS
Seek Offline: PASS
Background Offline Playback: PASS
Missing File Handling: PASS
```

**7. Sleep Timer**

```text
Start: PASS
Cancel: PASS
Expiration: PASS
Background Operation: PASS
```

**8. Video**

```text
Video Seekbar / Fullscreen: PASS
```

Hoặc:

```text
AT11: OUT OF SCOPE
```

nếu đã có quyết định chính thức.

**9. Build & Tests**

```text
Flutter Analyze: PASS
Flutter Tests: PASS
Android Build: PASS
Physical Device Tests: PASS (các chức năng cần thiết)
```

Nếu chưa kiểm thử được:

```text
[PASS]
[FAILED]
[NOT TESTED]
[BLOCKED]
[OUT OF SCOPE]
```

Không đánh dấu Download PASS nếu chỉ tải được file mà chưa kiểm tra khả năng phát lại.

Không đánh dấu Offline Playback PASS nếu chỉ phát file local khi còn Internet.

Không đánh dấu Safe Delete PASS nếu chưa kiểm tra trường hợp file gốc và file không thuộc quyền quản lý của ứng dụng.

---

# 7. STOP RULE

Sau khi hoàn thành Phase 6:

**DỪNG.**

Không tự chuyển sang triển khai đồng bộ Local–Cloud hoàn chỉnh.

Không tự triển khai:

```text
Pending Sync Queue Refactor
Automatic Batch Sync
Connectivity Sync Trigger
Retry Queue
Cloud Restore
Conflict Resolution
Account Data Merge
Playlist Cloud Synchronization
Favorites Cloud Synchronization
History Cloud Synchronization
Full Offline-first Data Architecture
```

Các nội dung này thuộc Phase 7.

Chỉ khi người dùng xác nhận:

```text
PHASE 6 DONE
```

mới chuyển sang:

```text
PHASE 7 — OFFLINE-FIRST & SYNCHRONIZATION
```

---

# 8. TỔNG KẾT CẤU TRÚC PHASE 6

```text
PHASE 6 — FLUTTER PLAYER & DOWNLOAD
│
├── TASK 6.1
│   └── Audit Existing Player Architecture
│
├── TASK 6.2
│   └── Select Background Audio Mechanism (AT01)
│
├── TASK 6.3
│   └── Notification & MediaSession (AT02)
│
├── TASK 6.4
│   └── Artwork Management (AT03)
│
├── TASK 6.5
│   └── Volume Slider (AT04)
│
├── TASK 6.6
│   └── Music File Details (AT05)
│
├── TASK 6.7
│   └── Safe Download Deletion (AT06)
│
├── TASK 6.8
│   └── Sleep Timer (AT07)
│
├── TASK 6.9
│   └── Download Service (AT08)
│
├── TASK 6.10
│   └── Offline Playback (AT09)
│
├── TASK 6.11
│   └── Video Seekbar / Fullscreen (AT11)
│
├── TASK 6.12
│   └── Player / Download Tests (AT10)
│
├── TASK 6.13
│   └── Documentation & Report
│
└── TASK 6.14
    └── Final Review & Stop
```

---

# 9. THỨ TỰ THỰC THI

```text
READ PHASE 1–5 DOCUMENTS
          ↓
AUDIT EXISTING PLAYER & DOWNLOAD SOURCE
          ↓
TRACE audio_handler.dart DEPENDENCIES
          ↓
SELECT ONE BACKGROUND AUDIO ENGINE
          ↓
INTEGRATE PLAYER STATE & QUEUE
          ↓
INTEGRATE NOTIFICATION / MEDIA SESSION
          ↓
IMPLEMENT ARTWORK
          ↓
IMPLEMENT VOLUME SLIDER
          ↓
IMPLEMENT MUSIC FILE DETAILS
          ↓
IMPLEMENT SAFE DOWNLOAD DELETION
          ↓
IMPLEMENT SLEEP TIMER
          ↓
IMPLEMENT DOWNLOAD SERVICE
          ↓
IMPLEMENT OFFLINE PLAYBACK
          ↓
IMPLEMENT VIDEO FEATURES IF IN SCOPE
          ↓
RUN PLAYER / DOWNLOAD / OFFLINE TESTS
          ↓
RUN REGRESSION TESTS
          ↓
WRITE PHASE 6 REPORT
          ↓
FINAL REVIEW
          ↓
PHASE 6 DONE
          ↓
STOP
```

---

## NGUYÊN TẮC QUAN TRỌNG NHẤT

Phase 6 là giai đoạn hoàn thiện **trải nghiệm nghe nhạc cốt lõi của WaveBox**.

Một cơ chế Player phải chịu trách nhiệm xuyên suốt việc phát nhạc, Queue, Background Audio và Media Session. Download phải lưu file an toàn, quản lý được trạng thái và không làm mất nhạc gốc của người dùng. Offline Playback phải hoạt động thực sự khi thiết bị không có Internet.

**Không đánh đổi tính ổn định của Player để viết lại kiến trúc một cách không cần thiết. Không xóa `audio_handler.dart` khi chưa kiểm tra toàn bộ dependency. Không xóa file nhạc gốc khi người dùng chỉ yêu cầu xóa bản tải về.**

Phase 6 hoàn thiện khả năng nghe nhạc và quản lý file trên thiết bị; Phase 7 mới tiếp tục xử lý đồng bộ dữ liệu Local–Cloud, khôi phục dữ liệu và bảo đảm hoạt động Offline-first trên nhiều phiên đăng nhập.