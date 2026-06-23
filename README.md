# study_language

Game học tiếng Trung kiểu Mario (Flutter). *Học là chính, game là động lực.*

## Tính năng

- **Vòng chơi quiz** 20 câu: mạng/combo/nấm, câu **boss** (đếm giờ), **power-up** (gợi ý/đóng băng/hồi mạng), cảnh cuộn parallax.
- **5 dạng câu hỏi**: Hán→nghĩa, nghĩa→Hán, **nghe**, **thanh điệu**, **Hán Việt** (bật/tắt trong Cài đặt).
- **SRS** (Leitner rút gọn) + màn **Ôn tập** theo thẻ đến hạn + **Preview** từ vựng & gợi ý tốc độ.
- **Audio TTS** tiếng Trung (`flutter_tts`).
- **Thống kê** tiến độ, **streak** + **nhắc học** hằng ngày (local notification).
- **Sao lưu/khôi phục** (file local + Google Drive) và **cập nhật nội dung** online.

Tài liệu thiết kế: [docs/design.md](docs/design.md) · Bảng công việc: [docs/tasks.md](docs/tasks.md).

## Chạy

```bash
flutter pub get
flutter run
```

## Cấu hình (tùy chọn)

- **Cập nhật nội dung online (E7):** trỏ tới server chứa `manifest.json` + `hskN.json`:
  ```bash
  flutter run --dart-define=CONTENT_BASE_URL=https://your-host/content
  ```
  Bỏ trống → offline-first dùng nội dung bundle trong `content/`.

- **Đồng bộ Google Drive (E6):** cần tự tạo OAuth client trên Google Cloud Console
  (Android: `google-services.json` + vân tay SHA-1; iOS: clientId trong `Info.plist`),
  rồi đặt `kDriveConfigured = true` trong [lib/logic/sync/drive_sync.dart](lib/logic/sync/drive_sync.dart).
  Khi chưa cấu hình, sao lưu **file local** vẫn dùng được đầy đủ.

## Kiểm thử

```bash
flutter analyze
flutter test
```

CI (GitHub Actions) chạy analyze + test + build APK debug — xem [.github/workflows/build.yml](.github/workflows/build.yml).
