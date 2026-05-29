# Tài liệu dự án — Game học ngoại ngữ (tiếng Trung)

Bộ tài liệu thiết kế & quản lý công việc cho phần mềm học ngoại ngữ kiểu Mario (Flutter).

## Mục lục

| File | Nội dung |
|------|----------|
| [design.md](design.md) | Đặc tả thiết kế: gameplay, màn hình, SRS, data model, đồng bộ, audio |
| [tasks.md](tasks.md) | **Bảng công việc** — các task chia theo nhóm, mỗi task có trạng thái |
| [data-pipeline.md](data-pipeline.md) | Phương án & pipeline tạo dữ liệu HSK 3→6 từ nguồn mở |
| [assets.md](assets.md) | Nguồn hình ảnh / âm thanh / font miễn phí (CC0) + cảnh báo bản quyền |

## Trạng thái nhanh

- ✅ Thiết kế chốt xong (gameplay hướng A, SRS Leitner, đồng bộ Drive snapshot).
- ✅ Dữ liệu: **HSK 1→6 đầy đủ (4994 thẻ)** — HSK 1+2 gõ tay, HSK 3→6 từ pipeline nguồn mở. Tất cả **chưa kiểm chứng** (`verified: false`).
- ✅ Pipeline tái lập: [../tools/](../tools/) (`fetch-sources.sh` + `build-hsk.js`).
- ✅ **Code Flutter (E2/E3/E4/E6 cốt lõi)**: chọn khóa→bài→chơi 1 vòng (Flame + Bloc + Hive), 4 đáp án từ distractor, SRS, mạng/nấm/combo. `flutter analyze` sạch, 4/4 unit test pass.
- ⚠️ **Chưa chạy trên máy/emulator thật** (mới verify bằng analyze + unit test). Cần lượt verify chạy app (E3-8).

## Chạy thử

```bash
flutter pub get
flutter run            # cần emulator/thiết bị
flutter analyze && flutter test
```

> ⚠️ Toàn bộ dữ liệu trong `../content/` **cần rà soát bởi người rành tiếng Trung** trước khi phát hành (xem [../content/README.md](../content/README.md)).
> ⚠️ `meaning_vi` (HSK 3→6) dùng nguồn **CC-BY-SA 4.0** — ràng buộc ghi công/share-alike, xem [../content/CREDITS.md](../content/CREDITS.md).
