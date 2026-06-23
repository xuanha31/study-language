# Bảng công việc (Task Board)

> **Chú thích trạng thái:**
> `☐ TODO` chưa làm · `◐ DOING` đang làm · `☑ DONE` xong · `⛔ BLOCKED` bị chặn (chờ thứ khác) · `🔍 REVIEW` chờ kiểm/duyệt
>
> Cập nhật trạng thái ngay trên dòng task. Mã task dạng `E<nhóm>-<số>` để tham chiếu.

---

## E0 — Thiết kế & tài liệu

| Mã | Task | Trạng thái |
|----|------|-----------|
| E0-1 | Chốt ý tưởng & gameplay (hướng A, mạng, combo, boss) | ☑ DONE |
| E0-2 | Thiết kế SRS (Leitner rút gọn, đo thời gian tương đối) | ☑ DONE |
| E0-3 | Thiết kế data model + cơ chế cập nhật (version per-card) | ☑ DONE |
| E0-4 | Thiết kế đồng bộ Google Drive (snapshot, tùy chọn) | ☑ DONE |
| E0-5 | Viết design doc ([design.md](design.md)) | ☑ DONE |
| E0-6 | Viết task board (file này) | ☑ DONE |
| E0-7 | CI/CD GitHub Actions (analyze + test + build APK) | ☑ DONE |

## E1 — Dữ liệu nội dung (content)

| Mã | Task | Trạng thái |
|----|------|-----------|
| E1-1 | Schema card + manifest + README | ☑ DONE |
| E1-2 | Tạo HSK 1 (150 từ) | ☑ DONE · 🔍 REVIEW (chưa kiểm chứng) |
| E1-3 | Tạo HSK 2 (150 từ) | ☑ DONE · 🔍 REVIEW (chưa kiểm chứng) |
| E1-4 | **Rà soát** HSK 1+2 bởi người rành tiếng Trung (đặt `verified:true`) | ☐ TODO |
| E1-5 | Chốt phương án data HSK 3→6 → chọn **A: pipeline nguồn mở** | ☑ DONE |
| E1-6 | Pipeline build (`tools/build-hsk.js` + fetch) — tái lập được | ☑ DONE |
| E1-7 | Sinh HSK 3 (298), HSK 4 (598), HSK 5 (1298), HSK 6 (2500) | ☑ DONE · 🔍 REVIEW |
| E1-8 | Ghi công + license nguồn ([../content/CREDITS.md](../content/CREDITS.md)) | ☑ DONE |
| E1-9 | **Rà soát** HSK 3→6 (meaning_vi AI-dịch, hanviet chọn âm tự động) | ☐ TODO |
| E1-9b | Sửa pipeline chọn nhầm form chữ đa âm + làm sạch nghĩa + per-char + audio HSK1/2 | ☑ DONE |
| E1-10 | Soạn hội thoại (`type:dialogue`) — tự viết, tránh bản quyền | ☐ TODO |
| E1-11 | Xử lý ràng buộc CC-BY-SA 4.0 của `meaning_vi` (ghi công trong app / cân nhắc nguồn) | ☐ TODO |
| E1-12 | Bổ sung ~2 từ/level thiếu so chuẩn (HSK3/4/5: 298/598/1298 vs 300/600/1300) | ☐ TODO |

## E2 — Khung dự án Flutter

| Mã | Task | Trạng thái |
|----|------|-----------|
| E2-1 | Khởi tạo project Flutter, cấu trúc thư mục, lint | ☑ DONE |
| E2-2 | Model Dart cho Card / CharInfo / Course (parse JSON) | ☑ DONE |
| E2-3 | ContentRepository: load manifest + hskN.json từ assets (bundle `content/`) | ☑ DONE |
| E2-4 | State management → **Bloc** (GameBloc) + Cubit (ContentCubit) | ☑ DONE |
| E2-5 | Nhúng font CJK (Noto Sans SC) qua google_fonts (tải+cache runtime) | ☑ DONE |

## E3 — Engine game (gameplay hướng A)

| Mã | Task | Trạng thái |
|----|------|-----------|
| E3-1 | Spike Flame vs widget → chọn **Flame** (cảnh vẽ bằng canvas, chưa sprite) | ☑ DONE |
| E3-2 | Màn chơi: nhân vật + mặt đất, nhảy ăn nấm khi đúng (hướng A) | ☑ DONE |
| E3-3 | UI câu hỏi 4 đáp án (overlay) + hiệu ứng đúng/sai | ☑ DONE |
| E3-4 | Hệ thống mạng (3 mặc định) + nấm + combo + thưởng mạng mỗi 5 combo | ☑ DONE |
| E3-5 | Boss câu 20 (đồng hồ đếm ngược) + power-up (gợi ý/đóng băng/hồi mạng) | ☑ DONE |
| E3-6 | Cảnh cuộn parallax + nhân vật chạy tới trạm kế + boss xuất hiện | ☑ DONE |
| E3-7 | Điều chỉnh tốc độ chơi (chậm/vừa/nhanh) | ☑ DONE |
| E3-8 | **Verify**: analyze+test (18 pass) + build APK debug; chưa chạy GUI tương tác | ◐ DOING |

## E4 — Học tập (chọn câu, SRS, ôn tập)

| Mã | Task | Trạng thái |
|----|------|-----------|
| E4-1 | Sinh 4 đáp án từ `distractor_group` (AnswerService) | ☑ DONE |
| E4-2 | Đủ dạng câu hỏi: Hán↔nghĩa, **nghe, thanh điệu, Hán Việt** (chọn trong cài đặt) | ☑ DONE |
| E4-3 | Lưu tiến độ học từng từ (level, nextReviewMs) — Hive | ☑ DONE |
| E4-4 | Thuật toán SRS (lên/xuống bậc, đo thời gian tương đối) | ☑ DONE |
| E4-5 | Màn ôn tập (gom thẻ đến hạn SRS → 1 vòng) | ☑ DONE |
| E4-6 | Preview từ vựng trước vòng + gợi ý tốc độ | ☑ DONE |

## E5 — Audio & TTS

| Mã | Task | Trạng thái |
|----|------|-----------|
| E5-1 | `flutter_tts` (zh-CN) + "chuẩn bị giọng đọc" kiểm tra engine | ☑ DONE |
| E5-2 | Pre-cache `synthesizeToFile` + màn loading (hiện đọc lazy, đủ dùng) | ◐ DOING |
| E5-3 | Phát audio câu hỏi nghe/thanh điệu + nút loa (preview/câu hỏi) | ☑ DONE |

## E6 — Đồng bộ & lưu trữ

| Mã | Task | Trạng thái |
|----|------|-----------|
| E6-1 | Lưu tiến độ local → **Hive** (ProgressRepository) | ☑ DONE |
| E6-2 | Google Sign-In + Drive AppData (code đủ, chờ cờ `kDriveConfigured` + OAuth) | ◐ DOING |
| E6-3 | Tạo/liệt kê/restore/xóa snapshot, giới hạn ~10 bản (local + Drive) + chia sẻ/nhập file | ☑ DONE |
| E6-4 | Cảnh báo khi restore đè tiến độ | ☑ DONE |

## E7 — Tải/cập nhật nội dung

| Mã | Task | Trạng thái |
|----|------|-----------|
| E7-1 | Offline-first: bản đã tải > bundle; tải khi có `CONTENT_BASE_URL` | ◐ DOING |
| E7-2 | `checkAndUpdate`: so version từng khóa qua manifest, giữ id → giữ tiến độ | ☑ DONE |

## E8 — Tài nguyên (assets)

| Mã | Task | Trạng thái |
|----|------|-----------|
| E8-1 | Tổng hợp nguồn ảnh/âm thanh/font CC0 ([assets.md](assets.md)) | ☑ DONE |
| E8-2 | Chọn & tải bộ sprite nhân vật + nấm + tileset platformer | ☐ TODO |
| E8-3 | Kiểm tra license từng asset (CC0/ghi công) trước khi dùng | ☐ TODO |

## E9 — UI/UX & ngoài game

| Mã | Task | Trạng thái |
|----|------|-----------|
| E9-1 | Màn chọn khóa HSK → bài → vòng | ☑ DONE |
| E9-2 | Màn cài đặt (tốc độ, dạng câu hỏi/chiều, âm thanh, nhắc học, dữ liệu) | ☑ DONE |
| E9-3 | Màn thống kê tiến độ / từ đã thuộc / độ chính xác / theo khóa | ☑ DONE |
| E9-4 | Daily streak + local notification nhắc học | ☑ DONE |
