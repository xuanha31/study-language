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
| E1-10 | Soạn hội thoại (`type:dialogue`) — tự viết, tránh bản quyền | ☐ TODO |
| E1-11 | Xử lý ràng buộc CC-BY-SA 4.0 của `meaning_vi` (ghi công trong app / cân nhắc nguồn) | ☐ TODO |

## E2 — Khung dự án Flutter

| Mã | Task | Trạng thái |
|----|------|-----------|
| E2-1 | Khởi tạo project Flutter, cấu trúc thư mục, lint | ☐ TODO |
| E2-2 | Model Dart cho Card / Course / Lesson (parse JSON) | ☐ TODO |
| E2-3 | Repository: load content từ assets/local, áp manifest | ☐ TODO |
| E2-4 | State management (Riverpod/Bloc — chọn) | ☐ TODO |
| E2-5 | Nhúng font CJK (Noto Sans SC) | ☐ TODO |

## E3 — Engine game (gameplay hướng A)

| Mã | Task | Trạng thái |
|----|------|-----------|
| E3-1 | Spike: thử Flame vs widget cho nhân vật nhảy/scroll | ☐ TODO |
| E3-2 | Màn chơi: nhân vật chạy → dừng hỏi → nhảy ăn nấm | ☐ TODO |
| E3-3 | UI câu hỏi 4 đáp án + hiệu ứng đúng/sai | ☐ TODO |
| E3-4 | Hệ thống mạng (3 mặc định, cộng dồn) + nấm + combo | ☐ TODO |
| E3-5 | Boss câu 20 + power-up (gợi ý/đóng băng/hồi mạng) | ☐ TODO |
| E3-6 | Sinh màn tự động theo 20 câu (template) | ☐ TODO |
| E3-7 | Điều chỉnh tốc độ chơi (chậm/vừa/nhanh) | ☐ TODO |

## E4 — Học tập (chọn câu, SRS, ôn tập)

| Mã | Task | Trạng thái |
|----|------|-----------|
| E4-1 | Sinh 4 đáp án từ `distractor_group` | ☐ TODO |
| E4-2 | Các dạng câu hỏi đảo chiều (nhận diện/sản xuất/nghe/thanh điệu/Hán Việt) | ☐ TODO |
| E4-3 | Lưu tiến độ học từng từ (level, nextReviewDate) | ☐ TODO |
| E4-4 | Thuật toán SRS (lên/xuống bậc, đo thời gian tương đối) | ☐ TODO |
| E4-5 | Màn ôn tập (trộn vào vòng / phần riêng) | ☐ TODO |
| E4-6 | Preview từ vựng trước vòng + gợi ý tốc độ | ☐ TODO |

## E5 — Audio & TTS

| Mã | Task | Trạng thái |
|----|------|-----------|
| E5-1 | Spike: kiểm tra `flutter_tts` đọc tiếng Trung trên máy thật | ☐ TODO |
| E5-2 | Pre-cache TTS lần đầu (`synthesizeToFile`) + màn loading | ☐ TODO |
| E5-3 | Phát audio trong câu hỏi nghe + nút loa trên card | ☐ TODO |

## E6 — Đồng bộ & lưu trữ

| Mã | Task | Trạng thái |
|----|------|-----------|
| E6-1 | Lưu tiến độ local (SQLite/Hive — chọn) | ☐ TODO |
| E6-2 | Google Sign-In + Drive AppData | ☐ TODO |
| E6-3 | Tạo/liệt kê/restore/xóa snapshot, giới hạn ~10 bản | ☐ TODO |
| E6-4 | Cảnh báo khi restore đè tiến độ | ☐ TODO |

## E7 — Tải/cập nhật nội dung

| Mã | Task | Trạng thái |
|----|------|-----------|
| E7-1 | Tải content lần đầu (cần mạng) + màn loading | ☐ TODO |
| E7-2 | Cập nhật theo manifest + version per-card (giữ tiến độ) | ☐ TODO |

## E8 — Tài nguyên (assets)

| Mã | Task | Trạng thái |
|----|------|-----------|
| E8-1 | Tổng hợp nguồn ảnh/âm thanh/font CC0 ([assets.md](assets.md)) | ☑ DONE |
| E8-2 | Chọn & tải bộ sprite nhân vật + nấm + tileset platformer | ☐ TODO |
| E8-3 | Kiểm tra license từng asset (CC0/ghi công) trước khi dùng | ☐ TODO |

## E9 — UI/UX & ngoài game

| Mã | Task | Trạng thái |
|----|------|-----------|
| E9-1 | Màn chọn khóa HSK → bài → vòng | ☐ TODO |
| E9-2 | Màn cài đặt (tốc độ, chiều Việt↔Trung, âm thanh) | ☐ TODO |
| E9-3 | Màn thống kê tiến độ / từ đã thuộc | ☐ TODO |
| E9-4 | Daily streak + local notification nhắc học | ☐ TODO |
